# Actual installed-package rename/build/runtime evidence, reusing the four kits.
run_rename_app() {
    if "$PHP" "$VERIFY/rename/run.php" "$APP" "$STACK" "$WORK" > "$WORK/application-$MAJOR-$STACK.log" 2>&1; then
        return 0
    else
        cat "$WORK/application-$MAJOR-$STACK.log"
        return 1
    fi
}
for STACK in vue react; do
    APP=$WORK/frontend-$MAJOR-$STACK
    test -f "$APP/vendor/tey/mod/resources/js/rename/helper.cjs"
    check "$STACK: explicit parser fixture dependency" bash -c 'cd "$1" && npm install --save-dev --save-exact @babel/parser@7.29.9 --no-audit --no-fund' harness "$APP"
    check "$STACK: prepare explicit rename recipe" "$PHP" "$VERIFY/rename/prepare.php" "$APP" "$STACK"
    if [ "$STACK" = vue ]; then
        sed "s#path.resolve(__dirname, '../../resources/js/rename/helper.cjs')#path.resolve(process.env.MOD_RENAME_TEST_APP, 'vendor/tey/mod/resources/js/rename/helper.cjs')#" "$WORK/mod-src/tests/Node/rename.test.cjs" > "$WORK/helper-$MAJOR.test.cjs"
        check 'installed helper parser/compilation suite' env MOD_RENAME_TEST_APP="$APP" node --test "$WORK/helper-$MAJOR.test.cjs"
    fi
    check "$STACK: installed-package rename scenarios" run_rename_app
done
