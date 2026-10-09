PAGE=$DOCS/docs/reference/layout-api.md
fresh 'Layout API' modules
check 'Public layout methods exist' tinker 'foreach (["mounts", "generates", "relates", "excludes", "path", "extends", "allowsNesting", "scaffolds"] as $method) { if (!method_exists(\Tey\Mod\Layout\Layout::class, $method)) { exit(1); } }'
check 'Builder and exception imports resolve' tinker 'if (!class_exists(\Tey\Mod\Layout\FileType::class) || !class_exists(\Tey\Mod\Exceptions\UnknownFileType::class)) { exit(1); }'
check 'Scaffold registry code reads the finite inventory' doc_boot 'Scaffold registry'
check 'Registry example boots' art mod:list --json
check 'Scaffold builder methods exist' tinker 'foreach (["makes", "include", "asks", "each", "part"] as $method) { if (!method_exists(\Tey\Mod\Scaffolds\Scaffold::class, $method)) { exit(1); } }'

check 'Compiled namespace lookup returns the app namespace' out_has 'App\Modules\Knowledge' tinker --execute 'echo \Tey\Mod\Facades\Mod::current()->namespaceFor("app/Modules/Knowledge");'
