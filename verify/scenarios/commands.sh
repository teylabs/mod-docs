PAGE=$DOCS/docs/reference/commands.md
fresh 'command inventory' modules
check 'Inventory shell forms run' doc_shell 'Inspecting the layout'
check 'JSON has the documented root keys' sh -c "cd '$APP' && '$PHP' artisan mod:list --json | '$PHP' -r '\$i=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR); exit(array_keys(\$i)===[\"layout\",\"extends\",\"path\",\"token\",\"groups\",\"types\",\"templates\",\"scaffolds\",\"discovery\",\"views\",\"frontend\",\"stack\",\"wiring\",\"routes\",\"rename\"]?0:1);'"
check 'Invalid inventory type fails' fails art mod:list --type=missing
check 'Create templates from command examples' doc_shell 'Creating templates'
check 'Template commands are registered' out_has mod:tool list mod
fresh 'command autoload' ddd
check 'Autoload shell forms run' doc_shell 'Registering autoload mappings'
check 'Configured mappings use the revised notice' out_has 'Every root of the ddd layout has its Composer mapping configured.' mod:autoload
check 'Configured mappings explain how to reload classes' out_has 'If classes do not load, run composer dump-autoload.' mod:autoload
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

fresh 'factory and policy inventory' modules
art mod:model Knowledge:Document --factory > /dev/null
art mod:policy Knowledge:DocumentPolicy --model=Document > /dev/null
check 'Inventory counts discovered factories and policies' out_has '1 factories, 1 policies' mod:list
check 'Verbose inventory names the factory target' out_has 'App\Modules\Knowledge\Models\Document -> App\Modules\Knowledge\Database\Factories\DocumentFactory' mod:list -v
check 'Verbose inventory names the policy target' out_has 'App\Modules\Knowledge\Models\Document -> App\Modules\Knowledge\Policies\DocumentPolicy' mod:list -v
