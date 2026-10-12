# F16: compile and render the documented recipe in both real starter kits.
PAGE=$DOCS/docs/going-further/frontend.md
page_shape() {
    local baseline=$APP modal commands generate grow preview apply uri component
    # Main continues to verify the latest release. Unreleased acceptance is explicit.
    if ! "$PHP" -r 'require $argv[1]."/vendor/autoload.php"; exit(method_exists(Tey\Mod\Scaffolds\Scaffold::class, "folder") ? 0 : 1);' "$APP"; then
        if [ "${MOD_REF:-}" = main ]; then
            record FAIL 'mod main must provide Scaffold::folder() for page shape'
        else
            printf 'SKIP | L%s frontend | page shape requires mod 0.7; dispatch mod_ref=main\n' "$MAJOR" | tee -a "$LOG"
        fi
        return
    fi
    APP=$WORK/page-shape-$MAJOR-$STACK
    for modal in modal no-modal; do
        test -f "$WORK/.mod-docs-harness"
        mkdir -p "$APP"
        # Copy real kit dependencies, not a mock app; keep the CRUD fixture intact.
        rsync -a --delete --exclude=.git "$baseline/" "$APP/"
        rm -rf "$APP/.git" "$APP/app/Modules/Inventory"
        mkdir -p "$APP/app/Modules/Inventory"
        check "$STACK/$modal: explicit parser fixture dependency" bash -c 'cd "$1" && npm install --save-dev --save-exact @babel/parser@7.29.9 --no-audit --no-fund' harness "$APP"
        check "$STACK/$modal: documented page-shape inputs" "$PHP" "$VERIFY/frontend/page-shape.php" prepare "$APP" "$STACK" "$MAJOR" "$modal" "$WORK"
        commands=$(doc_block 'Generate and Grow the Shape' bash)
        commands=${commands/--modal/--$modal}
        generate=${commands%%$'\n'*}; grow=${commands#*$'\n'}
        check "$STACK/$modal: generate pages" zsh_art "$generate"
        check "$STACK/$modal: exact generated tree and optional template block" "$PHP" "$VERIFY/frontend/page-shape.php" generated "$APP" "$STACK" "$MAJOR" "$modal" "$WORK"
        check "$STACK/$modal: grow History tab" zsh_art "$grow"
        check "$STACK/$modal: growth preserves pages and pageEntry refuses helpers" "$PHP" "$VERIFY/frontend/page-shape.php" grown "$APP" "$STACK" "$MAJOR" "$modal" "$WORK"
        check "$STACK/$modal: manual nearest-folder layout wiring" "$PHP" "$VERIFY/frontend/page-shape.php" wire "$APP" "$STACK" "$MAJOR" "$modal" "$WORK"
        git -C "$APP" init -q
        git -C "$APP" add -A
        git -C "$APP" -c user.name='Docs harness' -c user.email='harness@localhost' commit -qm 'Generate the documented page shape'
        commands=$(doc_block 'Rename the Shape Tree' bash)
        commands=${commands//--modal/--$modal}
        preview=${commands%%$'\n'*}
        commands=${commands#*$'\n'}; apply=${commands%%$'\n'*}
        check "$STACK/$modal: preview owned folder rename" zsh_art "$preview"
        cp "$WORK/check-output.txt" "$WORK/page-shape-$MAJOR-$STACK-$modal-preview.json"
        check "$STACK/$modal: unblocked preview moves the folder once" "$PHP" "$VERIFY/frontend/page-shape.php" preview "$APP" "$STACK" "$MAJOR" "$modal" "$WORK"
        check "$STACK/$modal: rename the resource" zsh_art "$apply"
        check "$STACK/$modal: npm run build" bash -c 'cd "$1" && npm run build' harness "$APP"
        check "$STACK/$modal: upstream kit input corrections" "$PHP" "$VERIFY/frontend/prepare-kit.php" "$APP" "$MAJOR" "$STACK" after
        if [ "$STACK" = vue ]; then
            check "$STACK/$modal: vue-tsc --noEmit" bash -c 'cd "$1" && npx vue-tsc --noEmit' harness "$APP"
        else
            check "$STACK/$modal: tsc --noEmit" bash -c 'cd "$1" && npx tsc --noEmit' harness "$APP"
        fi
        check "$STACK/$modal: partial bytes, render rewrites and manifest entries" "$PHP" "$VERIFY/frontend/page-shape.php" renamed "$APP" "$STACK" "$MAJOR" "$modal" "$WORK"
        check "$STACK/$modal: real folder layout and History render" node "$VERIFY/frontend/page-shape.mjs" "$APP" "$STACK"
        for uri in '' /create /history /overview; do
            case $uri in '') component=Index/Page;; /create) component=Create/Page;; /history) component=Edit/History/Page;; /overview) component=Edit/Overview/Page;; esac
            check "$STACK/$modal: GET /widgets$uri -> Inventory::Gadget/$component (200, direct and Inertia)" "$PHP" "$VERIFY/frontend/request.php" "$APP" "Inventory::Gadget/$component" --direct "/widgets$uri"
        done
        if [ "$modal" = modal ]; then
            check "$STACK/$modal: GET /widgets/create-modal -> Inventory::Gadget/Create/Modal (200, direct and Inertia)" "$PHP" "$VERIFY/frontend/request.php" "$APP" 'Inventory::Gadget/Create/Modal' --direct /widgets/create-modal
        fi
    done
    APP=$baseline
}

for STACK in vue react; do
    "$VERIFY/frontend/setup.sh" "$WORK" "$MAJOR" "$STACK"
    APP=$WORK/frontend-$MAJOR-$STACK
    check "$STACK: mod:install inertia" art mod:install inertia --no-interaction
    check "$STACK: mod:crud-pages Inventory:Widget" doc_shell 'Generating Pages With Their Controller'
    check "$STACK: migrate" art migrate --force
    check "$STACK: resolver runtime boundaries" node "$VERIFY/frontend/resolver.mjs" "$APP/vendor/tey/mod/resources/js/inertia.js"
    check "$STACK: custom-bootstrap instructions preserve the adapter" "$PHP" "$VERIFY/frontend/custom-bootstrap.php" "$APP" "$STACK"
    check "$STACK: qualified Inertia finders and documented Blade page entry" "$PHP" "$VERIFY/frontend/pages.php" "$APP" "$STACK"
    page_shape
    if [ "${MOD_DOCS_RENAME:-0}" = 1 ]; then continue; fi
    check "$STACK: npm run build" bash -c 'cd "$1" && npm run build' harness "$APP"
    check "$STACK: upstream kit input corrections" "$PHP" "$VERIFY/frontend/prepare-kit.php" "$APP" "$MAJOR" "$STACK" after
    if [ "$STACK" = vue ]; then
        check 'Vue: npx vue-tsc --noEmit' bash -c 'cd "$1" && npx vue-tsc --noEmit' harness "$APP"
        COMPONENT='Inventory::Widget/Index'
    else
        check 'React: npx tsc --noEmit' bash -c 'cd "$1" && npx tsc --noEmit' harness "$APP"
        COMPONENT='Inventory::widget/index'
    fi
    check "$STACK: GET /widgets renders $COMPONENT (200)" "$PHP" "$VERIFY/frontend/request.php" "$APP" "$COMPONENT" --direct
done
