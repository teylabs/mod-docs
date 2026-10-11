# Checks the module translation examples in Module Translations.
PAGE=$DOCS/docs/going-further/translations.md
fresh 'module translations' modules
check 'Documented module language file is written' doc_file 'Adding Translations' app/Modules/Inventory/lang/en/messages.php
check 'Module key resolves through its namespace' out_has 'Inventory saved.' tinker --execute "echo __('inventory::messages.saved');"
check 'Inventory lists the translation folder' out_has '"namespace": "inventory"' mod:list --json
check 'Documented application override is written' doc_file "Overriding a Module's Keys" lang/vendor/inventory/en/messages.php
check 'Application override wins' out_has 'Stock saved.' tinker --execute "echo __('inventory::messages.saved');"
