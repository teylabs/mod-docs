# Checks docs/going-further/custom-layouts.md.
PAGE=$DOCS/docs/going-further/custom-layouts.md

# Your Own File Types
fresh "own file type" modules
boot "\\Tey\\Mod\\Facades\\Mod::layout('modules')->generates('validator', in: 'Modules/{module}/Validators', suffix: 'Validator');"
check "The generator succeeds: mod:validator Knowledge:Upload" art mod:validator Knowledge:Upload
check "The file exists and passes PHP syntax: app/Modules/Knowledge/Validators/UploadValidator.php" has app/Modules/Knowledge/Validators/UploadValidator.php
mkdir -p "$APP/stubs"; cat > "$APP/stubs/mod.validator.stub" <<'STUB'
<?php

namespace {{ namespace }};

class {{ class }}
{
    public function rules(): array
    {
        return [];
    }
}
STUB
check "The generator succeeds: mod:validator Knowledge:Refund with the stub" art mod:validator Knowledge:Refund
check "stub applied and valid PHP" sh -c "grep -q 'public function rules(): array' '$APP/app/Modules/Knowledge/Validators/RefundValidator.php' && '$PHP' -l '$APP/app/Modules/Knowledge/Validators/RefundValidator.php'"
check "validator class loads" sh -c "cd '$APP' && '$PHP' artisan tinker --execute 'echo json_encode((new App\Modules\Knowledge\Validators\RefundValidator)->rules());' | grep -q '\[\]'"

# Layout examples
fresh "docs: layouts" type-first
check "type-first: mod:job Knowledge:ExtractText" art mod:job Knowledge:ExtractText
check "The file exists and passes PHP syntax: app/Jobs/Knowledge/ExtractText.php" has app/Jobs/Knowledge/ExtractText.php
check "type-first: mod:job ExtractText" art mod:job ExtractText
check "The file exists and passes PHP syntax: app/Jobs/ExtractText.php" has app/Jobs/ExtractText.php
check "type-first: mod:config" art mod:config billing
fresh "docs: extend features" features
boot "\\Tey\\Mod\\Facades\\Mod::layout('features')->generates('job', in: 'Features/{feature}/Queue');"
check "The generator succeeds: mod:job Knowledge:ExtractText" art mod:job Knowledge:ExtractText
check "The file exists and passes PHP syntax: app/Features/Knowledge/Queue/ExtractText.php" has app/Features/Knowledge/Queue/ExtractText.php
check "The generator succeeds: mod:test Knowledge:DocumentTest --unit" art mod:test Knowledge:DocumentTest --unit
check "The file exists and passes PHP syntax: tests/Unit/Knowledge/DocumentTest.php" has tests/Unit/Knowledge/DocumentTest.php
check "The file exists and passes PHP syntax: the Queue job's path follows in: from app/" has app/Features/Knowledge/Queue/ExtractText.php
fresh "docs: repeated kind keeps root" ddd
boot "\\Tey\\Mod\\Facades\\Mod::layout('ddd')->generates('controller', in: '{domain+}/Http/Controllers');"
check "ddd controller stays in app/Modules" sh -c "cd '$APP' && '$PHP' artisan mod:controller Knowledge:DocumentController --no-ansi | grep -qF 'app/Modules/Knowledge/Http/Controllers/DocumentController.php'"
fresh "docs: relation by id" modules
boot "\\Tey\\Mod\\Facades\\Mod::layout('modules')->relates('model', 'seeder', name: ['suffix' => 'Data']);"
check "model-seeder renamed: DocumentDataSeeder" sh -c "cd '$APP' && '$PHP' artisan mod:model Knowledge:Document --seed --no-ansi | grep -qF 'app/Modules/Knowledge/Database/Seeders/DocumentDataSeeder.php'"
fresh "docs: defining a layout" domains
boot "\\Tey\\Mod\\Facades\\Mod::layout('domains')->mounts('domain', 'Domain\\\\', 'src/Domain', fn (\\Tey\\Mod\\Layout\\Root \$root) => \$root->generates('model', in: '{domain}/Models')->generates('action', in: '{domain}/Actions'))->mounts('app', 'App\\\\', 'app', fn (\\Tey\\Mod\\Layout\\Root \$root) => \$root->generates('controller', in: 'Modules/{domain}/Http/Controllers', suffix: 'Controller'))->generates('factory', in: 'domain:{domain}/Database/Factories', suffix: 'Factory')->relates('model', 'factory')->excludes('App\\\\Support\\\\');"
art mod:autoload
check "The generator succeeds: mod:model Knowledge:Document --factory" art mod:model Knowledge:Document --factory
check "The file exists and passes PHP syntax: src/Domain/Knowledge/Models/Document.php" has src/Domain/Knowledge/Models/Document.php
check "The file exists and passes PHP syntax: src/Domain/Knowledge/Database/Factories/DocumentFactory.php" has src/Domain/Knowledge/Database/Factories/DocumentFactory.php
check "The generator succeeds: mod:controller Knowledge:DocumentController" art mod:controller Knowledge:DocumentController
check "The file exists and passes PHP syntax: app/Modules/Knowledge/Http/Controllers/DocumentController.php" has app/Modules/Knowledge/Http/Controllers/DocumentController.php
fresh "docs: placement option" modules
boot "\\Tey\\Mod\\Facades\\Mod::layout('modules')->path('app/Modules/{area}');"
check "The generator succeeds: mod:model Document --area=Knowledge" art mod:model Document --area=Knowledge
check "The file exists and passes PHP syntax: app/Modules/Knowledge/Models/Document.php" has app/Modules/Knowledge/Models/Document.php


fresh 'documented validator' modules
doc_boot 'Customizing a built-in layout'
check 'The validator example writes its documented path' doc_shell 'Customizing a built-in layout'
fresh 'documented job customization' features
doc_boot 'Moving a Folder'
check 'The customized job folder matches the page' doc_shell 'Moving a Folder'
fresh 'documented custom layout' domains
doc_boot 'Defining a Layout'
art mod:autoload
check 'The custom layout writes its documented model and factory' doc_shell 'Defining a Layout'
fresh 'documented renamed options' modules
doc_boot 'Renaming an Option'
check 'The renamed area option places a model' art mod:model Document --area=Knowledge
check 'The renamed operation option places a handler' sh -c "LAYOUT=slices perl -0pi -e 's/\x27layout\x27 => \x27modules\x27/\x27layout\x27 => \x27slices\x27/' '$APP/config/mod.php'"
check 'The renamed slice option creates Handler.php' art mod:handler --feature=Knowledge --operation=IndexDocument
fresh 'documented infrastructure layer' ddd
doc_boot 'Adding a Layer'
art mod:autoload
art mod:autoload
check 'Infrastructure generators write their documented paths' doc_shell 'Adding a Layer'
doc_boot 'Adding a Layer' 2
check 'A built-in job can move into the new root' art mod:job Knowledge:ExtractText
check 'The job is written in Infrastructure' has src/Infrastructure/Knowledge/Jobs/ExtractText.php

fresh 'extended layout with moved groups' areas
doc_boot 'Extending a layout'
check 'The moved group path registers and generates' doc_shell 'Extending a layout'
check 'The moved model class loads' classes_load 'Areas\Billing\Models\Invoice'
