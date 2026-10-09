PAGE=$DOCS/docs/guide/upgrade.md
fresh '0.1 to 0.2 API' modules
check 'The before example records the 0.1 calls' doc_block 'Before' php
check 'The after example uses the released API' doc_boot 'After'
check 'The migrated custom file type generates' doc_shell 'After'
check 'The migrated model and factory generate together' art mod:model Knowledge:Document --factory
check 'The migrated factory exists' has app/Modules/Knowledge/Database/Factories/DocumentFactory.php
check 'The old method has been removed' tinker 'if (method_exists(\Tey\Mod\Layout\Layout::class, "kind")) { exit(1); }'
