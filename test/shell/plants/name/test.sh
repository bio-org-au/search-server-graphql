

temp_dir='/tmp'

detail_fields='{ id, simple_name, full_name, full_name_html, family_name, name_status_name, name_usages { instance_id, standalone, instance_type_name, accepted_tree_status, reference_details {id, citation, citation_html, page, page_qualifier, year, full_citation_with_page}, primary_instance, misapplication, misapplication_details {direction, misapplied_to_full_name, misapplied_to_name_id, misapplied_in_references {id, citation, page, page_qualifier, display_entry}, misapplication_type_label }, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } }'

test_number=1
test_name="test${test_number}"
echo ${test_name}: name search list Angophora costata with trailing wildcard, publication year 1962, limit: 10
curl -s -d 'query={name_search(search_term:"Angophora*",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log


echo " "
test_number=2
test_name="test${test_number}"
echo ${test_name}: name search list Angophora with publication year 1962, limit: 10
curl -s -d 'query={name_search(search_term:"Angophora",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log


echo " "
test_number=3
test_name="test${test_number}"
echo ${test_name}: name search list Angophora with trailing wildcard, publication year 1962, limit: 10
curl -s -d 'query={name_search(search_term:"Angophora*",publication_year:"1962",limit:10){count,names{id,simple_name,full_name,name_status_name,family_name}}}' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log


echo " "
test_number=4
test_name="test${test_number}"
echo ${test_name}: name search list genus: angophora, name element: corda*, type of name: scientific, limit: 10
curl -s -d "query={name_search(genus: \"angophora\", name_element: \"corda*\", type_of_name: \"scientific\", limit: 10){count, names ${detail_fields} } }" -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
sed -i '' -e '$a\' $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log


echo " "
test_number=5
test_name="test${test_number}"
echo ${test_name}: name show for id 91755
curl -s -d 'query={ name(id: 91755) { id, simple_name, full_name, full_name_html, family_name, name_status_name, name_usages { instance_id, standalone, instance_type_name, accepted_tree_status, reference_details {id, citation, citation_html, page, page_qualifier, year, full_citation_with_page}, primary_instance, misapplication, misapplication_details {direction, misapplied_to_full_name, misapplied_to_name_id, misapplied_in_references {id, citation, page, page_qualifier, display_entry}, misapplication_type_label }, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } } }' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
sed -i '' -e '$a\' $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log


echo " "
test_number=6
test_name="test${test_number}"
echo ${test_name}: name show for non-existing id 87221755
curl -s -d 'query={ name(id: 87221755) { id, simple_name, full_name, full_name_html, family_name, name_status_name, name_usages { instance_id, standalone, instance_type_name, accepted_tree_status, reference_details {id, citation, citation_html, page, page_qualifier, year, full_citation_with_page}, primary_instance, misapplication, misapplication_details {direction, misapplied_to_full_name, misapplied_to_name_id, misapplied_in_references {id, citation, page, page_qualifier, display_entry}, misapplication_type_label }, synonyms { id, full_name, instance_type, label, page, name_status_name, } notes { id, key, value } } } }' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log


echo " "
test_number=7
test_name="test${test_number}"
echo $test_name: query runtime environment
curl -s -d 'query={ runtime_environment {ruby_platform, ruby_version, rails_version, database} }' -X POST http://localhost:2004/v1 -o $temp_dir/${test_name}.log
sed -i '' -e '$a\' $temp_dir/${test_name}.log
diff ${test_name}.expected $temp_dir/${test_name}.log
