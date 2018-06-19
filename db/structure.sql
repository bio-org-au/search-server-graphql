--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.12
-- Dumped by pg_dump version 9.5.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: audit; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA audit;


--
-- Name: SCHEMA audit; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA audit IS 'Out-of-table audit/history logging tables and trigger functions';


--
-- Name: mapper; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mapper;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: audit_table(regclass); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$_$;


--
-- Name: FUNCTION audit_table(target_table regclass); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass) IS '
Add auditing support to the given table. Row-level changes will be logged with full client query text. No cols are ignored.
';


--
-- Name: audit_table(regclass, boolean, boolean); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) RETURNS void
    LANGUAGE sql
    AS $_$
SELECT audit.audit_table($1, $2, $3, ARRAY[]::text[]);
$_$;


--
-- Name: audit_table(regclass, boolean, boolean, text[]); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
  _q_txt text;
  _ignored_cols_snip text = '';
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table;

    IF audit_rows THEN
        IF array_length(ignored_cols,1) > 0 THEN
            _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
        END IF;
        _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 target_table ||
                 ' FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func(' ||
                 quote_literal(audit_query_text) || _ignored_cols_snip || ');';
        RAISE NOTICE '%',_q_txt;
        EXECUTE _q_txt;
        stm_targets = 'TRUNCATE';
    ELSE
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%',_q_txt;
    EXECUTE _q_txt;

END;
$$;


--
-- Name: FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) IS '
Add auditing support to a table.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
   audit_rows:       Record each row change, or only audit at a statement level
   audit_query_text: Record the text of the client query that triggered the audit event?
   ignored_cols:     Columns to exclude from update diffs, ignore updates that change only ignored cols.
';


--
-- Name: if_modified_func(); Type: FUNCTION; Schema: audit; Owner: -
--

CREATE FUNCTION audit.if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO pg_catalog, public
    AS $$
DECLARE
    audit_row audit.logged_actions;
    include_values boolean;
    log_diffs boolean;
    h_old hstore;
    h_new hstore;
    excluded_cols text[] = ARRAY[]::text[];
BEGIN
    IF TG_WHEN <> 'AFTER' THEN
        RAISE EXCEPTION 'audit.if_modified_func() may only run as an AFTER trigger';
    END IF;

    audit_row = ROW(
        nextval('audit.logged_actions_event_id_seq'), -- event_id
        TG_TABLE_SCHEMA::text,                        -- schema_name
        TG_TABLE_NAME::text,                          -- table_name
        TG_RELID,                                     -- relation OID for much quicker searches
        session_user::text,                           -- session_user_name
        current_timestamp,                            -- action_tstamp_tx
        statement_timestamp(),                        -- action_tstamp_stm
        clock_timestamp(),                            -- action_tstamp_clk
        txid_current(),                               -- transaction ID
        current_setting('application_name'),          -- client application
        inet_client_addr(),                           -- client_addr
        inet_client_port(),                           -- client_port
        current_query(),                              -- top-level query or queries (if multistatement) from client
        substring(TG_OP,1,1),                         -- action
        NULL, NULL,                                   -- row_data, changed_fields
        'f'                                           -- statement_only
        );

    IF NOT TG_ARGV[0]::boolean IS DISTINCT FROM 'f'::boolean THEN
        audit_row.client_query = NULL;
    END IF;

    IF TG_ARGV[1] IS NOT NULL THEN
        excluded_cols = TG_ARGV[1]::text[];
    END IF;

    IF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(OLD.*);
        audit_row.changed_fields =  (hstore(NEW.*) - audit_row.row_data) - excluded_cols;
        IF audit_row.changed_fields = hstore('') THEN
            -- All changed fields are ignored. Skip this update.
            RETURN NULL;
        END IF;
    ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(OLD.*) - excluded_cols;
    ELSIF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(NEW.*) - excluded_cols;
    ELSIF (TG_LEVEL = 'STATEMENT' AND TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
        audit_row.statement_only = 't';
    ELSE
        RAISE EXCEPTION '[audit.if_modified_func] - Trigger func added as trigger for unhandled case: %, %',TG_OP, TG_LEVEL;
        RETURN NULL;
    END IF;
    INSERT INTO audit.logged_actions VALUES (audit_row.*);
    RETURN NULL;
END;
$$;


--
-- Name: FUNCTION if_modified_func(); Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON FUNCTION audit.if_modified_func() IS '
Track changes to a table at the statement and/or row level.

Optional parameters to trigger in CREATE TRIGGER call:

param 0: boolean, whether to log the query text. Default ''t''.

param 1: text[], columns to ignore in updates. Default [].

         Updates to ignored cols are omitted from changed_fields.

         Updates with only ignored cols changed are not inserted
         into the audit log.

         Almost all the processing work is still done for updates
         that ignored. If you need to save the load, you need to use
         WHEN clause on the trigger instead.

         No warning or error is issued if ignored_cols contains columns
         that do not exist in the target table. This lets you specify
         a standard set of ignored columns.

There is no parameter to disable logging of values. Add this trigger as
a ''FOR EACH STATEMENT'' rather than ''FOR EACH ROW'' trigger if you do not
want to log row values.

Note that the user name logged is the login role for the session. The audit trigger
cannot obtain the active role because it is reset by the SECURITY DEFINER invocation
of the audit trigger its self.
';


--
-- Name: author_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.author_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'author deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'author updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'author created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: daily_top_nodes(text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.daily_top_nodes(tree_label text, since timestamp without time zone) RETURNS TABLE(latest_node_id bigint, year double precision, month double precision, day double precision)
    LANGUAGE sql
    AS $$

WITH RECURSIVE treewalk AS (
  SELECT class_root.*
  FROM tree_node class_node
    JOIN tree_arrangement a ON class_node.id = a.node_id AND a.label = tree_label
    JOIN tree_link sublink ON class_node.id = sublink.supernode_id
    JOIN tree_node class_root ON sublink.subnode_id = class_root.id
  UNION ALL
  SELECT node.*
  FROM treewalk
    JOIN tree_node node ON treewalk.prev_node_id = node.id
)
SELECT
  max(tw.id) AS latest_node_id,
  year,
  month,
  day
FROM treewalk tw
  JOIN tree_event event ON tw.checked_in_at_id = event.id
  ,
      extract(YEAR FROM event.time_stamp) AS year,
      extract(MONTH FROM event.time_stamp) AS month,
      extract(DAY FROM event.time_stamp) AS day
WHERE event.time_stamp > since
GROUP BY year, month, day
ORDER BY latest_node_id ASC
$$;


--
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO public, pg_temp
    AS $_$
SELECT unaccent('unaccent', $1)
$_$;


--
-- Name: find_family_name_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_family_name_id(target_element_link text) RETURNS bigint
    LANGUAGE sql
    AS $$
WITH RECURSIVE walk (name_id, rank, parent_id) AS (
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  FROM tree_version_element tve
    JOIN tree_element te ON tve.tree_element_id = te.id
  WHERE element_link = target_element_link
  UNION ALL
  SELECT
    te.name_id,
    te.rank,
    tve.parent_id
  FROM walk, tree_version_element tve
    JOIN tree_element te ON tve.tree_element_id = te.id
  WHERE element_link = walk.parent_id
)
SELECT name_id
FROM walk
WHERE rank = 'Familia';
$$;


--
-- Name: find_name_in_tree(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.find_name_in_tree(pname bigint, ptree bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- declarations
  ct integer;
  base_id tree_arrangement.id%TYPE;
  link_id tree_link.id%TYPE;
BEGIN
  -- if this is a simple tree, then we can just look for the tree link directly.
  -- if it is a tree based on another tree, then we must do a treewalk

  select base_arrangement_id into base_id from tree_arrangement a where a.id = ptree;

  begin
    IF base_id is null then
      -- ok. look for the name as a current node in the tree, and find the link to its current parent.

      select l.id INTO STRICT link_id
      from tree_node c
        join tree_link l on c.id = l.subnode_id
        join tree_node p on l.supernode_id = p.id
      where c.name_id = pname
            and c.tree_arrangement_id = ptree
            and c.next_node_id is null
            and p.tree_arrangement_id = ptree
            and p.next_node_id is null;
    ELSE
      -- ok. we need to do a treewalk. As always, this gets nasty.

      with RECURSIVE walk as (
        select l.id as stem_link, l.id as leaf_link, p.tree_arrangement_id = ptree as foundit
        from tree_node c
          join tree_link l on c.id = l.subnode_id
          join tree_node p on l.supernode_id = p.id
        where
          c.name_id = pname
          and (c.tree_arrangement_id = ptree or c.tree_arrangement_id = base_id)
          and c.next_node_id is null
          and (p.tree_arrangement_id = ptree or p.tree_arrangement_id = base_id)
          and p.next_node_id is null
        UNION ALL
        SELECT
          superlink.id as stem_link, walk.leaf_link, p.tree_arrangement_id = ptree as foundit
        FROM walk
          JOIN tree_link sublink on walk.stem_link = sublink.id
          join tree_link superlink on sublink.supernode_id = superlink.subnode_id
          join tree_node p on superlink.supernode_id = p.id
        where not walk.foundit -- clip the search
              and (p.tree_arrangement_id = ptree or p.tree_arrangement_id = base_id)
              and p.next_node_id is null
      )
      select leaf_link INTO STRICT link_id from walk where foundit;

    END IF;

    return link_id;

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise notice 'no data found';
      return null;
    WHEN TOO_MANY_ROWS THEN
      raise notice 'too many rows';
      RAISE 'Multiple placements of name % in tree %', pname, ptree USING ERRCODE = 'unique_violation';
  end;
END;
$$;


--
-- Name: instance_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.instance_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'instance deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'instance updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'instance created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: is_instance_in_tree(bigint, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_instance_in_tree(pinstance bigint, ptree bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  -- declarations
  ct integer;
  base_id tree_arrangement.id%TYPE;
BEGIN
  -- OK. Is this instance directly in the tree as a current node?

  select count(*) into ct
  from tree_node n
  where n.instance_id = pinstance
        and n.tree_arrangement_id = ptree
        and n.next_node_id is null;

  if ct <> 0 then
    return true;
  end if;

  -- is the tree derived from some other tree?

  select base_arrangement_id into base_id from tree_arrangement a where a.id = ptree;

  if base_id is null then
    return false;
  end if;

  -- right. This tree is derived from another tree. That means that the instance might be in that
  -- other tree and adopted to this one. here's where we need to do a treewalk.
  -- this code assumes that the tree will have at least one node belonging to it at the root, which currently
  -- is the case.

  with recursive treewalk as (
    select n.id as node_id, n.tree_arrangement_id
    from tree_node n
    where n.instance_id = pinstance
          and n.tree_arrangement_id = base_id
          and n.next_node_id is null
    union all
    select n.id as node_id, n.tree_arrangement_id
    from treewalk
      join tree_link l on treewalk.node_id = l.subnode_id
      join tree_node n on l.supernode_id = n.id
    where treewalk.tree_arrangement_id <> ptree -- clip search here
          and n.next_node_id is null
          and n.tree_arrangement_id in (ptree, base_id)
  )
  select count(node_id) into ct from treewalk where treewalk.tree_arrangement_id = ptree;

  return ct <> 0;
END;
$$;


--
-- Name: name_name_path(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_name_path(target_name_id bigint) RETURNS TABLE(name_path text, family_id bigint)
    LANGUAGE sql
    AS $$
with pathElements (id, path_element, rank_name) as (
  WITH RECURSIVE walk (id, parent_id, path_element, pos, rank_name) AS (
    SELECT
      n.id,
      n.parent_id,
      n.name_element,
      1,
      rank.name
    FROM name n
      join name_rank rank on n.name_rank_id = rank.id
    WHERE n.id = target_name_id
    UNION ALL
    SELECT
      n.id,
      n.parent_id,
      n.name_element,
      walk.pos + 1,
      rank.name
    FROM walk, name n
      join name_rank rank on n.name_rank_id = rank.id
    WHERE n.id = walk.parent_id
  )
  SELECT
    id,
    path_element,
    rank_name
  FROM walk
  order by walk.pos desc)
select
  string_agg(path_element, '/'),
  (select id
   from pathElements p2
   where p2.rank_name = 'Familia'
   limit 1)
from pathElements;
$$;


--
-- Name: name_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.name_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'name deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'name updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'name created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: pbool(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pbool(bool boolean) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
begin
return case bool
       when true
        then 'true'
      else
        ''
      end;
end; $$;


--
-- Name: profile_as_jsonb(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.profile_as_jsonb(source_instance_id bigint) RETURNS jsonb
    LANGUAGE sql
    AS $$
SELECT jsonb_object_agg(key.name, jsonb_build_object(
    'value', note.value,
    'created_at', note.created_at,
    'created_by', note.created_by,
    'updated_at', note.updated_at,
    'updated_by', note.updated_by,
    'source_link', 'https://test-id.biodiversity.org.au' || '/instanceNote/apni/' || note.id
))
FROM instance i
  JOIN instance_note note ON i.id = note.instance_id
  JOIN instance_note_key key ON note.instance_note_key_id = key.id
WHERE i.id = source_instance_id;
$$;


--
-- Name: reference_notification(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reference_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (TG_OP = 'DELETE')
  THEN
    INSERT INTO notification (id, version, message, object_id)
      SELECT
        nextval('hibernate_sequence'),
        0,
        'reference deleted',
        OLD.id;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'reference updated',
          NEW.id;
      RETURN NEW;
  ELSIF (TG_OP = 'INSERT')
    THEN
      INSERT INTO notification (id, version, message, object_id)
        SELECT
          nextval('hibernate_sequence'),
          0,
          'reference created',
          NEW.id;
      RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$;


--
-- Name: synonym_as_html(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonym_as_html(instance_id bigint) RETURNS TABLE(html text)
    LANGUAGE sql
    AS $$
SELECT CASE
       WHEN it.nomenclatural
         THEN '<nom>' || synonym.full_name_html || ' <type>' || it.name || '</type></nom>'
       WHEN it.taxonomic
         THEN '<tax>' || synonym.full_name_html || ' <type>' || it.name || '</type></tax>'
       WHEN it.misapplied
         THEN '<mis>' || synonym.full_name_html || ' <type>' || it.name || '</type> by <citation>' ||
              cites_ref.citation_html
              ||
              '</citation></mis>'
       WHEN it.synonym
         THEN '<syn>' || synonym.full_name_html || ' <type>' || it.name || '</type></syn>'
       ELSE ''
       END
FROM Instance i,
  Instance syn_inst
  JOIN instance_type it ON syn_inst.instance_type_id = it.id
  JOIN instance cites_inst ON syn_inst.cites_id = cites_inst.id
  JOIN reference cites_ref ON cites_inst.reference_id = cites_ref.id
  ,
  NAME synonym
WHERE syn_inst.cited_by_id = i.id
      AND i.id = instance_id
      AND synonym.id = syn_inst.name_id
ORDER BY it.nomenclatural DESC, it.taxonomic DESC, it.misapplied DESC, synonym.simple_name, cites_ref.year ASC;
$$;


--
-- Name: synonyms_as_html(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonyms_as_html(instance_id bigint) RETURNS text
    LANGUAGE sql
    AS $$
SELECT '<synonyms>' || string_agg(html, '') || '</synonyms>'
FROM synonym_as_html(instance_id) AS html;
$$;


--
-- Name: synonyms_as_jsonb(bigint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.synonyms_as_jsonb(instance_id bigint, host text) RETURNS jsonb
    LANGUAGE sql
    AS $$
SELECT jsonb_build_object('list',
                          coalesce(
                              jsonb_agg(jsonb_build_object(
                                            'host', host,
                                            'instance_id', syn_inst.id,
                                            'instance_link',
                                            '/instance/apni/' || syn_inst.id,
                                            'concept_link',
                                            '/instance/apni/' || cites_inst.id,
                                            'simple_name', synonym.simple_name,
                                            'type', it.name,
                                            'name_id', synonym.id :: BIGINT,
                                            'name_link',
                                            '/name/apni/' || synonym.id,
                                            'full_name_html', synonym.full_name_html,
                                            'nom', it.nomenclatural,
                                            'tax', it.taxonomic,
                                            'mis', it.misapplied,
                                            'cites', cites_ref.citation_html,
                                            'cites_link',
                                            '/reference/apni/' || cites_ref.id,
                                            'year', cites_ref.year
                                        )), '[]' :: JSONB)
)
FROM Instance i,
  Instance syn_inst
  JOIN instance_type it ON syn_inst.instance_type_id = it.id
  JOIN instance cites_inst ON syn_inst.cites_id = cites_inst.id
  JOIN reference cites_ref ON cites_inst.reference_id = cites_ref.id
  ,
  name synonym
WHERE i.id = instance_id
      AND syn_inst.cited_by_id = i.id
      AND synonym.id = syn_inst.name_id;
$$;


--
-- Name: tree_element_data_from_start_node(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tree_element_data_from_start_node(root_node bigint) RETURNS TABLE(tree_id bigint, node_id bigint, excluded boolean, declared_bt boolean, instance_id bigint, name_id bigint, simple_name text, name_path text, instance_path text, parent_instance_path text, parent_excluded boolean, depth integer)
    LANGUAGE sql
    AS $$
WITH RECURSIVE treewalk (tree_id, node_id, excluded, declared_bt, instance_id, name_id, simple_name, name_path, instance_path,
    parent_instance_path, parent_excluded, depth) AS (
  SELECT
    tree.id                   AS tree_id,
    node.id                   AS node_id,
    (node.type_uri_id_part <>
     'ApcConcept') :: BOOLEAN AS excluded,
    (node.type_uri_id_part =
     'DeclaredBt') :: BOOLEAN AS declared_bt,
    node.instance_id          AS instance_id,
    node.name_id              AS name_id,
    n.simple_name :: TEXT     AS simple_name,
    coalesce(n.name_element,
             '?')             AS name_path,
    CASE
    WHEN (node.type_uri_id_part = 'ApcConcept')
      THEN
        node.instance_id :: TEXT
    WHEN (node.type_uri_id_part = 'DeclaredBt')
      THEN
        'b' || node.instance_id :: TEXT
    ELSE
      'x' || node.instance_id :: TEXT
    END                       AS instance_path,
    ''                        AS parent_instance_path,
    FALSE                     AS parent_excluded,
    1                         AS depth
  FROM tree_link link
    JOIN tree_node node ON link.subnode_id = node.id
    JOIN tree_arrangement tree ON node.tree_arrangement_id = tree.id
    JOIN name n ON node.name_id = n.id
    JOIN name_rank rank ON n.name_rank_id = rank.id
    JOIN instance inst ON node.instance_id = inst.id
    JOIN reference ref ON inst.reference_id = ref.id
  WHERE link.supernode_id = root_node
        AND node.internal_type = 'T'
  UNION ALL
  SELECT
    treewalk.tree_id                           AS tree_id,
    node.id                                    AS node_id,
    (node.type_uri_id_part <>
     'ApcConcept') :: BOOLEAN                  AS excluded,
    (node.type_uri_id_part =
     'DeclaredBt') :: BOOLEAN                  AS declared_bt,
    node.instance_id                           AS instance_id,
    node.name_id                               AS name_id,
    n.simple_name :: TEXT                      AS simple_name,
    treewalk.name_path || '/' || COALESCE(n.name_element,
                                          '?') AS name_path,
    CASE
    WHEN (node.type_uri_id_part = 'ApcConcept')
      THEN
        treewalk.instance_path || '/' || node.instance_id :: TEXT
    WHEN (node.type_uri_id_part = 'DeclaredBt')
      THEN
        treewalk.instance_path || '/b' || node.instance_id :: TEXT
    ELSE
      treewalk.instance_path || '/x' || node.instance_id :: TEXT
    END                                        AS instance_path,
    treewalk.instance_path                     AS parent_instance_path,
    treewalk.excluded                          AS parent_excluded,
    treewalk.depth + 1                         AS depth
  FROM treewalk
    JOIN tree_link link ON link.supernode_id = treewalk.node_id
    JOIN tree_node node ON link.subnode_id = node.id
    JOIN name n ON node.name_id = n.id
    JOIN name_rank rank ON n.name_rank_id = rank.id
    JOIN instance inst ON node.instance_id = inst.id
    JOIN reference REF ON inst.reference_id = REF.id
  WHERE node.internal_type = 'T'
        AND node.tree_arrangement_id = treewalk.tree_id
)
SELECT
  tree_id,
  node_id,
  excluded,
  declared_bt,
  instance_id,
  name_id,
  simple_name,
  name_path,
  instance_path,
  parent_instance_path,
  parent_excluded,
  depth
FROM treewalk
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logged_actions; Type: TABLE; Schema: audit; Owner: -
--

CREATE TABLE audit.logged_actions (
    event_id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    relid oid NOT NULL,
    session_user_name text,
    action_tstamp_tx timestamp with time zone NOT NULL,
    action_tstamp_stm timestamp with time zone NOT NULL,
    action_tstamp_clk timestamp with time zone NOT NULL,
    transaction_id bigint,
    application_name text,
    client_addr inet,
    client_port integer,
    client_query text,
    action text NOT NULL,
    row_data public.hstore,
    changed_fields public.hstore,
    statement_only boolean NOT NULL,
    CONSTRAINT logged_actions_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text, 'T'::text])))
);


--
-- Name: TABLE logged_actions; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON TABLE audit.logged_actions IS 'History of auditable actions on audited tables, from audit.if_modified_func()';


--
-- Name: COLUMN logged_actions.event_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.event_id IS 'Unique identifier for each auditable event';


--
-- Name: COLUMN logged_actions.schema_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.schema_name IS 'Database schema audited table for this event is in';


--
-- Name: COLUMN logged_actions.table_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.table_name IS 'Non-schema-qualified table name of table event occured in';


--
-- Name: COLUMN logged_actions.relid; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::regclass';


--
-- Name: COLUMN logged_actions.session_user_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.session_user_name IS 'Login / session user whose statement caused the audited event';


--
-- Name: COLUMN logged_actions.action_tstamp_tx; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_stm; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_clk; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';


--
-- Name: COLUMN logged_actions.transaction_id; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.transaction_id IS 'Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.';


--
-- Name: COLUMN logged_actions.application_name; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.application_name IS 'Application name set when this audit event occurred. Can be changed in-session by client.';


--
-- Name: COLUMN logged_actions.client_addr; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';


--
-- Name: COLUMN logged_actions.client_port; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_port IS 'Remote peer IP port address of client that issued query. Undefined for unix socket.';


--
-- Name: COLUMN logged_actions.client_query; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.client_query IS 'Top-level query that caused this auditable event. May be more than one statement.';


--
-- Name: COLUMN logged_actions.action; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';


--
-- Name: COLUMN logged_actions.row_data; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';


--
-- Name: COLUMN logged_actions.changed_fields; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.changed_fields IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';


--
-- Name: COLUMN logged_actions.statement_only; Type: COMMENT; Schema: audit; Owner: -
--

COMMENT ON COLUMN audit.logged_actions.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE; Schema: audit; Owner: -
--

CREATE SEQUENCE audit.logged_actions_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE OWNED BY; Schema: audit; Owner: -
--

ALTER SEQUENCE audit.logged_actions_event_id_seq OWNED BY audit.logged_actions.event_id;


--
-- Name: db_version; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: mapper_sequence; Type: SEQUENCE; Schema: mapper; Owner: -
--

CREATE SEQUENCE mapper.mapper_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.host (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    host_name character varying(512) NOT NULL,
    preferred boolean DEFAULT false NOT NULL
);


--
-- Name: identifier; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.identifier (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    id_number bigint NOT NULL,
    name_space character varying(255) NOT NULL,
    object_type character varying(255) NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    reason_deleted character varying(255),
    updated_at timestamp with time zone,
    updated_by character varying(255),
    preferred_uri_id bigint,
    version_number bigint
);


--
-- Name: identifier_identities; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.identifier_identities (
    match_id bigint NOT NULL,
    identifier_id bigint NOT NULL
);


--
-- Name: match; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.match (
    id bigint DEFAULT nextval('mapper.mapper_sequence'::regclass) NOT NULL,
    uri character varying(255) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone,
    updated_by character varying(255)
);


--
-- Name: match_host; Type: TABLE; Schema: mapper; Owner: -
--

CREATE TABLE mapper.match_host (
    match_hosts_id bigint,
    host_id bigint
);


--
-- Name: nsl_global_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nsl_global_seq
    START WITH 50000001
    INCREMENT BY 1
    MINVALUE 50000001
    MAXVALUE 60000000
    CACHE 1;


--
-- Name: author; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.author (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev character varying(100),
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    date_range character varying(50),
    duplicate_of_id bigint,
    full_name character varying(255),
    ipni_id character varying(50),
    name character varying(1000),
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL
);


--
-- Name: bulk_name_raw; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bulk_name_raw (
    genus character varying,
    species character varying,
    subsp_var character varying,
    authority character varying,
    preferred_authority character varying,
    page character varying,
    act_page character varying,
    nsw_page character varying,
    nt_page character varying,
    qld_page character varying,
    sa_page character varying,
    tas_page character varying,
    vic_page character varying,
    wa_page character varying,
    ait_page character varying,
    nominated_id integer
);


--
-- Name: hibernate_sequence; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hibernate_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comment (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint,
    name_id bigint,
    reference_id bigint,
    text text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: db_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.db_version (
    id bigint NOT NULL,
    version integer NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    attempts numeric(19,2),
    created_at timestamp with time zone NOT NULL,
    failed_at timestamp with time zone,
    handler text,
    last_error text,
    locked_at timestamp with time zone,
    locked_by character varying(4000),
    priority numeric(19,2),
    queue character varying(4000),
    run_at timestamp with time zone,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: distribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.distribution (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    description character varying(100) NOT NULL,
    is_doubtfully_naturalised boolean DEFAULT false NOT NULL,
    is_extinct boolean DEFAULT false NOT NULL,
    is_native boolean DEFAULT false NOT NULL,
    is_naturalised boolean DEFAULT false NOT NULL,
    region character varying(10) NOT NULL
);


--
-- Name: event_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_record (
    id bigint NOT NULL,
    version bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    data jsonb,
    dealt_with boolean DEFAULT false NOT NULL,
    type text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: help_topic; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.help_topic (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    created_by character varying(4000) NOT NULL,
    marked_up_text text NOT NULL,
    name character varying(4000) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    updated_by character varying(4000) NOT NULL
);


--
-- Name: id_mapper; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.id_mapper (
    id bigint NOT NULL,
    from_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    system character varying(20) NOT NULL,
    to_id bigint
);


--
-- Name: instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    bhl_url character varying(4000),
    cited_by_id bigint,
    cites_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    draft boolean DEFAULT false NOT NULL,
    instance_type_id bigint NOT NULL,
    name_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    nomenclatural_status character varying(50),
    page character varying(255),
    page_qualifier character varying(255),
    parent_id bigint,
    reference_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(1000) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_name_string character varying(255),
    CONSTRAINT citescheck CHECK (((cites_id IS NULL) OR (cited_by_id IS NOT NULL)))
);


--
-- Name: instance_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_note (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    instance_id bigint NOT NULL,
    instance_note_key_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    value character varying(4000) NOT NULL
);


--
-- Name: instance_note_key; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_note_key (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: instance_paths; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_paths (
    id bigint,
    instance_path text,
    parent_instance_path text,
    name_path text,
    instance_id bigint,
    name_id bigint,
    excluded boolean,
    declared_bt boolean,
    depth integer,
    versions_str text,
    nodes jsonb,
    versions jsonb,
    ver_node_map jsonb
);


--
-- Name: instance_resources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_resources (
    instance_id bigint NOT NULL,
    resource_id bigint NOT NULL
);


--
-- Name: resource; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.resource (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    path character varying(2400) NOT NULL,
    site_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL
);


--
-- Name: site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    description character varying(1000) NOT NULL,
    name character varying(100) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    url character varying(500) NOT NULL
);


--
-- Name: instance_resource_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.instance_resource_vw AS
 SELECT site.name AS site_name,
    site.description AS site_description,
    site.url AS site_url,
    resource.path AS resource_path,
    ((site.url)::text || (resource.path)::text) AS url,
    instance_resources.instance_id
   FROM (((public.site
     JOIN public.resource ON ((site.id = resource.site_id)))
     JOIN public.instance_resources ON ((resource.id = instance_resources.resource_id)))
     JOIN public.instance ON ((instance_resources.instance_id = instance.id)));


--
-- Name: instance_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instance_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    citing boolean DEFAULT false NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    doubtful boolean DEFAULT false NOT NULL,
    misapplied boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    nomenclatural boolean DEFAULT false NOT NULL,
    primary_instance boolean DEFAULT false NOT NULL,
    pro_parte boolean DEFAULT false NOT NULL,
    protologue boolean DEFAULT false NOT NULL,
    relationship boolean DEFAULT false NOT NULL,
    secondary_instance boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    standalone boolean DEFAULT false NOT NULL,
    synonym boolean DEFAULT false NOT NULL,
    taxonomic boolean DEFAULT false NOT NULL,
    unsourced boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    has_label character varying(255) DEFAULT 'not set'::character varying NOT NULL,
    of_label character varying(255) DEFAULT 'not set'::character varying NOT NULL,
    bidirectional boolean DEFAULT false NOT NULL
);


--
-- Name: language; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    iso6391code character varying(2),
    iso6393code character varying(3) NOT NULL,
    name character varying(50) NOT NULL
);


--
-- Name: locale; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locale (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    locale_name_string character varying(50) NOT NULL
);


--
-- Name: name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    author_id bigint,
    base_author_id bigint,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(50) NOT NULL,
    duplicate_of_id bigint,
    ex_author_id bigint,
    ex_base_author_id bigint,
    full_name character varying(512),
    full_name_html character varying(2048),
    name_element character varying(255),
    name_rank_id bigint NOT NULL,
    name_status_id bigint NOT NULL,
    name_type_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    orth_var boolean DEFAULT false NOT NULL,
    parent_id bigint,
    sanctioning_author_id bigint,
    second_parent_id bigint,
    simple_name character varying(250),
    simple_name_html character varying(2048),
    source_dup_of_id bigint,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    status_summary character varying(50),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(50) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    why_is_this_here_id bigint,
    verbatim_rank character varying(50),
    sort_name character varying(250),
    family_id bigint,
    name_path text DEFAULT ''::text NOT NULL
);


--
-- Name: name_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_category (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: name_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_status (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    display boolean DEFAULT true NOT NULL,
    name character varying(50),
    name_group_id bigint NOT NULL,
    name_status_id bigint,
    nom_illeg boolean DEFAULT false NOT NULL,
    nom_inval boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    deprecated boolean DEFAULT false NOT NULL
);


--
-- Name: name_detail_commons_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_detail_commons_vw AS
 SELECT instance.cited_by_id,
    ((((ity.name)::text || ':'::text) || (name.full_name_html)::text) || (
        CASE
            WHEN (ns.nom_illeg OR ns.nom_inval) THEN ns.name
            ELSE ''::character varying
        END)::text) AS entry,
    instance.id,
    instance.cites_id,
    ity.name AS instance_type_name,
    ity.sort_order AS instance_type_sort_order,
    name.full_name,
    name.full_name_html,
    ns.name,
    instance.name_id,
    instance.id AS instance_id,
    instance.cited_by_id AS name_detail_id
   FROM (((public.instance
     JOIN public.name ON ((instance.name_id = name.id)))
     JOIN public.instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN public.name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text = ANY (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_detail_synonyms_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_detail_synonyms_vw AS
 SELECT instance.cited_by_id,
    ((((ity.name)::text || ':'::text) || (name.full_name_html)::text) || (
        CASE
            WHEN (ns.nom_illeg OR ns.nom_inval) THEN ns.name
            ELSE ''::character varying
        END)::text) AS entry,
    instance.id,
    instance.cites_id,
    ity.name AS instance_type_name,
    ity.sort_order AS instance_type_sort_order,
    name.full_name,
    name.full_name_html,
    ns.name,
    instance.name_id,
    instance.id AS instance_id,
    instance.cited_by_id AS name_detail_id,
    instance.reference_id
   FROM (((public.instance
     JOIN public.name ON ((instance.name_id = name.id)))
     JOIN public.instance_type ity ON ((ity.id = instance.instance_type_id)))
     JOIN public.name_status ns ON ((ns.id = name.name_status_id)))
  WHERE ((ity.name)::text <> ALL (ARRAY[('common name'::character varying)::text, ('vernacular name'::character varying)::text]));


--
-- Name: name_rank; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_rank (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev character varying(20) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    has_parent boolean DEFAULT false NOT NULL,
    italicize boolean DEFAULT false NOT NULL,
    major boolean DEFAULT false NOT NULL,
    name character varying(50) NOT NULL,
    name_group_id bigint NOT NULL,
    parent_rank_id bigint,
    sort_order integer DEFAULT 0 NOT NULL,
    visible_in_name boolean DEFAULT true NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_verbatim_rank boolean DEFAULT false NOT NULL
);


--
-- Name: name_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    autonym boolean DEFAULT false NOT NULL,
    connector character varying(1),
    cultivar boolean DEFAULT false NOT NULL,
    formula boolean DEFAULT false NOT NULL,
    hybrid boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    name_category_id bigint NOT NULL,
    name_group_id bigint NOT NULL,
    scientific boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    description_html text,
    rdf_id character varying(50),
    deprecated boolean DEFAULT false NOT NULL
);


--
-- Name: reference; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reference (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    abbrev_title character varying(2000),
    author_id bigint NOT NULL,
    bhl_url character varying(4000),
    citation character varying(4000),
    citation_html character varying(4000),
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    display_title character varying(2000) NOT NULL,
    doi character varying(255),
    duplicate_of_id bigint,
    edition character varying(100),
    isbn character varying(16),
    issn character varying(16),
    language_id bigint NOT NULL,
    namespace_id bigint NOT NULL,
    notes character varying(1000),
    pages character varying(1000),
    parent_id bigint,
    publication_date character varying(50),
    published boolean DEFAULT false NOT NULL,
    published_location character varying(1000),
    publisher character varying(1000),
    ref_author_role_id bigint NOT NULL,
    ref_type_id bigint NOT NULL,
    source_id bigint,
    source_id_string character varying(100),
    source_system character varying(50),
    title character varying(2000) NOT NULL,
    tl2 character varying(30),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(1000) NOT NULL,
    valid_record boolean DEFAULT false NOT NULL,
    verbatim_author character varying(1000),
    verbatim_citation character varying(2000),
    verbatim_reference character varying(1000),
    volume character varying(100),
    year integer
);


--
-- Name: name_details_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_details_vw AS
 SELECT n.id,
    n.full_name,
    n.simple_name,
    s.name AS status_name,
    r.name AS rank_name,
    r.visible_in_name AS rank_visible_in_name,
    r.sort_order AS rank_sort_order,
    t.name AS type_name,
    t.scientific AS type_scientific,
    t.cultivar AS type_cultivar,
    i.id AS instance_id,
    ref.year AS reference_year,
    ref.id AS reference_id,
    ref.citation_html AS reference_citation_html,
    ity.name AS instance_type_name,
    ity.id AS instance_type_id,
    ity.primary_instance,
    ity.standalone AS instance_standalone,
    sty.standalone AS synonym_standalone,
    sty.name AS synonym_type_name,
    i.page,
    i.page_qualifier,
    i.cited_by_id,
    i.cites_id,
    i.bhl_url,
        CASE ity.primary_instance
            WHEN true THEN 'A'::text
            ELSE 'B'::text
        END AS primary_instance_first,
    sname.full_name AS synonym_full_name,
    author.name AS author_name,
    n.id AS name_id,
    n.sort_name,
    ((((ref.citation_html)::text || ': '::text) || (COALESCE(i.page, ''::character varying))::text) ||
        CASE ity.primary_instance
            WHEN true THEN ((' ['::text || (ity.name)::text) || ']'::text)
            ELSE ''::text
        END) AS entry
   FROM ((((((((((public.name n
     JOIN public.name_status s ON ((n.name_status_id = s.id)))
     JOIN public.name_rank r ON ((n.name_rank_id = r.id)))
     JOIN public.name_type t ON ((n.name_type_id = t.id)))
     JOIN public.instance i ON ((n.id = i.name_id)))
     JOIN public.instance_type ity ON ((i.instance_type_id = ity.id)))
     JOIN public.reference ref ON ((i.reference_id = ref.id)))
     LEFT JOIN public.author ON ((ref.author_id = author.id)))
     LEFT JOIN public.instance syn ON ((syn.cited_by_id = i.id)))
     LEFT JOIN public.instance_type sty ON ((syn.instance_type_id = sty.id)))
     LEFT JOIN public.name sname ON ((syn.name_id = sname.id)))
  WHERE (n.duplicate_of_id IS NULL);


--
-- Name: name_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_group (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50),
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: name_or_synonym_vw; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.name_or_synonym_vw AS
 SELECT 0 AS id,
    ''::character varying AS simple_name,
    ''::character varying AS full_name,
    ''::character varying AS type_code,
    0 AS instance_id,
    0 AS tree_node_id,
    0 AS accepted_id,
    ''::character varying AS accepted_full_name,
    0 AS name_status_id,
    0 AS reference_id,
    0 AS name_rank_id,
    ''::character varying AS sort_name
   FROM public.name
  WHERE (1 = 0);


--
-- Name: name_tag; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_tag (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL
);


--
-- Name: name_tag_name; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.name_tag_name (
    name_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: namespace; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.namespace (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: nomenclatural_event_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nomenclatural_event_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name_group_id bigint NOT NULL,
    nomenclatural_event_type character varying(50),
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id bigint NOT NULL,
    version bigint NOT NULL,
    message character varying(255) NOT NULL,
    object_id bigint
);


--
-- Name: nsl_simple_name_export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nsl_simple_name_export (
    id text,
    apc_comment character varying(4000),
    apc_distribution character varying(4000),
    apc_excluded boolean,
    apc_familia character varying(255),
    apc_instance_id text,
    apc_name character varying(512),
    apc_proparte boolean,
    apc_relationship_type character varying(255),
    apni boolean,
    author character varying(255),
    authority character varying(255),
    autonym boolean,
    basionym character varying(512),
    base_name_author character varying(255),
    classifications character varying(255),
    created_at timestamp without time zone,
    created_by character varying(255),
    cultivar boolean,
    cultivar_name character varying(255),
    ex_author character varying(255),
    ex_base_name_author character varying(255),
    familia character varying(255),
    family_nsl_id text,
    formula boolean,
    full_name_html character varying(2048),
    genus character varying(255),
    genus_nsl_id text,
    homonym boolean,
    hybrid boolean,
    infraspecies character varying(255),
    name character varying(255),
    classis character varying(255),
    name_element character varying(255),
    subclassis character varying(255),
    name_type_name character varying(255),
    nom_illeg boolean,
    nom_inval boolean,
    nom_stat character varying(255),
    parent_nsl_id text,
    proto_citation character varying(512),
    proto_instance_id text,
    proto_year smallint,
    rank character varying(255),
    rank_abbrev character varying(255),
    rank_sort_order integer,
    replaced_synonym character varying(512),
    sanctioning_author character varying(255),
    scientific boolean,
    second_parent_nsl_id text,
    simple_name_html character varying(2048),
    species character varying(255),
    species_nsl_id text,
    taxon_name character varying(512),
    updated_at timestamp without time zone,
    updated_by character varying(255)
);


--
-- Name: ref_author_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_author_role (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    description_html text,
    rdf_id character varying(50)
);


--
-- Name: ref_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ref_type (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    parent_id bigint,
    parent_optional boolean DEFAULT false NOT NULL,
    description_html text,
    rdf_id character varying(50),
    use_parent_details boolean DEFAULT false NOT NULL
);


--
-- Name: shard_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shard_config (
    id bigint DEFAULT nextval('public.hibernate_sequence'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    value character varying(5000) NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    use_notes character varying(255)
);


--
-- Name: tree; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    accepted_tree boolean DEFAULT false NOT NULL,
    config jsonb,
    current_tree_version_id bigint,
    default_draft_tree_version_id bigint,
    description_html text DEFAULT 'Edit me'::text NOT NULL,
    group_name text NOT NULL,
    host_name text NOT NULL,
    link_to_home_page text,
    name text NOT NULL,
    reference_id bigint,
    CONSTRAINT draft_not_current CHECK ((current_tree_version_id <> default_draft_tree_version_id))
);


--
-- Name: tree_arrangement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_arrangement (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    tree_type bpchar NOT NULL,
    description character varying(255),
    label character varying(50),
    node_id bigint,
    is_synthetic bpchar NOT NULL,
    title character varying(50),
    namespace_id bigint,
    owner character varying(255),
    shared boolean DEFAULT true,
    base_arrangement_id bigint,
    CONSTRAINT chk_classification_has_label CHECK (((tree_type <> ALL (ARRAY['E'::bpchar, 'P'::bpchar])) OR (label IS NOT NULL))),
    CONSTRAINT chk_tree_arrangement_type CHECK ((tree_type = ANY (ARRAY['E'::bpchar, 'P'::bpchar, 'U'::bpchar, 'Z'::bpchar]))),
    CONSTRAINT chk_work_trees_have_base_trees CHECK (((tree_type <> 'U'::bpchar) OR (base_arrangement_id IS NOT NULL)))
);


--
-- Name: tree_element; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_element (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    display_html text NOT NULL,
    excluded boolean DEFAULT false NOT NULL,
    instance_id bigint NOT NULL,
    instance_link text NOT NULL,
    name_element character varying(255) NOT NULL,
    name_id bigint NOT NULL,
    name_link text NOT NULL,
    previous_element_id bigint,
    profile jsonb,
    rank character varying(50) NOT NULL,
    simple_name text NOT NULL,
    source_element_link text,
    source_shard text NOT NULL,
    synonyms jsonb,
    synonyms_html text NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: tree_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_event (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    auth_user character varying(255) NOT NULL,
    note character varying(255),
    time_stamp timestamp with time zone NOT NULL,
    namespace_id bigint
);


--
-- Name: tree_link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_link (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    link_seq integer NOT NULL,
    subnode_id bigint NOT NULL,
    supernode_id bigint NOT NULL,
    is_synthetic bpchar NOT NULL,
    type_uri_id_part character varying(255),
    type_uri_ns_part_id bigint NOT NULL,
    versioning_method bpchar NOT NULL,
    CONSTRAINT chk_tree_link_sub_not_end CHECK ((subnode_id <> 0)),
    CONSTRAINT chk_tree_link_sup_not_end CHECK ((supernode_id <> 0)),
    CONSTRAINT chk_tree_link_synthetic_yn CHECK ((is_synthetic = ANY (ARRAY['N'::bpchar, 'Y'::bpchar]))),
    CONSTRAINT chk_tree_link_vmethod CHECK ((versioning_method = ANY (ARRAY['F'::bpchar, 'V'::bpchar, 'T'::bpchar])))
);


--
-- Name: tree_node; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_node (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    checked_in_at_id bigint,
    internal_type character varying(255) NOT NULL,
    literal character varying(4096),
    name_uri_id_part character varying(255),
    name_uri_ns_part_id bigint,
    next_node_id bigint,
    prev_node_id bigint,
    replaced_at_id bigint,
    resource_uri_id_part character varying(255),
    resource_uri_ns_part_id bigint,
    tree_arrangement_id bigint,
    is_synthetic bpchar NOT NULL,
    taxon_uri_id_part character varying(255),
    taxon_uri_ns_part_id bigint,
    type_uri_id_part character varying(255),
    type_uri_ns_part_id bigint NOT NULL,
    name_id bigint,
    instance_id bigint,
    CONSTRAINT chk_arrangement_synthetic_yn CHECK ((is_synthetic = ANY (ARRAY['N'::bpchar, 'Y'::bpchar]))),
    CONSTRAINT chk_internal_type_d CHECK ((((internal_type)::text <> 'D'::text) OR ((name_uri_ns_part_id IS NULL) AND (taxon_uri_ns_part_id IS NULL) AND (literal IS NULL)))),
    CONSTRAINT chk_internal_type_enum CHECK (((internal_type)::text = ANY (ARRAY[('S'::character varying)::text, ('Z'::character varying)::text, ('T'::character varying)::text, ('D'::character varying)::text, ('V'::character varying)::text]))),
    CONSTRAINT chk_internal_type_s CHECK ((((internal_type)::text <> 'S'::text) OR ((name_uri_ns_part_id IS NULL) AND (taxon_uri_ns_part_id IS NULL) AND (resource_uri_ns_part_id IS NULL) AND (literal IS NULL)))),
    CONSTRAINT chk_internal_type_t CHECK ((((internal_type)::text <> 'T'::text) OR (literal IS NULL))),
    CONSTRAINT chk_internal_type_v CHECK ((((internal_type)::text <> 'V'::text) OR ((name_uri_ns_part_id IS NULL) AND (taxon_uri_ns_part_id IS NULL) AND (((resource_uri_ns_part_id IS NOT NULL) AND (literal IS NULL)) OR ((resource_uri_ns_part_id IS NULL) AND (literal IS NOT NULL)))))),
    CONSTRAINT chk_tree_node_instance_matches CHECK (((instance_id IS NULL) OR (((instance_id)::character varying)::text = (taxon_uri_id_part)::text))),
    CONSTRAINT chk_tree_node_name_matches CHECK (((name_id IS NULL) OR (((name_id)::character varying)::text = (name_uri_id_part)::text))),
    CONSTRAINT chk_tree_node_synthetic_yn CHECK ((is_synthetic = ANY (ARRAY['N'::bpchar, 'Y'::bpchar])))
);


--
-- Name: tree_uri_ns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_uri_ns (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    description character varying(255),
    id_mapper_namespace_id bigint,
    id_mapper_system character varying(255),
    label character varying(20) NOT NULL,
    owner_uri_id_part character varying(255),
    owner_uri_ns_part_id bigint,
    title character varying(255),
    uri character varying(255)
);


--
-- Name: tree_value_uri; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_value_uri (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    deprecated boolean DEFAULT false NOT NULL,
    description character varying(2048),
    is_multi_valued boolean DEFAULT false NOT NULL,
    is_resource boolean DEFAULT false NOT NULL,
    label character varying(20) NOT NULL,
    link_uri_id_part character varying(255) NOT NULL,
    link_uri_ns_part_id bigint NOT NULL,
    node_uri_id_part character varying(255) NOT NULL,
    node_uri_ns_part_id bigint NOT NULL,
    root_id bigint NOT NULL,
    sort_order integer NOT NULL,
    title character varying(50) NOT NULL
);


--
-- Name: tree_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    created_by character varying(255) NOT NULL,
    draft_name text NOT NULL,
    log_entry text,
    previous_version_id bigint,
    published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    published_by character varying(100),
    tree_id bigint NOT NULL
);


--
-- Name: tree_version_element; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tree_version_element (
    element_link text NOT NULL,
    depth integer NOT NULL,
    name_path text NOT NULL,
    parent_id text,
    taxon_id bigint NOT NULL,
    taxon_link text NOT NULL,
    tree_element_id bigint NOT NULL,
    tree_path text NOT NULL,
    tree_version_id bigint NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    updated_by character varying(255) NOT NULL
);


--
-- Name: user_query; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_query (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone NOT NULL,
    query_completed boolean DEFAULT false NOT NULL,
    query_started boolean DEFAULT false NOT NULL,
    record_count numeric(19,2) NOT NULL,
    search_finished_at timestamp with time zone,
    search_info character varying(500),
    search_model character varying(4000),
    search_result text,
    search_started_at timestamp with time zone,
    search_terms character varying(4000),
    trash boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: why_is_this_here; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.why_is_this_here (
    id bigint DEFAULT nextval('public.nsl_global_seq'::regclass) NOT NULL,
    lock_version bigint DEFAULT 0 NOT NULL,
    name character varying(50) NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL
);


--
-- Name: event_id; Type: DEFAULT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logged_actions ALTER COLUMN event_id SET DEFAULT nextval('audit.logged_actions_event_id_seq'::regclass);


--
-- Name: logged_actions_pkey; Type: CONSTRAINT; Schema: audit; Owner: -
--

ALTER TABLE ONLY audit.logged_actions
    ADD CONSTRAINT logged_actions_pkey PRIMARY KEY (event_id);


--
-- Name: db_version_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: host_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.host
    ADD CONSTRAINT host_pkey PRIMARY KEY (id);


--
-- Name: identifier_identities_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT identifier_identities_pkey PRIMARY KEY (identifier_id, match_id);


--
-- Name: identifier_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT identifier_pkey PRIMARY KEY (id);


--
-- Name: match_pkey; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match
    ADD CONSTRAINT match_pkey PRIMARY KEY (id);


--
-- Name: uk_2u4bey0rox6ubtvqevg3wasp9; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match
    ADD CONSTRAINT uk_2u4bey0rox6ubtvqevg3wasp9 UNIQUE (uri);


--
-- Name: unique_name_space; Type: CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT unique_name_space UNIQUE (version_number, id_number, object_type, name_space);


--
-- Name: author_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (id);


--
-- Name: comment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- Name: current_name_only_once; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT current_name_only_once EXCLUDE USING btree (tree_arrangement_id WITH =, name_id WITH =) WHERE (((name_id IS NOT NULL) AND (replaced_at_id IS NULL)));


--
-- Name: db_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_version
    ADD CONSTRAINT db_version_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: distribution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.distribution
    ADD CONSTRAINT distribution_pkey PRIMARY KEY (id);


--
-- Name: event_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_record
    ADD CONSTRAINT event_record_pkey PRIMARY KEY (id);


--
-- Name: help_topic_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.help_topic
    ADD CONSTRAINT help_topic_pkey PRIMARY KEY (id);


--
-- Name: id_mapper_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT id_mapper_pkey PRIMARY KEY (id);


--
-- Name: instance_note_key_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note_key
    ADD CONSTRAINT instance_note_key_pkey PRIMARY KEY (id);


--
-- Name: instance_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT instance_note_pkey PRIMARY KEY (id);


--
-- Name: instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT instance_pkey PRIMARY KEY (id);


--
-- Name: instance_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT instance_resources_pkey PRIMARY KEY (instance_id, resource_id);


--
-- Name: instance_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_type
    ADD CONSTRAINT instance_type_pkey PRIMARY KEY (id);


--
-- Name: language_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (id);


--
-- Name: locale_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locale
    ADD CONSTRAINT locale_pkey PRIMARY KEY (id);


--
-- Name: name_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_category
    ADD CONSTRAINT name_category_pkey PRIMARY KEY (id);


--
-- Name: name_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_group
    ADD CONSTRAINT name_group_pkey PRIMARY KEY (id);


--
-- Name: name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT name_pkey PRIMARY KEY (id);


--
-- Name: name_rank_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT name_rank_pkey PRIMARY KEY (id);


--
-- Name: name_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT name_status_pkey PRIMARY KEY (id);


--
-- Name: name_tag_name_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT name_tag_name_pkey PRIMARY KEY (name_id, tag_id);


--
-- Name: name_tag_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag
    ADD CONSTRAINT name_tag_pkey PRIMARY KEY (id);


--
-- Name: name_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT name_type_pkey PRIMARY KEY (id);


--
-- Name: namespace_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT namespace_pkey PRIMARY KEY (id);


--
-- Name: no_duplicate_synonyms; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT no_duplicate_synonyms UNIQUE (name_id, reference_id, instance_type_id, page, cites_id, cited_by_id);


--
-- Name: nomenclatural_event_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclatural_event_type
    ADD CONSTRAINT nomenclatural_event_type_pkey PRIMARY KEY (id);


--
-- Name: notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: ref_author_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_author_role
    ADD CONSTRAINT ref_author_role_pkey PRIMARY KEY (id);


--
-- Name: ref_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (id);


--
-- Name: reference_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (id);


--
-- Name: resource_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT resource_pkey PRIMARY KEY (id);


--
-- Name: shard_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shard_config
    ADD CONSTRAINT shard_config_pkey PRIMARY KEY (id);


--
-- Name: site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: tree_arrangement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_arrangement
    ADD CONSTRAINT tree_arrangement_pkey PRIMARY KEY (id);


--
-- Name: tree_element_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT tree_element_pkey PRIMARY KEY (id);


--
-- Name: tree_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_event
    ADD CONSTRAINT tree_event_pkey PRIMARY KEY (id);


--
-- Name: tree_link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_link
    ADD CONSTRAINT tree_link_pkey PRIMARY KEY (id);


--
-- Name: tree_node_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT tree_node_pkey PRIMARY KEY (id);


--
-- Name: tree_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT tree_pkey PRIMARY KEY (id);


--
-- Name: tree_uri_ns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_uri_ns
    ADD CONSTRAINT tree_uri_ns_pkey PRIMARY KEY (id);


--
-- Name: tree_value_uri_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_value_uri
    ADD CONSTRAINT tree_value_uri_pkey PRIMARY KEY (id);


--
-- Name: tree_version_element_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT tree_version_element_pkey PRIMARY KEY (element_link);


--
-- Name: tree_version_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT tree_version_pkey PRIMARY KEY (id);


--
-- Name: uk_314uhkq8i7r46050kd1nfrs95; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT uk_314uhkq8i7r46050kd1nfrs95 UNIQUE (name);


--
-- Name: uk_4fp66uflo7rgx59167ajs0ujv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT uk_4fp66uflo7rgx59167ajs0ujv UNIQUE (name);


--
-- Name: uk_5185nbyw5hkxqyyqgylfn2o6d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_group
    ADD CONSTRAINT uk_5185nbyw5hkxqyyqgylfn2o6d UNIQUE (name);


--
-- Name: uk_5smmen5o34hs50jxd247k81ia; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_uri_ns
    ADD CONSTRAINT uk_5smmen5o34hs50jxd247k81ia UNIQUE (label);


--
-- Name: uk_70p0ys3l5v6s9dqrpjr3u3rrf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_uri_ns
    ADD CONSTRAINT uk_70p0ys3l5v6s9dqrpjr3u3rrf UNIQUE (uri);


--
-- Name: uk_9kovg6nyb11658j2tv2yv4bsi; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT uk_9kovg6nyb11658j2tv2yv4bsi UNIQUE (abbrev);


--
-- Name: uk_a0justk7c77bb64o6u1riyrlh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note_key
    ADD CONSTRAINT uk_a0justk7c77bb64o6u1riyrlh UNIQUE (name);


--
-- Name: uk_eq2y9mghytirkcofquanv5frf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.namespace
    ADD CONSTRAINT uk_eq2y9mghytirkcofquanv5frf UNIQUE (name);


--
-- Name: uk_g8hr207ijpxlwu10pewyo65gv; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_g8hr207ijpxlwu10pewyo65gv UNIQUE (name);


--
-- Name: uk_hghw87nl0ho38f166atlpw2hy; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_hghw87nl0ho38f166atlpw2hy UNIQUE (iso6391code);


--
-- Name: uk_j5337m9qdlirvd49v4h11t1lk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_type
    ADD CONSTRAINT uk_j5337m9qdlirvd49v4h11t1lk UNIQUE (name);


--
-- Name: uk_kqwpm0crhcq4n9t9uiyfxo2df; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT uk_kqwpm0crhcq4n9t9uiyfxo2df UNIQUE (doi);


--
-- Name: uk_l95kedbafybjpp3h53x8o9fke; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_author_role
    ADD CONSTRAINT uk_l95kedbafybjpp3h53x8o9fke UNIQUE (name);


--
-- Name: uk_o4su6hi7vh0yqs4c1dw0fsf1e; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag
    ADD CONSTRAINT uk_o4su6hi7vh0yqs4c1dw0fsf1e UNIQUE (name);


--
-- Name: uk_qjkskvl9hx0w78truoyq9teju; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locale
    ADD CONSTRAINT uk_qjkskvl9hx0w78truoyq9teju UNIQUE (locale_name_string);


--
-- Name: uk_rpsahneqboogcki6p1bpygsua; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT uk_rpsahneqboogcki6p1bpygsua UNIQUE (iso6393code);


--
-- Name: uk_rxqxoenedjdjyd4x7c98s59io; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_category
    ADD CONSTRAINT uk_rxqxoenedjdjyd4x7c98s59io UNIQUE (name);


--
-- Name: uk_se7crmfnhjmyvirp3p9hiqerx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT uk_se7crmfnhjmyvirp3p9hiqerx UNIQUE (name);


--
-- Name: uk_sv1q1i7xve7xgmkwvmdbeo1mb; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.why_is_this_here
    ADD CONSTRAINT uk_sv1q1i7xve7xgmkwvmdbeo1mb UNIQUE (name);


--
-- Name: uk_y303qbh1ijdg3sncl9vlxus0; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_arrangement
    ADD CONSTRAINT uk_y303qbh1ijdg3sncl9vlxus0 UNIQUE (label);


--
-- Name: unique_from_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT unique_from_id UNIQUE (to_id, from_id);


--
-- Name: user_query_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_query
    ADD CONSTRAINT user_query_pkey PRIMARY KEY (id);


--
-- Name: why_is_this_here_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.why_is_this_here
    ADD CONSTRAINT why_is_this_here_pkey PRIMARY KEY (id);


--
-- Name: logged_actions_action_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_idx ON audit.logged_actions USING btree (action);


--
-- Name: logged_actions_action_tstamp_tx_stm_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_action_tstamp_tx_stm_idx ON audit.logged_actions USING btree (action_tstamp_stm);


--
-- Name: logged_actions_relid_idx; Type: INDEX; Schema: audit; Owner: -
--

CREATE INDEX logged_actions_relid_idx ON audit.logged_actions USING btree (relid);


--
-- Name: identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_index ON mapper.identifier USING btree (id_number, name_space, object_type);


--
-- Name: identifier_prefuri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_prefuri_index ON mapper.identifier USING btree (preferred_uri_id);


--
-- Name: identifier_version_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identifier_version_index ON mapper.identifier USING btree (id_number, name_space, object_type, version_number);


--
-- Name: identity_uri_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX identity_uri_index ON mapper.match USING btree (uri);


--
-- Name: mapper_identifier_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_identifier_index ON mapper.identifier_identities USING btree (identifier_id);


--
-- Name: mapper_match_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX mapper_match_index ON mapper.identifier_identities USING btree (match_id);


--
-- Name: match_host_index; Type: INDEX; Schema: mapper; Owner: -
--

CREATE INDEX match_host_index ON mapper.match_host USING btree (match_hosts_id);


--
-- Name: auth_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_index ON public.author USING btree (namespace_id, source_id, source_system);


--
-- Name: auth_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_source_string_index ON public.author USING btree (source_id_string);


--
-- Name: auth_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auth_system_index ON public.author USING btree (source_system);


--
-- Name: author_abbrev_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_abbrev_index ON public.author USING btree (abbrev);


--
-- Name: author_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX author_name_index ON public.author USING btree (name);


--
-- Name: by_root_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX by_root_id ON public.tree_value_uri USING btree (root_id);


--
-- Name: comment_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_author_index ON public.comment USING btree (author_id);


--
-- Name: comment_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_instance_index ON public.comment USING btree (instance_id);


--
-- Name: comment_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_name_index ON public.comment USING btree (name_id);


--
-- Name: comment_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX comment_reference_index ON public.comment USING btree (reference_id);


--
-- Name: event_record_created_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_created_index ON public.event_record USING btree (created_at);


--
-- Name: event_record_dealt_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_dealt_index ON public.event_record USING btree (dealt_with);


--
-- Name: event_record_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_index ON public.event_record USING btree (created_at, dealt_with, type);


--
-- Name: event_record_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_record_type_index ON public.event_record USING btree (type);


--
-- Name: id_mapper_from_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX id_mapper_from_index ON public.id_mapper USING btree (from_id, namespace_id, system);


--
-- Name: idx_node_current_a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_a ON public.tree_node USING btree (tree_arrangement_id) WHERE (replaced_at_id IS NULL);


--
-- Name: idx_node_current_b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_b ON public.tree_node USING btree (tree_arrangement_id) WHERE (next_node_id IS NULL);


--
-- Name: idx_node_current_instance_a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_instance_a ON public.tree_node USING btree (instance_id, tree_arrangement_id) WHERE (replaced_at_id IS NULL);


--
-- Name: idx_node_current_instance_b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_instance_b ON public.tree_node USING btree (instance_id, tree_arrangement_id) WHERE (next_node_id IS NULL);


--
-- Name: idx_node_current_name_a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_name_a ON public.tree_node USING btree (name_id, tree_arrangement_id) WHERE (replaced_at_id IS NULL);


--
-- Name: idx_node_current_name_b; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_node_current_name_b ON public.tree_node USING btree (name_id, tree_arrangement_id) WHERE (next_node_id IS NULL);


--
-- Name: idx_tree_link_seq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_tree_link_seq ON public.tree_link USING btree (supernode_id, link_seq);


--
-- Name: idx_tree_node_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_instance_id ON public.tree_node USING btree (instance_id);


--
-- Name: idx_tree_node_instance_id_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_instance_id_in ON public.tree_node USING btree (instance_id, tree_arrangement_id);


--
-- Name: idx_tree_node_literal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_literal ON public.tree_node USING btree (literal);


--
-- Name: idx_tree_node_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name ON public.tree_node USING btree (name_uri_id_part, name_uri_ns_part_id);


--
-- Name: idx_tree_node_name_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name_id ON public.tree_node USING btree (name_id);


--
-- Name: idx_tree_node_name_id_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name_id_in ON public.tree_node USING btree (name_id, tree_arrangement_id);


--
-- Name: idx_tree_node_name_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_name_in ON public.tree_node USING btree (name_uri_id_part, name_uri_ns_part_id, tree_arrangement_id);


--
-- Name: idx_tree_node_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_resource ON public.tree_node USING btree (resource_uri_id_part, resource_uri_ns_part_id);


--
-- Name: idx_tree_node_resource_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_resource_in ON public.tree_node USING btree (resource_uri_id_part, resource_uri_ns_part_id, tree_arrangement_id);


--
-- Name: idx_tree_node_taxon; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_taxon ON public.tree_node USING btree (taxon_uri_id_part, taxon_uri_ns_part_id);


--
-- Name: idx_tree_node_taxon_in; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_node_taxon_in ON public.tree_node USING btree (taxon_uri_id_part, taxon_uri_ns_part_id, tree_arrangement_id);


--
-- Name: idx_tree_uri_ns_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_uri_ns_label ON public.tree_uri_ns USING btree (label);


--
-- Name: idx_tree_uri_ns_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tree_uri_ns_uri ON public.tree_uri_ns USING btree (uri);


--
-- Name: instance_citedby_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_citedby_index ON public.instance USING btree (cited_by_id);


--
-- Name: instance_cites_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_cites_index ON public.instance USING btree (cites_id);


--
-- Name: instance_instancetype_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_instancetype_index ON public.instance USING btree (instance_type_id);


--
-- Name: instance_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_name_index ON public.instance USING btree (name_id);


--
-- Name: instance_note_key_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_note_key_rdfid ON public.instance_note_key USING btree (rdf_id);


--
-- Name: instance_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_parent_index ON public.instance USING btree (parent_id);


--
-- Name: instance_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_path_index ON public.instance_paths USING btree (instance_path);


--
-- Name: instance_reference_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_reference_index ON public.instance USING btree (reference_id);


--
-- Name: instance_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_index ON public.instance USING btree (namespace_id, source_id, source_system);


--
-- Name: instance_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_source_string_index ON public.instance USING btree (source_id_string);


--
-- Name: instance_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_system_index ON public.instance USING btree (source_system);


--
-- Name: instance_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX instance_type_rdfid ON public.instance_type USING btree (rdf_id);


--
-- Name: link_uri_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX link_uri_index ON public.tree_value_uri USING btree (link_uri_id_part, link_uri_ns_part_id, root_id);


--
-- Name: lower_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lower_full_name ON public.name USING btree (lower((full_name)::text));


--
-- Name: name_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_author_index ON public.name USING btree (author_id);


--
-- Name: name_baseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_baseauthor_index ON public.name USING btree (base_author_id);


--
-- Name: name_category_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_category_rdfid ON public.name_category USING btree (rdf_id);


--
-- Name: name_duplicate_of_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_duplicate_of_id_index ON public.name USING btree (duplicate_of_id);


--
-- Name: name_exauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exauthor_index ON public.name USING btree (ex_author_id);


--
-- Name: name_exbaseauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_exbaseauthor_index ON public.name USING btree (ex_base_author_id);


--
-- Name: name_full_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_full_name_index ON public.name USING btree (full_name);


--
-- Name: name_group_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_group_rdfid ON public.name_group USING btree (rdf_id);


--
-- Name: name_lower_f_unaccent_full_name_like; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_f_unaccent_full_name_like ON public.name USING btree (lower(public.f_unaccent((full_name)::text)) varchar_pattern_ops);


--
-- Name: name_lower_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_full_name_gin_trgm ON public.name USING gin (lower((full_name)::text) public.gin_trgm_ops);


--
-- Name: name_lower_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_simple_name_gin_trgm ON public.name USING gin (lower((simple_name)::text) public.gin_trgm_ops);


--
-- Name: name_lower_unacent_full_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_full_name_gin_trgm ON public.name USING gin (lower(public.f_unaccent((full_name)::text)) public.gin_trgm_ops);


--
-- Name: name_lower_unacent_simple_name_gin_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_lower_unacent_simple_name_gin_trgm ON public.name USING gin (lower(public.f_unaccent((simple_name)::text)) public.gin_trgm_ops);


--
-- Name: name_name_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_name_element_index ON public.name USING btree (name_element);


--
-- Name: name_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_parent_id_ndx ON public.name USING btree (parent_id);


--
-- Name: name_rank_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_index ON public.name USING btree (name_rank_id);


--
-- Name: name_rank_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_rank_rdfid ON public.name_rank USING btree (rdf_id);


--
-- Name: name_sanctioningauthor_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_sanctioningauthor_index ON public.name USING btree (sanctioning_author_id);


--
-- Name: name_second_parent_id_ndx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_second_parent_id_ndx ON public.name USING btree (second_parent_id);


--
-- Name: name_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_simple_name_index ON public.name USING btree (simple_name);


--
-- Name: name_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_index ON public.name USING btree (namespace_id, source_id, source_system);


--
-- Name: name_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_source_string_index ON public.name USING btree (source_id_string);


--
-- Name: name_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_index ON public.name USING btree (name_status_id);


--
-- Name: name_status_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_status_rdfid ON public.name_status USING btree (rdf_id);


--
-- Name: name_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_system_index ON public.name USING btree (source_system);


--
-- Name: name_tag_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_name_index ON public.name_tag_name USING btree (name_id);


--
-- Name: name_tag_tag_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_tag_tag_index ON public.name_tag_name USING btree (tag_id);


--
-- Name: name_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_index ON public.name USING btree (name_type_id);


--
-- Name: name_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_type_rdfid ON public.name_type USING btree (rdf_id);


--
-- Name: name_whyisthishere_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX name_whyisthishere_index ON public.name USING btree (why_is_this_here_id);


--
-- Name: namespace_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX namespace_rdfid ON public.namespace USING btree (rdf_id);


--
-- Name: node_uri_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX node_uri_index ON public.tree_value_uri USING btree (node_uri_id_part, node_uri_ns_part_id, root_id);


--
-- Name: nomenclatural_event_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX nomenclatural_event_type_rdfid ON public.nomenclatural_event_type USING btree (rdf_id);


--
-- Name: note_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_instance_index ON public.instance_note USING btree (instance_id);


--
-- Name: note_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_key_index ON public.instance_note USING btree (instance_note_key_id);


--
-- Name: note_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_index ON public.instance_note USING btree (namespace_id, source_id, source_system);


--
-- Name: note_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_source_string_index ON public.instance_note USING btree (source_id_string);


--
-- Name: note_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX note_system_index ON public.instance_note USING btree (source_system);


--
-- Name: parent_instance_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX parent_instance_path_index ON public.instance_paths USING btree (parent_instance_path);


--
-- Name: ref_author_role_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_author_role_rdfid ON public.ref_author_role USING btree (rdf_id);


--
-- Name: ref_citation_text_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_citation_text_index ON public.reference USING gin (to_tsvector('english'::regconfig, public.f_unaccent(COALESCE((citation)::text, ''::text))));


--
-- Name: ref_source_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_index ON public.reference USING btree (namespace_id, source_id, source_system);


--
-- Name: ref_source_string_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_source_string_index ON public.reference USING btree (source_id_string);


--
-- Name: ref_system_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_system_index ON public.reference USING btree (source_system);


--
-- Name: ref_type_rdfid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ref_type_rdfid ON public.ref_type USING btree (rdf_id);


--
-- Name: reference_author_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_author_index ON public.reference USING btree (author_id);


--
-- Name: reference_authorrole_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_authorrole_index ON public.reference USING btree (ref_author_role_id);


--
-- Name: reference_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_parent_index ON public.reference USING btree (parent_id);


--
-- Name: reference_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reference_type_index ON public.reference USING btree (ref_type_id);


--
-- Name: tree_arrangement_label; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_arrangement_label ON public.tree_arrangement USING btree (label);


--
-- Name: tree_arrangement_node; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_arrangement_node ON public.tree_arrangement USING btree (node_id);


--
-- Name: tree_element_instance_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_instance_index ON public.tree_element USING btree (instance_id);


--
-- Name: tree_element_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_name_index ON public.tree_element USING btree (name_id);


--
-- Name: tree_element_previous_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_element_previous_index ON public.tree_element USING btree (previous_element_id);


--
-- Name: tree_link_subnode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_link_subnode ON public.tree_link USING btree (subnode_id);


--
-- Name: tree_link_supernode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_link_supernode ON public.tree_link USING btree (supernode_id);


--
-- Name: tree_name_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_name_path_index ON public.tree_version_element USING btree (name_path);


--
-- Name: tree_node_next; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_node_next ON public.tree_node USING btree (next_node_id);


--
-- Name: tree_node_prev; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_node_prev ON public.tree_node USING btree (prev_node_id);


--
-- Name: tree_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_path_index ON public.tree_version_element USING btree (tree_path);


--
-- Name: tree_simple_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_simple_name_index ON public.tree_element USING btree (simple_name);


--
-- Name: tree_synonyms_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_synonyms_index ON public.tree_element USING gin (synonyms);


--
-- Name: tree_version_element_element_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_element_index ON public.tree_version_element USING btree (tree_element_id);


--
-- Name: tree_version_element_link_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_link_index ON public.tree_version_element USING btree (element_link);


--
-- Name: tree_version_element_parent_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_parent_index ON public.tree_version_element USING btree (parent_id);


--
-- Name: tree_version_element_taxon_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_taxon_id_index ON public.tree_version_element USING btree (taxon_id);


--
-- Name: tree_version_element_taxon_link_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_taxon_link_index ON public.tree_version_element USING btree (taxon_link);


--
-- Name: tree_version_element_version_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tree_version_element_version_index ON public.tree_version_element USING btree (tree_version_id);


--
-- Name: unique_instance_path_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_instance_path_index ON public.instance_paths USING btree (instance_path, excluded);


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.instance FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.reference FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.instance_note FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_row; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON public.comment FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.author FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.instance FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.name FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.reference FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.instance_note FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: audit_trigger_stm; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON public.comment FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');


--
-- Name: author_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER author_update AFTER INSERT OR DELETE OR UPDATE ON public.author FOR EACH ROW EXECUTE PROCEDURE public.author_notification();


--
-- Name: instance_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER instance_update AFTER INSERT OR DELETE OR UPDATE ON public.instance FOR EACH ROW EXECUTE PROCEDURE public.instance_notification();


--
-- Name: name_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER name_update AFTER INSERT OR DELETE OR UPDATE ON public.name FOR EACH ROW EXECUTE PROCEDURE public.name_notification();


--
-- Name: reference_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reference_update AFTER INSERT OR DELETE OR UPDATE ON public.reference FOR EACH ROW EXECUTE PROCEDURE public.reference_notification();


--
-- Name: fk_3unhnjvw9xhs9l3ney6tvnioq; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match_host
    ADD CONSTRAINT fk_3unhnjvw9xhs9l3ney6tvnioq FOREIGN KEY (host_id) REFERENCES mapper.host(id);


--
-- Name: fk_iw1fva74t5r4ehvmoy87n37yr; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.match_host
    ADD CONSTRAINT fk_iw1fva74t5r4ehvmoy87n37yr FOREIGN KEY (match_hosts_id) REFERENCES mapper.match(id);


--
-- Name: fk_k2o53uoslf9gwqrd80cu2al4s; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier
    ADD CONSTRAINT fk_k2o53uoslf9gwqrd80cu2al4s FOREIGN KEY (preferred_uri_id) REFERENCES mapper.match(id);


--
-- Name: fk_mf2dsc2dxvsa9mlximsct7uau; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT fk_mf2dsc2dxvsa9mlximsct7uau FOREIGN KEY (match_id) REFERENCES mapper.match(id);


--
-- Name: fk_ojfilkcwskdvvbggwsnachry2; Type: FK CONSTRAINT; Schema: mapper; Owner: -
--

ALTER TABLE ONLY mapper.identifier_identities
    ADD CONSTRAINT fk_ojfilkcwskdvvbggwsnachry2 FOREIGN KEY (identifier_id) REFERENCES mapper.identifier(id);


--
-- Name: fk_10d0jlulq2woht49j5ccpeehu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT fk_10d0jlulq2woht49j5ccpeehu FOREIGN KEY (name_category_id) REFERENCES public.name_category(id);


--
-- Name: fk_156ncmx4599jcsmhh5k267cjv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_156ncmx4599jcsmhh5k267cjv FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: fk_16c4wgya68bwotwn6f50dhw69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_16c4wgya68bwotwn6f50dhw69 FOREIGN KEY (taxon_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_1g9477sa8plad5cxkxmiuh5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_1g9477sa8plad5cxkxmiuh5b FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: fk_1qx84m8tuk7vw2diyxfbj5r2n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_1qx84m8tuk7vw2diyxfbj5r2n FOREIGN KEY (language_id) REFERENCES public.language(id);


--
-- Name: fk_22wdc2pxaskytkgpdgpyok07n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT fk_22wdc2pxaskytkgpdgpyok07n FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: fk_2dk33tolvn16lfmp25nk2584y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_link
    ADD CONSTRAINT fk_2dk33tolvn16lfmp25nk2584y FOREIGN KEY (type_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_2uiijd73snf6lh5s6a82yjfin; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_tag_name
    ADD CONSTRAINT fk_2uiijd73snf6lh5s6a82yjfin FOREIGN KEY (tag_id) REFERENCES public.name_tag(id);


--
-- Name: fk_30enb6qoexhuk479t75apeuu5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_30enb6qoexhuk479t75apeuu5 FOREIGN KEY (cites_id) REFERENCES public.instance(id);


--
-- Name: fk_3min66ljijxavb0fjergx5dpm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_3min66ljijxavb0fjergx5dpm FOREIGN KEY (duplicate_of_id) REFERENCES public.reference(id);


--
-- Name: fk_3pqdqa03w5c6h4yyrrvfuagos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_3pqdqa03w5c6h4yyrrvfuagos FOREIGN KEY (duplicate_of_id) REFERENCES public.name(id);


--
-- Name: fk_3tfkdcmf6rg6hcyiu8t05er7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_3tfkdcmf6rg6hcyiu8t05er7x FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: fk_48skgw51tamg6ud4qa8oh0ycm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT fk_48skgw51tamg6ud4qa8oh0ycm FOREIGN KEY (default_draft_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: fk_49ic33s4xgbdoa4p5j107rtpf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT fk_49ic33s4xgbdoa4p5j107rtpf FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: fk_4q3huja5dv8t9xyvt5rg83a35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT fk_4q3huja5dv8t9xyvt5rg83a35 FOREIGN KEY (tree_id) REFERENCES public.tree(id);


--
-- Name: fk_4y1qy9beekbv71e9i6hto6hun; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_4y1qy9beekbv71e9i6hto6hun FOREIGN KEY (resource_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_51alfoe7eobwh60yfx45y22ay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ref_type
    ADD CONSTRAINT fk_51alfoe7eobwh60yfx45y22ay FOREIGN KEY (parent_id) REFERENCES public.ref_type(id);


--
-- Name: fk_5fpm5u0ukiml9nvmq14bd7u51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_5fpm5u0ukiml9nvmq14bd7u51 FOREIGN KEY (name_status_id) REFERENCES public.name_status(id);


--
-- Name: fk_5gp2lfblqq94c4ud3340iml0l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_5gp2lfblqq94c4ud3340iml0l FOREIGN KEY (second_parent_id) REFERENCES public.name(id);


--
-- Name: fk_5r3o78sgdbxsf525hmm3t44gv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_type
    ADD CONSTRAINT fk_5r3o78sgdbxsf525hmm3t44gv FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: fk_5sv181ivf7oybb6hud16ptmo5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_element
    ADD CONSTRAINT fk_5sv181ivf7oybb6hud16ptmo5 FOREIGN KEY (previous_element_id) REFERENCES public.tree_element(id);


--
-- Name: fk_6a4p11f1bt171w09oo06m0wag; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT fk_6a4p11f1bt171w09oo06m0wag FOREIGN KEY (duplicate_of_id) REFERENCES public.author(id);


--
-- Name: fk_6oqj6vquqc33cyawn853hfu5g; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_6oqj6vquqc33cyawn853hfu5g FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: fk_80khvm60q13xwqgpy43twlnoe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_80khvm60q13xwqgpy43twlnoe FOREIGN KEY (tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: fk_8mal9hru5u3ypaosfoju8ulpd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_resources
    ADD CONSTRAINT fk_8mal9hru5u3ypaosfoju8ulpd FOREIGN KEY (resource_id) REFERENCES public.resource(id);


--
-- Name: fk_8nnhwv8ldi9ppol6tg4uwn4qv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_8nnhwv8ldi9ppol6tg4uwn4qv FOREIGN KEY (parent_id) REFERENCES public.tree_version_element(element_link);


--
-- Name: fk_9aq5p2jgf17y6b38x5ayd90oc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_9aq5p2jgf17y6b38x5ayd90oc FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: fk_a98ei1lxn89madjihel3cvi90; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_a98ei1lxn89madjihel3cvi90 FOREIGN KEY (ref_author_role_id) REFERENCES public.ref_author_role(id);


--
-- Name: fk_ai81l07vh2yhmthr3582igo47; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_ai81l07vh2yhmthr3582igo47 FOREIGN KEY (sanctioning_author_id) REFERENCES public.author(id);


--
-- Name: fk_airfjupm6ohehj1lj82yqkwdx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_airfjupm6ohehj1lj82yqkwdx FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: fk_am2j11kvuwl19gqewuu18gjjm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_am2j11kvuwl19gqewuu18gjjm FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: fk_bcef76k0ijrcquyoc0yxehxfp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_bcef76k0ijrcquyoc0yxehxfp FOREIGN KEY (name_type_id) REFERENCES public.name_type(id);


--
-- Name: fk_budb70h51jhcxe7qbtpea0hi2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_budb70h51jhcxe7qbtpea0hi2 FOREIGN KEY (prev_node_id) REFERENCES public.tree_node(id);


--
-- Name: fk_bw41122jb5rcu8wfnog812s97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_bw41122jb5rcu8wfnog812s97 FOREIGN KEY (instance_id) REFERENCES public.instance(id);


--
-- Name: fk_coqxx3ewgiecsh3t78yc70b35; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_coqxx3ewgiecsh3t78yc70b35 FOREIGN KEY (base_author_id) REFERENCES public.author(id);


--
-- Name: fk_cr9avt4miqikx4kk53aflnnkd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_cr9avt4miqikx4kk53aflnnkd FOREIGN KEY (parent_id) REFERENCES public.reference(id);


--
-- Name: fk_dd33etb69v5w5iah1eeisy7yt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_dd33etb69v5w5iah1eeisy7yt FOREIGN KEY (parent_id) REFERENCES public.name(id);


--
-- Name: fk_djkn41tin6shkjuut9nam9xvn; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_value_uri
    ADD CONSTRAINT fk_djkn41tin6shkjuut9nam9xvn FOREIGN KEY (node_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_dm9y4p9xpsc8m7vljbohubl7x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_dm9y4p9xpsc8m7vljbohubl7x FOREIGN KEY (ref_type_id) REFERENCES public.ref_type(id);


--
-- Name: fk_dqhn53mdh0n77xhsw7l5dgd38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_dqhn53mdh0n77xhsw7l5dgd38 FOREIGN KEY (why_is_this_here_id) REFERENCES public.why_is_this_here(id);


--
-- Name: fk_ds3bc89iy6q3ts4ts85mqiys; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_value_uri
    ADD CONSTRAINT fk_ds3bc89iy6q3ts4ts85mqiys FOREIGN KEY (link_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_eqw4xo7vty6e4tq8hy34c51om; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_eqw4xo7vty6e4tq8hy34c51om FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: fk_f6s94njexmutjxjv8t5dy1ugt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_f6s94njexmutjxjv8t5dy1ugt FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: fk_fvfq13j3dqv994o9vg54yj5kk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_arrangement
    ADD CONSTRAINT fk_fvfq13j3dqv994o9vg54yj5kk FOREIGN KEY (node_id) REFERENCES public.tree_node(id);


--
-- Name: fk_g4o6xditli5a0xrm6eqc6h9gw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT fk_g4o6xditli5a0xrm6eqc6h9gw FOREIGN KEY (name_status_id) REFERENCES public.name_status(id);


--
-- Name: fk_gc6f9ykh7eaflvty9tr6n4cb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_gc6f9ykh7eaflvty9tr6n4cb6 FOREIGN KEY (name_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_gdunt8xo68ct1vfec9c6x5889; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_gdunt8xo68ct1vfec9c6x5889 FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: fk_gtkjmbvk6uk34fbfpy910e7t6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_gtkjmbvk6uk34fbfpy910e7t6 FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: fk_h9t5eaaqhnqwrc92rhryyvdcf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT fk_h9t5eaaqhnqwrc92rhryyvdcf FOREIGN KEY (name_id) REFERENCES public.name(id);


--
-- Name: fk_hb0xb97midopfgrm2k5fpe3p1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_hb0xb97midopfgrm2k5fpe3p1 FOREIGN KEY (parent_id) REFERENCES public.instance(id);


--
-- Name: fk_he1t3ug0o7ollnk2jbqaouooa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance_note
    ADD CONSTRAINT fk_he1t3ug0o7ollnk2jbqaouooa FOREIGN KEY (instance_note_key_id) REFERENCES public.instance_note_key(id);


--
-- Name: fk_kqshktm171nwvk38ot4d12w6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_link
    ADD CONSTRAINT fk_kqshktm171nwvk38ot4d12w6b FOREIGN KEY (supernode_id) REFERENCES public.tree_node(id);


--
-- Name: fk_l76e0lo0edcngyyqwkmkgywj9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.resource
    ADD CONSTRAINT fk_l76e0lo0edcngyyqwkmkgywj9 FOREIGN KEY (site_id) REFERENCES public.site(id);


--
-- Name: fk_lumlr5avj305pmc4hkjwaqk45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_lumlr5avj305pmc4hkjwaqk45 FOREIGN KEY (reference_id) REFERENCES public.reference(id);


--
-- Name: fk_nlq0qddnhgx65iojhj2xm8tay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_nlq0qddnhgx65iojhj2xm8tay FOREIGN KEY (checked_in_at_id) REFERENCES public.tree_event(id);


--
-- Name: fk_nw785lqesvg8ntfaper0tw2vs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_value_uri
    ADD CONSTRAINT fk_nw785lqesvg8ntfaper0tw2vs FOREIGN KEY (root_id) REFERENCES public.tree_arrangement(id);


--
-- Name: fk_o80rrtl8xwy4l3kqrt9qv0mnt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_o80rrtl8xwy4l3kqrt9qv0mnt FOREIGN KEY (instance_type_id) REFERENCES public.instance_type(id);


--
-- Name: fk_oge4ibjd3ff3oyshexl6set2u; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_oge4ibjd3ff3oyshexl6set2u FOREIGN KEY (type_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_p0ysrub11cm08xnhrbrfrvudh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT fk_p0ysrub11cm08xnhrbrfrvudh FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: fk_p3lpayfbl9s3hshhoycfj82b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT fk_p3lpayfbl9s3hshhoycfj82b9 FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: fk_p8lhsoo01164dsvvwxob0w3sp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reference
    ADD CONSTRAINT fk_p8lhsoo01164dsvvwxob0w3sp FOREIGN KEY (author_id) REFERENCES public.author(id);


--
-- Name: fk_pc0tkp9bgp1cxull530y60v46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_pc0tkp9bgp1cxull530y60v46 FOREIGN KEY (replaced_at_id) REFERENCES public.tree_event(id);


--
-- Name: fk_pr2f6peqhnx9rjiwkr5jgc5be; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instance
    ADD CONSTRAINT fk_pr2f6peqhnx9rjiwkr5jgc5be FOREIGN KEY (cited_by_id) REFERENCES public.instance(id);


--
-- Name: fk_q9k8he941kvl07j2htmqxq35v; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_uri_ns
    ADD CONSTRAINT fk_q9k8he941kvl07j2htmqxq35v FOREIGN KEY (owner_uri_ns_part_id) REFERENCES public.tree_uri_ns(id);


--
-- Name: fk_qiy281xsleyhjgr0eu1sboagm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.id_mapper
    ADD CONSTRAINT fk_qiy281xsleyhjgr0eu1sboagm FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: fk_ql5g85814a9y57c1ifd0nkq3v; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nomenclatural_event_type
    ADD CONSTRAINT fk_ql5g85814a9y57c1ifd0nkq3v FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: fk_r67um91pujyfrx7h1cifs3cmb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_rank
    ADD CONSTRAINT fk_r67um91pujyfrx7h1cifs3cmb FOREIGN KEY (parent_rank_id) REFERENCES public.name_rank(id);


--
-- Name: fk_rp659tjcxokf26j8551k6an2y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_rp659tjcxokf26j8551k6an2y FOREIGN KEY (ex_base_author_id) REFERENCES public.author(id);


--
-- Name: fk_sbuntfo4jfai44yjh9o09vu6s; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_sbuntfo4jfai44yjh9o09vu6s FOREIGN KEY (next_node_id) REFERENCES public.tree_node(id);


--
-- Name: fk_sgvxmyj7r9g4wy9c4hd1yn4nu; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_sgvxmyj7r9g4wy9c4hd1yn4nu FOREIGN KEY (ex_author_id) REFERENCES public.author(id);


--
-- Name: fk_sk2iikq8wla58jeypkw6h74hc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_sk2iikq8wla58jeypkw6h74hc FOREIGN KEY (name_rank_id) REFERENCES public.name_rank(id);


--
-- Name: fk_svg2ee45qvpomoer2otdc5oyc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree
    ADD CONSTRAINT fk_svg2ee45qvpomoer2otdc5oyc FOREIGN KEY (current_tree_version_id) REFERENCES public.tree_version(id);


--
-- Name: fk_swotu3c2gy1hp8f6ekvuo7s26; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name_status
    ADD CONSTRAINT fk_swotu3c2gy1hp8f6ekvuo7s26 FOREIGN KEY (name_group_id) REFERENCES public.name_group(id);


--
-- Name: fk_t6kkvm8ubsiw6fqg473j0gjga; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_node
    ADD CONSTRAINT fk_t6kkvm8ubsiw6fqg473j0gjga FOREIGN KEY (tree_arrangement_id) REFERENCES public.tree_arrangement(id);


--
-- Name: fk_tgankaahxgr4p0mw4opafah05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_link
    ADD CONSTRAINT fk_tgankaahxgr4p0mw4opafah05 FOREIGN KEY (subnode_id) REFERENCES public.tree_node(id);


--
-- Name: fk_tiniptsqbb5fgygt1idm1isfy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version
    ADD CONSTRAINT fk_tiniptsqbb5fgygt1idm1isfy FOREIGN KEY (previous_version_id) REFERENCES public.tree_version(id);


--
-- Name: fk_ufme7yt6bqyf3uxvuvouowhh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_version_element
    ADD CONSTRAINT fk_ufme7yt6bqyf3uxvuvouowhh FOREIGN KEY (tree_element_id) REFERENCES public.tree_element(id);


--
-- Name: fk_whce6pgnqjtxgt67xy2lfo34; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.name
    ADD CONSTRAINT fk_whce6pgnqjtxgt67xy2lfo34 FOREIGN KEY (family_id) REFERENCES public.name(id);


--
-- Name: tree_arrangement_base_arrangement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_arrangement
    ADD CONSTRAINT tree_arrangement_base_arrangement_id_fkey FOREIGN KEY (base_arrangement_id) REFERENCES public.tree_arrangement(id);


--
-- Name: tree_arrangement_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_arrangement
    ADD CONSTRAINT tree_arrangement_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- Name: tree_event_namespace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tree_event
    ADD CONSTRAINT tree_event_namespace_id_fkey FOREIGN KEY (namespace_id) REFERENCES public.namespace(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

