

echo test1: name search list Angophora costata with trailing wildcard, publication year 1962, limit: 10
rm test1.log
curl -S -d 'query={name_search(search_term:"Angophora*",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o test1.log
diff test1.expected test1.log

echo test2: name search list Angophora with publication year 1962, limit: 10
rm test2.log
curl -S -d 'query={name_search(search_term:"Angophora",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o test2.log
diff test2.expected test2.log

echo test3: name search list Angophora with trailing wildcard, publication year 1962, limit: 10
rm test3.log
curl -S -d 'query={name_search(search_term:"Angophora*",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o test3.log
diff test3.expected test3.log

echo test4: name search list genus: angophora, name element: corda*, type of name: scientific, limit: 10
rm test4.log
curl -S -d 'query={name_search(genus: "angophora", name_element: "corda*", type_of_name: "scientific", limit: 10){count, names {id, simple_name, full_name, full_name_html, name_status_name, family_name, name_history {name_usages {instance_id, reference_id, citation, page, page_qualifier, year, standalone, instance_type_name, accepted_tree_status, primary_instance, misapplied, misapplied_to_name, misapplied_to_id, misapplied_by_id, misapplied_by_citation, misapplied_on_page, synonyms {id, name_id, full_name, full_name_html, instance_type, label, page, name_status_name} notes{ id, key, value} }}}}}' -X POST http://localhost:2004/v1 -o test4.log
diff test4.expected test4.log

echo test5: name show for id 91755
rm test5.log
curl -S -d 'query={ name(id: 91755) { id, simple_name, full_name, full_name_html, family_name, name_status_name, name_history { name_usages { instance_id, reference_id, citation, page, page_qualifier, year, standalone, instance_type_name, accepted_tree_status, primary_instance, misapplied, misapplied_to_name, misapplied_to_id, misapplied_by_id, misapplied_by_citation, misapplied_on_page, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } } } }' -X POST http://localhost:2004/v1 -o test5.log
diff test5.expected test5.log

echo test6: name show for non-existing id 87221755
rm test6.log
curl -S -d 'query={ name(id: 87221755) { id, simple_name, full_name, full_name_html, family_name, name_status_name, name_history { name_usages { instance_id, reference_id, citation, page, page_qualifier, year, standalone, instance_type_name, accepted_tree_status, primary_instance, misapplied, misapplied_to_name, misapplied_to_id, misapplied_by_id, misapplied_by_citation, misapplied_on_page, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } } } }' -X POST http://localhost:2004/v1 -o test6.log
diff test6.expected test6.log
