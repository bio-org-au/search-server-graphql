

temp_dir='/tmp'

echo test1: name search list Angophora costata with trailing wildcard, publication year 1962, limit: 10
curl -S -d 'query={name_search(search_term:"Angophora*",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o $temp_dir/test1.log
diff test1.expected $temp_dir/test1.log

echo test2: name search list Angophora with publication year 1962, limit: 10
curl -S -d 'query={name_search(search_term:"Angophora",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o $temp_dir/test2.log
diff test2.expected $temp_dir/test2.log

echo test3: name search list Angophora with trailing wildcard, publication year 1962, limit: 10
curl -S -d 'query={name_search(search_term:"Angophora*",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o $temp_dir/test3.log
diff test3.expected $temp_dir/test3.log

echo test4: name search list genus: angophora, name element: corda*, type of name: scientific, limit: 10
curl -S -d 'query={name_search(genus: "angophora", name_element: "corda*", type_of_name: "scientific", limit: 10){count, names {id, simple_name, full_name, full_name_html, name_status_name, family_name, name_history {name_usages {instance_id, reference_id, citation, page, page_qualifier, year, standalone, instance_type_name, accepted_tree_status, primary_instance, misapplied, misapplied_to_name, misapplied_to_id, misapplied_by_id, misapplied_by_citation, misapplied_on_page, synonyms {id, name_id, full_name, full_name_html, instance_type, label, page, name_status_name} notes{ id, key, value} }}}}}' -X POST http://localhost:2004/v1 -o $temp_dir/test4.log
diff test4.expected $temp_dir/test4.log

echo test5: name show for id 91755
curl -S -d 'query={ name(id: 91755) { id, simple_name, full_name, full_name_html, family_name, name_status_name, name_history { name_usages { instance_id, reference_id, citation, page, page_qualifier, year, standalone, instance_type_name, accepted_tree_status, primary_instance, misapplied, misapplied_to_name, misapplied_to_id, misapplied_by_id, misapplied_by_citation, misapplied_on_page, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } } } }' -X POST http://localhost:2004/v1 -o $temp_dir/test5.log
diff test5.expected $temp_dir/test5.log

echo test6: name show for non-existing id 87221755
curl -S -d 'query={ name(id: 87221755) { id, simple_name, full_name, full_name_html, family_name, name_status_name, name_history { name_usages { instance_id, reference_id, citation, page, page_qualifier, year, standalone, instance_type_name, accepted_tree_status, primary_instance, misapplied, misapplied_to_name, misapplied_to_id, misapplied_by_id, misapplied_by_citation, misapplied_on_page, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } } } }' -X POST http://localhost:2004/v1 -o $temp_dir/test6.log
diff test6.expected $temp_dir/test6.log

test_number=7
test_name="test${test_number}"
echo $test_name
echo Query runtime environment
curl -S -d 'query={ runtime_environment }' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log
