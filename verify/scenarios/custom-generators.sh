PAGE=$DOCS/docs/going-further/custom-generators.md
fresh 'template-first workflow' modules
mkdir -p "$APP/app/Modules/Agents/Models"
check 'Create the tool template from the page' doc_shell 'Creating a generator'
check 'Creation output matches E2' doc_output 'Creating a generator'
doc_file 'Editing the template' 'stubs/mod/@module/Tools/tool.stub'
check 'Generate the tool from the edited template' doc_shell 'Editing the template'
check 'Tool is valid PHP' has app/Modules/Agents/Tools/SearchDocuments.php
check 'Tool namespace follows the module' grep -F 'namespace App\Modules\Agents\Tools;' "$APP/app/Modules/Agents/Tools/SearchDocuments.php"
check 'Starting types create usable templates' doc_shell 'Choosing a starting type'
check 'DTO template creates its base' art mod:payload Agents:DocumentData
check 'DTO is valid PHP' has app/Modules/Agents/Payloads/DocumentData.php
check 'Quoted bracket creation runs through zsh' doc_shell 'Paths and slots'
check 'Slot generation writes valid PHP' has app/Modules/Agents/Webhooks/Drive/FileChanged.php
check 'Missing slot refuses and names the answering flag' doc_shell 'When something is off' 1 1
check 'Slot error matches acceptance output' doc_output 'When something is off'
check 'Inventory diagnoses templates' doc_shell 'When something is off' 2
check 'Extraction short name works without loading source PHP' doc_shell 'From an existing class'
check 'Extracted template preserves the body' grep -F 'public function __construct()' "$APP/stubs/mod/@module/Tools/search.stub"
fresh 'PHP bridge' modules
mkdir -p "$APP/stubs" "$APP/app/Modules/Agents/Models"
doc_file 'Editing the template' 'stubs/tool.stub'
doc_boot 'The same, in PHP'
check 'PHP declaration produces the same tool' art mod:tool Agents:SearchDocuments
check 'PHP tool is valid and has the same namespace' has app/Modules/Agents/Tools/SearchDocuments.php
fresh 'template refinement' modules
mkdir -p "$APP/app/Modules/Agents/Models"
art mod:template dto @module/Data/links
# PHP refinement is applied after the template scanner compiles the file type.
doc_boot 'Refining a template'
check 'Refinement gives the DTO its suffix' art mod:links Agents:Document
check 'Refined class exists' has app/Modules/Agents/Data/DocumentLinks.php
fresh 'prefixed DDD anchor' ddd
check 'Literal application path before the domain anchor' doc_shell 'The application layer in DDD'
check 'Application-layer template creates the documented class' has app/Modules/Knowledge/Presenters/ShowDocument.php
fresh 'package template folder' modules
mkdir -p "$APP/app/stubs/@group/Tools"
doc_file 'Editing the template' 'app/stubs/@group/Tools/tool.stub'
doc_boot 'Packages'
check 'A neutral package anchor follows the app layout' art mod:tool Agents:PackageTool
check 'Package tool exists' has app/Modules/Agents/Tools/PackageTool.php
mkdir -p "$APP/stubs/mod/@module/Tools"
doc_file 'Editing the template' 'stubs/mod/@module/Tools/tool.stub'
check 'App template wins over package template' art mod:list --json
