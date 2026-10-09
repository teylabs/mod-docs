# Checks docs/going-further/stubs.md.
PAGE=$DOCS/docs/going-further/stubs.md


# Layout examples: Starter Stubs
fresh "docs: starters in features" features
boot "\\Tey\\Mod\\Facades\\Mod::layout('features')->kind('dto', in: 'Features/{feature}/Data');"
check "features dto starts as a DTO with the app/Support base" sh -c "cd '$APP' && out=\$('$PHP' artisan mod:dto Knowledge:DocumentData --no-ansi) && echo \"\$out\" | grep -qF 'Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].' && echo \"\$out\" | grep -qF 'DTO [app/Features/Knowledge/Data/DocumentData.php] created successfully.'"
fresh "docs: starter through stub:" features
boot "\\Tey\\Mod\\Facades\\Mod::layout('features')->kind('payload', in: 'Features/{feature}/Payloads', stub: \\Tey\\Mod\\Generation\\Starters::dto());"
check "payload with Starters::dto() extends the DTO base" sh -c "cd '$APP' && '$PHP' artisan mod:payload Knowledge:DocumentPayload --no-ansi >/dev/null && grep -q 'extends DataTransferObject' app/Features/Knowledge/Payloads/DocumentPayload.php"
fresh "docs: ddd bases" ddd
check "ddd base in src/Domain/Shared" sh -c "cd '$APP' && out=\$('$PHP' artisan mod:dto Knowledge:DocumentData --no-ansi) && echo \"\$out\" | grep -qF 'Created base class Domain\Shared\Data\DataTransferObject [src/Domain/Shared/Data/DataTransferObject.php].' && echo \"\$out\" | grep -qF 'DTO [src/Domain/Knowledge/Data/DocumentData.php] created successfully.'"
check "ddd provider named as given" sh -c "cd '$APP' && '$PHP' artisan mod:provider Knowledge:Knowledge --no-ansi | grep -qF 'src/Domain/Knowledge/Providers/Knowledge.php'"
fresh "docs: modules dto and alias" modules
check "modules: mod:dto writes Data" sh -c "cd '$APP' && '$PHP' artisan mod:dto Knowledge:DocumentData --no-ansi | grep -qF 'app/Modules/Knowledge/Data/DocumentData.php'"
check "modules: mod:data is the same command" sh -c "cd '$APP' && '$PHP' artisan mod:data Knowledge:ChunkData --no-ansi | grep -qF 'DTO [app/Modules/Knowledge/Data/ChunkData.php]'"
check "modules: mod:value writes ValueObjects" sh -c "cd '$APP' && '$PHP' artisan mod:value Knowledge:ContentHash --no-ansi | grep -qF 'app/Modules/Knowledge/ValueObjects/ContentHash.php'"
check "modules: mod:view-model writes ViewModels" sh -c "cd '$APP' && '$PHP' artisan mod:view-model Knowledge:ShowDocument --no-ansi | grep -qF 'app/Modules/Knowledge/ViewModels/ShowDocument.php'"
check "modules: provider gets ServiceProvider" sh -c "cd '$APP' && '$PHP' artisan mod:provider Knowledge:Knowledge --no-ansi | grep -qF 'app/Modules/Knowledge/Providers/KnowledgeServiceProvider.php'"
check "mod:bases prints both when missing" sh -c "cd '$APP' && rm -rf app/Support && out=\$('$PHP' artisan mod:bases --no-ansi) && echo \"\$out\" | grep -qF 'Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].' && echo \"\$out\" | grep -qF 'Created base class App\Support\ViewModels\ViewModel [app/Support/ViewModels/ViewModel.php].'"
check "configured BaseData" sh -c "cd '$APP' && perl -0pi -e \"s/'dto' => null/'dto' => App\\\\\\\\Support\\\\\\\\BaseData::class/\" config/mod.php && '$PHP' artisan mod:dto Knowledge:SummaryData --no-ansi | grep -qF 'Using the configured base App\Support\BaseData.'"
check "bases_path default in config" grep -q "'bases_path' => 'app/Support'" "$APP/config/mod.php"

# Read the starter, base and override examples from their current page.
fresh 'documented repository stub' ddd
PAGE=$DOCS/docs/going-further/custom-layouts.md
doc_boot 'Adding a Layer'
PAGE=$DOCS/docs/going-further/stubs.md
doc_file 'Starting From Your Own Stub' stubs/mod.repository.stub
check 'The repository example uses the app stub at the documented path' doc_shell 'Starting From Your Own Stub'
check 'The repository is valid PHP' has src/Infrastructure/Knowledge/Repositories/DocumentRepository.php
fresh 'documented feature DTO starter' features
doc_boot 'Starter Stubs'
check 'The feature DTO example uses its starter and shared base' doc_shell 'Starter Stubs' 2
fresh 'documented payload starter' features
doc_boot 'Starter Stubs' 2
check 'A differently named file type accepts the DTO starter' art mod:payload Knowledge:DocumentPayload
check 'The payload extends DataTransferObject' grep -F 'extends DataTransferObject' "$APP/app/Features/Knowledge/Payloads/DocumentPayload.php"
fresh 'documented module DTO base' modules
check 'The first DTO command succeeds' doc_shell 'Generated Base Classes' 1
check 'Generated base output matches the page' doc_output 'Generated Base Classes'
fresh 'documented DDD DTO base' ddd
check 'DDD generates its base in the documented shared folder' doc_shell 'Generated Base Classes' 2
fresh 'documented missing bases' modules
check 'The missing-base command succeeds' doc_shell 'Writing Missing Bases'
check 'Missing-base output matches the page' doc_output 'Writing Missing Bases' 1
art mod:bases > "$WORK/doc-output.txt"
check 'A second base run matches the documented message' doc_output 'Writing Missing Bases' 2
printf '\n// Owned by the application\n' >> "$APP/app/Support/Data/DataTransferObject.php"
art mod:dto Knowledge:DocumentData --force > /dev/null
check 'Generating a DTO never overwrites an existing base' grep -F 'Owned by the application' "$APP/app/Support/Data/DataTransferObject.php"
fresh 'documented configured base' modules
doc_config 'Extending Your Own Base Class'
doc_file 'Using the Base in Your Stub' stubs/mod.dto.stub
check 'The app stub uses the configured base from the page' doc_shell 'Extending Your Own Base Class'
check 'The DTO imports the configured base' grep -F 'use App\Support\BaseData;' "$APP/app/Modules/Knowledge/Data/DocumentData.php"
