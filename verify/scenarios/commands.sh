PAGE=$DOCS/docs/reference/commands.md
fresh 'command inventory' modules
check 'Inventory shell forms run' doc_shell 'Inspecting the layout'
check 'JSON has the documented root keys' sh -c "cd '$APP' && '$PHP' artisan mod:list --json | '$PHP' -r '\$i=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR); exit(array_keys(\$i)===[\"layout\",\"extends\",\"path\",\"token\",\"groups\",\"types\",\"templates\",\"scaffolds\",\"discovery\"]?0:1);'"
check 'Invalid inventory type fails' fails art mod:list --type=missing
check 'Create templates from command examples' doc_shell 'Creating templates'
check 'Template commands are registered' out_has mod:tool list mod
fresh 'command autoload' ddd
check 'Autoload shell forms run' doc_shell 'Registering autoload mappings'
check 'Domain mapping is present' grep -F 'src/Domain/' "$APP/composer.json"
fresh 'missing command output' modules
check 'Missing generator exits with the documented guidance' doc_shell 'Commands from another layout' 1 1
check 'Missing generator text is current' doc_output 'Commands from another layout'
fresh 'bases command' modules
check 'mod:bases writes missing base classes' doc_shell 'Writing base classes'
check 'mod:bases output matches' doc_output 'Writing base classes'

check 'Listed alias wording matches the reference' sh -c "cd '$APP' && '$PHP' artisan list mod --no-ansi | grep -F 'mod:value-object' | grep -F '[mod:value|mod:valueobject]'"
check 'Cache and clear commands run' art mod:cache
check 'Cache clears' art mod:clear
