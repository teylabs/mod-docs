# F16: compile and render the documented recipe in both real starter kits.
PAGE=$DOCS/docs/going-further/frontend.md
for STACK in vue react; do
    "$VERIFY/frontend/setup.sh" "$WORK" "$MAJOR" "$STACK"
    APP=$WORK/frontend-$MAJOR-$STACK
    check "$STACK: mod:install inertia" art mod:install inertia --no-interaction
    check "$STACK: mod:crud-pages Inventory:Widget" doc_shell 'Generating Pages With Their Controller'
    check "$STACK: migrate" art migrate --force
    check "$STACK: npm run build" bash -c 'cd "$1" && npm run build' harness "$APP"
    check "$STACK: upstream kit input corrections" "$PHP" "$VERIFY/frontend/prepare-kit.php" "$APP" "$MAJOR" "$STACK" after
    if [ "$STACK" = vue ]; then
        check 'Vue: npx vue-tsc --noEmit' bash -c 'cd "$1" && npx vue-tsc --noEmit' harness "$APP"
        COMPONENT='Inventory::Widget/Index'
    else
        check 'React: npx tsc --noEmit' bash -c 'cd "$1" && npx tsc --noEmit' harness "$APP"
        COMPONENT='Inventory::widget/index'
    fi
    check "$STACK: GET /widgets renders $COMPONENT (200)" "$PHP" "$VERIFY/frontend/request.php" "$APP" "$COMPONENT"
    check "$STACK: resolver runtime boundaries" node "$VERIFY/frontend/resolver.mjs" "$APP/vendor/tey/mod/resources/js/inertia.js"
done
