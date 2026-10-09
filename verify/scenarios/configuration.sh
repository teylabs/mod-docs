PAGE=$DOCS/docs/reference/configuration.md
fresh 'configuration defaults' modules
check 'Configuration publish command writes the file' doc_shell 'Configuration'
boot "\\Tey\\Mod\\Facades\\Mod::layout('modules')->generates('handler', in: 'Modules/{module}/Handlers');"
doc_config 'discovery.file_types'
check 'Renamed discovery key compiles and caches' art mod:cache
check 'The configured discovery key is active' grep -F "'file_types'" "$APP/config/mod.php"
