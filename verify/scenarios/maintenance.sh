# Checks docs/going-further/maintenance.md.
PAGE=$DOCS/docs/going-further/maintenance.md

# The page's update script, run in a disposable app. Maintenance is POSIX-only.
setup_maintenance() {
    doc_file 'Registering Checks' maintenance/checks.php
    doc_block 'Registering Checks' json > "$APP/maintenance/policy.json"
    doc_file 'A Complete Update' update.php
}
# The script up to (not including) its first apply, then the artifacts' plan.
maintenance_prelude() { sed '/^\$result = Maintenance::apply/,$d' "$APP/update.php"; }
# Examples add their own imports; a second `use` of the same class is an error.
maintenance_example() { doc_block "$1" php "${2:-1}" | grep -v '^use .*;$'; }

fresh 'maintenance: install, update, repeat' modules
check 'The checks, policy and script are valid PHP' setup_maintenance
check 'The script installs, updates and repeats as documented' doc_shell 'A Complete Update'
check 'The update wrote version 2 of the file' grep -F "Hello, world" "$APP/app/Acme/Greeting.php"
check 'Mod keeps its records in .mod-maintenance' test -d "$APP/.mod-maintenance"

fresh 'maintenance: an edited file is a conflict' modules
setup_maintenance
art_run() { (cd "$APP" && "$PHP" "$@" 2>&1); }
art_run update.php > /dev/null
{ maintenance_prelude; echo; maintenance_example 'Reading a Plan'; } > "$APP/conflict.php"
check 'The conflict example runs' sh -c "cd '$APP' && '$PHP' conflict.php > '$WORK/doc-output.txt'"
check 'The conflict output matches the page' doc_output 'Reading a Plan' 1
check 'An edited file is left as the developer wrote it' grep -F 'My own version' "$APP/app/Acme/Greeting.php"

fresh 'maintenance: diagnose' modules
setup_maintenance
{ maintenance_prelude; echo; maintenance_example 'When an Update Stops Part-way' 1; echo 'echo json_encode($report), "\n";'; } > "$APP/diagnose.php"
check 'diagnose reads a plan that has not run' sh -c "cd '$APP' && '$PHP' diagnose.php | grep -F '\"current\":true,\"executable\":true,\"orphans\":[]'"

fresh 'maintenance: a failed check, then resume' modules
setup_maintenance
mv "$APP/bootstrap/app.php" "$APP/bootstrap/app.php.away"
{ maintenance_prelude; echo '$plan = Checkout::inspect($root, "my-app", $empty, $v1, $inputs, ["php" => "passed"]);'; echo '$r = Maintenance::apply($plan, $inputs, "install-1.0.0", $checks, exclusiveCheckout: true); echo "install: {$r["status"]}\n";'; } > "$APP/fail.php"
check 'A failing check ends in verification_failed' sh -c "cd '$APP' && '$PHP' fail.php | grep -Fx 'install: verification_failed'"
check 'The installed version is not recorded' fails test -e "$APP/.mod-maintenance/installed.json"
mv "$APP/bootstrap/app.php.away" "$APP/bootstrap/app.php"
{ maintenance_prelude; maintenance_example 'When an Update Stops Part-way' 2; } > "$APP/resume.php"
check 'resume finishes the same intent' sh -c "cd '$APP' && '$PHP' resume.php > '$WORK/doc-output.txt'"
check 'The resume output matches the page' doc_output 'When an Update Stops Part-way' 1
check 'The installed version is recorded after the checks pass' test -e "$APP/.mod-maintenance/installed.json"
