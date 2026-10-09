PAGE=$DOCS/docs/guide/introduction.md
fresh 'intro model' modules
check 'Introduction model command runs' doc_shell 'Generating files in your structure'
check 'Introduction tree matches generated files' doc_tree 'Generating files in your structure'
check 'Introduction listener commands run' doc_shell 'Discovery without registration'
check 'Introduction discovery output matches' doc_output 'Discovery without registration'
