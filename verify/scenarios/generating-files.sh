# Checks docs/basics/generating-files.md.
PAGE=$DOCS/docs/basics/generating-files.md

# Generating + Placement + Auto-Discovery
fresh "generating" modules
check "The generator succeeds: mod:event Knowledge:DocumentUploaded" art mod:event Knowledge:DocumentUploaded
check "The generator succeeds: mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded" art mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded
check "listener imports the module event" grep -q 'use App\\Modules\\Knowledge\\Events\\DocumentUploaded;' "$APP/app/Modules/Knowledge/Listeners/GenerateEmbeddings.php"
check "The generator succeeds: mod:job Knowledge:ExtractText" art mod:job Knowledge:ExtractText
check "The file exists and passes PHP syntax: app/Modules/Knowledge/Jobs/ExtractText.php" has app/Modules/Knowledge/Jobs/ExtractText.php
check "list mod shows mod:model" out_has "mod:model" list mod
check "dash-free alias mod:viewmodel" sh -c "cd '$APP' && '$PHP' artisan mod:viewmodel Knowledge:ListDocuments --no-ansi | grep -qF 'app/Modules/Knowledge/ViewModels/ListDocuments.php'"
check "dash-free alias mod:valueobject" sh -c "cd '$APP' && '$PHP' artisan mod:valueobject Knowledge:Checksum --no-ansi | grep -qF 'app/Modules/Knowledge/ValueObjects/Checksum.php'"
check "dash-free alias mod:jobmiddleware" sh -c "cd '$APP' && '$PHP' artisan mod:jobmiddleware Knowledge:RateLimited --no-ansi | grep -qF 'app/Modules/Knowledge/Jobs/Middleware/RateLimited.php'"
check "a command the layout lacks names the layout that has it (exit 1)" sh -c "cd '$APP' && ! '$PHP' artisan mod:handler Knowledge:Thing -q; '$PHP' artisan mod:handler Knowledge:Thing --no-ansi 2>&1 | grep -qF 'mod:handler is not a command of the modules layout. The slices layout has it.'"
check "case-only mismatch uses the existing module" sh -c "cd '$APP' && '$PHP' artisan mod:model knowledge:Note --no-ansi 2>&1 | grep -qF 'Using existing module Knowledge (you typed knowledge).' && grep -q 'namespace App.Modules.Knowledge.Models;' app/Modules/Knowledge/Models/Note.php && rm app/Modules/Knowledge/Models/Note.php"
art mod:model Agents:Conversation >/dev/null
check "a new module is announced with the existing ones" sh -c "cd '$APP' && '$PHP' artisan mod:model Knowledg:Note --no-interaction --no-ansi | grep -qF 'Created new module Knowledg (existing: Agents, Knowledge).' && rm -rf app/Modules/Knowledg app/Modules/Agents"
check "The generator succeeds: mod:model Document --module=Knowledge" art mod:model Document --module=Knowledge
check "The generator succeeds: mod:model Order --in=Knowledge" art mod:model Order --in=Knowledge
check "The file exists and passes PHP syntax: app/Modules/Knowledge/Models/Order.php" has app/Modules/Knowledge/Models/Order.php
check "an existing file prints an error and writes nothing" sh -c "cd '$APP' && echo '// mine' >> app/Modules/Knowledge/Models/Order.php && '$PHP' artisan mod:model Knowledge:Order -f 2>&1 | grep -q ERROR && grep -q '// mine' app/Modules/Knowledge/Models/Order.php && test ! -e app/Modules/Knowledge/Database/Factories/OrderFactory.php"
check "The generator succeeds: mod:command Knowledge:PruneDocuments" art mod:command Knowledge:PruneDocuments
check "the command is registered" out_has "app:prune-documents" list
check "event:list shows the listener" out_has "App\\Modules\\Knowledge\\Listeners\\GenerateEmbeddings@handle" event:list --event=DocumentUploaded
check "listener registered once" sh -c "[ \$(cd '$APP' && '$PHP' artisan event:list --event=DocumentUploaded | grep -c GenerateEmbeddings) = 1 ]"

fresh 'documented generators' modules
check 'Event and listener commands write the documented paths' doc_shell 'Running a Generator'
check 'The documented command listing succeeds' doc_shell 'Listing the Commands'
fresh 'documented related-file tree' modules
check 'The documented related-file command succeeds' doc_shell 'Generating Related Files'
check 'Related files match the documented tree' doc_tree 'Generating Related Files'
check 'The missing-module command exits with an error' doc_shell 'Leaving the Module Out' 1 1
check 'The missing-module error matches the page' doc_output 'Leaving the Module Out'
check 'A new module is generated as documented' doc_shell 'New and Misspelled Modules' 1
check 'The new-module notice matches the page' doc_output 'New and Misspelled Modules' 1
check 'A case-only mismatch uses the existing module' doc_shell 'New and Misspelled Modules' 2
check 'The case correction matches the page' doc_output 'New and Misspelled Modules' 2
# Remove Billing and Note so the near-miss fixture has exactly the stated peers.
rm -rf "$APP/app/Modules/Billing" "$APP/app/Modules/Knowledge/Models/Note.php"
check 'A near miss without a terminal creates the new module' doc_shell 'New and Misspelled Modules' 3
check 'The noninteractive near-miss notice matches the page' doc_output 'New and Misspelled Modules' 4
check 'Existing model and factory commands exit with zero' doc_shell 'When a File Already Exists' 1
check 'Existing model and factory errors match the page' doc_output 'When a File Already Exists' 1
rm "$APP/app/Modules/Knowledge/Models/Document.php"
check 'An existing factory prevents a partial write' doc_shell 'When a File Already Exists' 2 1
check 'The refused-plan errors match the page' doc_output 'When a File Already Exists' 2
