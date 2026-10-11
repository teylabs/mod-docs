# Checks the optional native generators described in MCP File Types.
PAGE=$DOCS/docs/basics/generating-files.md
# Keep the optional Composer dependency out of the baseline apps.
source_app=$APP
APP=$WORK/copy-$MAJOR
mkdir -p "$APP"
rsync -a --delete "$source_app/" "$APP/"

for layout in modules ddd; do
    fresh "native MCP: $layout" "$layout"
    check 'Install Laravel MCP in the disposable app' sh -c "cd '$APP' && '$PHP' '$COMPOSER_BIN' require laravel/mcp --quiet"
    if [ "$layout" = modules ]; then
        check 'Documented module commands run' doc_shell 'MCP File Types' 1
        check 'Documented server path contains valid PHP' has app/Modules/Knowledge/Mcp/Servers/DocumentServer.php
        check 'Documented tool path contains valid PHP' has app/Modules/Knowledge/Mcp/Tools/SearchDocuments.php
        check 'Documented resource path contains valid PHP' has app/Modules/Knowledge/Mcp/Resources/DocumentResource.php
        check 'Documented prompt path contains valid PHP' has app/Modules/Knowledge/Mcp/Prompts/SummarizeDocument.php
        group=Inventory
    else
        art mod:autoload
        check 'Documented nested DDD command runs' doc_shell 'MCP File Types' 2
        check 'Nested DDD tool belongs to the application root' has app/Modules/Knowledge/Search/Mcp/Tools/SearchDocuments.php
        group=Inventory/Search
    fi
    for kind in server tool resource prompt; do
        case $kind in server) folder=Servers;; tool) folder=Tools;; resource) folder=Resources;; prompt) folder=Prompts;; esac
        path="app/Modules/$group/Mcp/$folder/ParityProbe.php"
        check "$layout $kind native generator runs" art "make:mcp-$kind" ParityProbe
        check "$layout $kind preview reports its placement" out_has "$path" "mod:mcp-$kind" "$group:ParityProbe" --dry-run --json
        check "$layout $kind preview writes no class" test ! -f "$APP/$path"
        check "$layout $kind placed generator runs" art "mod:mcp-$kind" "$group:ParityProbe"
        check "$layout $kind matches native bytes except namespace" "$PHP" "$VERIFY/mcp-parity.php" "$APP/app/Mcp/$folder/ParityProbe.php" "$APP/$path" "$group" "$folder"
        check "$layout $kind class loads" classes_load "App\\Modules\\${group//\//\\}\\Mcp\\$folder\\ParityProbe"
    done
    check 'Companion-view generator is not added' sh -c "cd '$APP' && ! '$PHP' artisan list --raw | grep -q '^mod:mcp-app-resource '"
done
