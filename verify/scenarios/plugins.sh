# Checks docs/going-further/plugins.md.
PAGE=$DOCS/docs/going-further/plugins.md

# Plugin examples: Generating a Base Class, and inFileTypeRoot in ddd
fresh "docs: plugin generated base" modules
mkdir -p "$APP/pkg/stubs/bases"
printf '<?php\n\nnamespace {{ namespace }};\n{{ baseImport }}\nclass {{ class }}{{ extends }}\n{\n    public function __construct(\n        //\n    ) {}\n}\n' > "$APP/pkg/stubs/dto.stub"
printf '<?php\n\nnamespace {{ namespace }};\n\nabstract class {{ class }}\n{\n}\n' > "$APP/pkg/stubs/bases/data-transfer-object.stub"
boot "\\Tey\\Mod\\Facades\\Mod::stubs()->for('dto', \\Tey\\Mod\\Generation\\Stub::file(base_path('pkg/stubs/dto.stub'))->whenInstalled('spatie/laravel-data', base: 'Spatie\\\\LaravelData\\\\Data')->generatesBase(\\Tey\\Mod\\Generation\\GeneratedBase::named('DataTransferObject', in: 'Data', stub: base_path('pkg/stubs/bases/data-transfer-object.stub'))));"
check "plugin base in app/Support/Data" sh -c "cd '$APP' && out=\$('$PHP' artisan mod:dto Knowledge:DocumentData --no-ansi) && echo \"\$out\" | grep -qF 'Created base class App\Support\Data\DataTransferObject [app/Support/Data/DataTransferObject.php].' && echo \"\$out\" | grep -qF 'DTO [app/Modules/Knowledge/Data/DocumentData.php] created successfully.'"
fresh "docs: plugin base inFileTypeRoot" ddd
mkdir -p "$APP/pkg/stubs/bases"
printf '<?php\n\nnamespace {{ namespace }};\n{{ baseImport }}\nclass {{ class }}{{ extends }}\n{\n}\n' > "$APP/pkg/stubs/dto.stub"
printf '<?php\n\nnamespace {{ namespace }};\n\nabstract class {{ class }}\n{\n}\n' > "$APP/pkg/stubs/bases/data-transfer-object.stub"
boot "\\Tey\\Mod\\Facades\\Mod::stubs()->for('dto', \\Tey\\Mod\\Generation\\Stub::file(base_path('pkg/stubs/dto.stub'))->generatesBase(\\Tey\\Mod\\Generation\\GeneratedBase::named('DataTransferObject', in: 'Shared/Data', stub: base_path('pkg/stubs/bases/data-transfer-object.stub'))->inFileTypeRoot()));"
check "inFileTypeRoot base in src/Domain/Shared/Data" sh -c "cd '$APP' && '$PHP' artisan mod:dto Knowledge:DocumentData --no-ansi | grep -qF 'src/Domain/Shared/Data/DataTransferObject.php'"
fresh "docs: plugin builder alias" ddd
autoload 'Domain\' 'src/Domain/'
boot "\\Tey\\Mod\\Facades\\Mod::layout('ddd')->generates('builder', in: '{domain+}/Builders', suffix: 'Builder', aliases: ['mod:query-builder'], label: 'Query builder');"
check "mod:builder label" sh -c "cd '$APP' && '$PHP' artisan mod:builder Knowledge:Document --no-ansi | grep -qF 'Query builder [src/Domain/Knowledge/Builders/DocumentBuilder.php] created successfully.'"
check "mod:query-builder alias" sh -c "cd '$APP' && '$PHP' artisan mod:query-builder Knowledge:Chunk --no-ansi | grep -qF 'src/Domain/Knowledge/Builders/ChunkBuilder.php'"
check "mod:querybuilder dash-free alias" sh -c "cd '$APP' && '$PHP' artisan mod:querybuilder Knowledge:Page --no-ansi | grep -qF 'src/Domain/Knowledge/Builders/PageBuilder.php'"


fresh 'documented builder plugin' ddd
autoload 'Domain\' 'src/Domain/'
doc_boot 'Adding File Types and Commands'
check 'The plugin commands and label match the page' doc_shell 'Adding File Types and Commands'
# Place the provider at app/Providers: its ../stubs path then resolves to app/stubs.
doc_file 'Registering Stubs' app/stubs/builder.stub 2
doc_boot 'Registering Stubs'
check 'The plugin stub generates an Eloquent builder' art mod:builder Knowledge:Search
check 'The plugin builder extends Eloquent Builder' grep -F 'extends Builder' "$APP/src/Domain/Knowledge/Builders/SearchBuilder.php"
check 'The plugin builder autoloads' tinker 'new Domain\Knowledge\Builders\SearchBuilder(app(App\Models\User::class)->newQuery()->getQuery());'
# An app stub must win over the registered package stub.
mkdir -p "$APP/stubs"
printf '<?php\nnamespace {{ namespace }};\nclass {{ class }} { public const APP_STUB = true; }\n' > "$APP/stubs/mod.builder.stub"
check 'An app stub overrides the plugin stub' art mod:builder Knowledge:Override
check 'The app stub appears in the generated builder' grep -F 'APP_STUB = true' "$APP/src/Domain/Knowledge/Builders/OverrideBuilder.php"
rm "$APP/stubs/mod.builder.stub"
doc_file 'Swapping a Generator' pkg/src/Commands/BuilderCommand.php
autoload 'Knowledge\Tools\' 'pkg/src/'
doc_boot 'Swapping a Generator' 2
check 'A replacement plugin generator runs its hook' out_has 'Add a newEloquentBuilder() method to the model to use it.' mod:builder Knowledge:Custom
fresh 'documented plugin generated base' modules
PAGE=$DOCS/docs/going-further/stubs.md
doc_file 'Using the Base in Your Stub' app/stubs/dto.stub
PAGE=$DOCS/docs/going-further/plugins.md
mkdir -p "$APP/app/stubs/bases"
printf '<?php\nnamespace {{ namespace }};\nabstract class {{ class }} {}\n' > "$APP/app/stubs/bases/data-transfer-object.stub"
doc_boot 'Generating a Base Class'
check 'The plugin base and DTO output matches the page' doc_shell 'Generating a Base Class'
fresh 'documented discovery candidates' modules
art mod:event Knowledge:DocumentUploaded > /dev/null
art mod:listener Knowledge:GenerateEmbeddings --event=DocumentUploaded > /dev/null
art mod:listener Knowledge:Ignored --event=DocumentUploaded > /dev/null
doc_boot 'Supplying Discovery Candidates'
check 'The documented finder includes its supplied listener' out_has 'GenerateEmbeddings@handle' event:list --event=DocumentUploaded
check 'The documented finder omits other listeners' fails out_has 'Ignored@handle' event:list --event=DocumentUploaded
fresh 'documented command switch' modules
doc_config 'Turning Commands Off'
check 'The documented switch removes mod generators' fails out_has 'mod:model' list --raw
check 'The documented switch removes discovery cache commands' fails out_has 'mod:cache' list --raw

# Register the complete provider shown in the DDD plugin example.
fresh 'documented complete DDD plugin' ddd
autoload 'Domain\' 'src/Domain/'
autoload 'Vendor\Ddd\' 'pkg/src/'
doc_file 'Example: A DDD Plugin' pkg/src/DddServiceProvider.php
doc_file 'Registering Stubs' pkg/stubs/builder.stub 2
PAGE=$DOCS/docs/going-further/stubs.md
doc_file 'Using the Base in Your Stub' pkg/stubs/dto.stub
cp "$APP/pkg/stubs/dto.stub" "$APP/pkg/stubs/view-model.stub"
PAGE=$DOCS/docs/going-further/plugins.md
mkdir -p "$APP/pkg/stubs/bases"
printf '<?php\nnamespace {{ namespace }};\nabstract class {{ class }} {}\n' > "$APP/pkg/stubs/bases/data-transfer-object.stub"
printf '<?php\nreturn ["base_view_model" => Domain\\Shared\\ViewModels\\ViewModel::class];\n' > "$APP/config/ddd.php"
"$PHP" -r '$f=$argv[1]; $providers=require $f; $providers[]="Vendor\\Ddd\\DddServiceProvider"; file_put_contents($f,"<?php\nreturn ".var_export($providers,true).";\n");' "$APP/bootstrap/providers.php"
check 'The complete DDD plugin writes its builder and uses its configured view-model base' doc_shell 'Example: A DDD Plugin'
check 'The DDD builder uses the packaged Eloquent stub' grep -F 'extends Builder' "$APP/src/Domain/Knowledge/Builders/DocumentBuilder.php"
check 'The DDD plugin generates its DTO base in the domain root' art mod:dto Knowledge:DocumentData
check 'The DDD plugin base exists and is valid PHP' has src/Domain/Shared/Data/DataTransferObject.php

# Optional dependencies are installed only in a copy; the baseline stays plain.
COPY=$WORK/copy-$MAJOR
rm -rf "$COPY"
cp -R "$WORK/base-$MAJOR" "$COPY"
APP=$COPY
fresh 'installed package variants' modules
(cd "$APP" && "$PHP" "$COMPOSER_BIN" require spatie/laravel-data -q)
PAGE=$DOCS/docs/going-further/stubs.md
check 'The installed DTO package matches the starter example' doc_shell 'Starter Stubs' 1
PAGE=$DOCS/docs/going-further/stubs.md
doc_file 'Using the Base in Your Stub' app/stubs/dto.stub
PAGE=$DOCS/docs/going-further/plugins.md
doc_boot 'Using Another Package When It Is Installed'
rm "$APP/app/Modules/Knowledge/Data/DocumentData.php"
check 'A plugin variant uses the documented installed package' doc_shell 'Using Another Package When It Is Installed'
check 'The plugin DTO extends the installed Data class' grep -F 'use Spatie\LaravelData\Data;' "$APP/app/Modules/Knowledge/Data/DocumentData.php"
APP=$WORK/base-$MAJOR

fresh 'package template folder' modules
mkdir -p "$APP/app/stubs/mod/@group/Tools"
PAGE=$DOCS/docs/going-further/custom-generators.md
doc_file 'Editing the template' app/stubs/mod/@group/Tools/tool.stub
PAGE=$DOCS/docs/going-further/plugins.md
doc_boot 'Shipping generator templates'
check 'Package template command follows the app layout' art mod:tool Knowledge:PackageTool
check 'Package template writes valid PHP' has app/Modules/Knowledge/Tools/PackageTool.php
fresh 'package scaffold' modules
mkdir -p "$APP/app/stubs"
# A self-contained native controller stub is the fixture for the package variant.
cat > "$APP/app/stubs/controller.crud.stub" <<'STUB'
<?php
namespace {{ namespace }};
class {{ class }} {}
STUB
doc_boot 'Shipping scaffolds'
check 'Package scaffold uses its registered variant' art mod:document Knowledge:Document
check 'Package scaffold controller is valid' has app/Modules/Knowledge/Controllers/DocumentController.php
