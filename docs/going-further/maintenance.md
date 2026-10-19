# Keeping Generated Files Up to Date

A package or recipe that generates files into an app will ship a newer version one day. `Tey\Mod\Maintenance` updates the app's copies without overwriting the edits you made to them.

> **Experimental.** This API arrived in Mod 0.8, with lineages and claims added in Mod 0.9, and may change before 1.0. It works on POSIX checkouts (macOS and Linux). Windows roots are refused, although Mod's generators still work on Windows.

It is for people building a package, recipe or installer on Mod. If you only use generators, you don't need it.

## How an Update Decides

Mod compares three versions of every generated file:

- **original**: what was installed last time
- **current**: what is in the checkout now
- **target**: what the new release generates

A file that still matches its original is replaced. A file you edited is a conflict, and a conflict stops the whole update before anything is written. Mod never merges and has no force option.

Mod handles whole files only. Migrations, providers and other side effects stay with the package that calls it.

## Describing What You Generate

An `Artifact` describes one version of a recipe's output: a name and version, the exact relative paths with their bytes, the selected groups (for example a vertical unit such as `Billing`), host bindings, and the IDs of the checks that must pass after installing it.

```php
use Tey\Mod\Maintenance\Artifact;

$v2 = new Artifact(
    name: 'acme/greeting',
    version: '2.0.0',
    files: ['app/Acme/Greeting.php' => $bytes],
    groups: ['core'],
    bindings: ['namespace' => 'App\Acme'],
    checks: ['boots'],
    metadata: ['source' => 'acme/greeting@2.0.0'],
);
```

An artifact can't change once built, and its identity comes from its content. Mod keeps the original bytes of what it installed, so an update is always compared with exactly what you shipped before. Build artifacts from your own recipe's output, never from JSON a developer can edit.

`metadata` is optional provenance such as a source reference or the package constraint. It must be plain JSON data, nested no deeper than 16 levels and no larger than 1 MiB. Mod records it and never acts on it: it can't add files, skip checks or run anything.

## Registering Checks

A check proves the new files work. Each check ID an artifact names needs a closure that returns `true` on success. Keep them in the checkout, in a file of their own:

```php memo="maintenance/checks.php"
<?php

return [
    'boots' => fn (): bool => is_file(__DIR__.'/../bootstrap/app.php')
        && str_contains(
            (string) file_get_contents(__DIR__.'/../app/Acme/Greeting.php'),
            'class Greeting',
        ),
];
```

Checks are closures your code supplies. A command string is refused. Alongside them, Mod needs two files that describe your check registry, so that changing a check invalidates an earlier result. The policy lists the check IDs:

```json memo="maintenance/policy.json"
{"checks": ["boots"]}
```

## A Complete Update

This script installs version 1, updates to version 2, and repeats the update to show it is safe to run twice. Run it from the app's root:

```php memo="update.php"
<?php

use Tey\Mod\Maintenance\Artifact;
use Tey\Mod\Maintenance\Checkout;
use Tey\Mod\Maintenance\Maintenance;

require __DIR__.'/vendor/autoload.php';

$root = realpath(__DIR__);
$checks = require $root.'/maintenance/checks.php';
$inputs = [
    'verification-policy' => 'maintenance/policy.json',
    'verification-code' => 'maintenance/checks.php',
    'lock' => 'composer.lock',
];

$empty = new Artifact('acme/greeting', '0.0.0', [], ['core'], ['namespace' => 'App\Acme'], ['boots']);
$v1 = new Artifact('acme/greeting', '1.0.0', [
    'app/Acme/Greeting.php' => "<?php\n\nnamespace App\Acme;\n\nclass Greeting\n{\n    public function __invoke(): string\n    {\n        return 'Hello';\n    }\n}\n",
], ['core'], ['namespace' => 'App\Acme'], ['boots']);
$v2 = new Artifact('acme/greeting', '2.0.0', [
    'app/Acme/Greeting.php' => "<?php\n\nnamespace App\Acme;\n\nclass Greeting\n{\n    public function __invoke(): string\n    {\n        return 'Hello, world';\n    }\n}\n",
], ['core'], ['namespace' => 'App\Acme'], ['boots']);

$plan = Checkout::inspect($root, 'my-app', $empty, $v1, $inputs, ['php' => 'passed']);
$result = Maintenance::apply($plan, $inputs, 'install-1.0.0', $checks, exclusiveCheckout: true);
echo "install: {$result['status']}\n";

$plan = Checkout::inspect($root, 'my-app', $v1, $v2, $inputs, ['php' => 'passed']);
$result = Maintenance::apply($plan, $inputs, 'update-2.0.0', $checks, exclusiveCheckout: true);
echo "update: {$result['status']} (wrote ".implode(', ', $result['written']).")\n";

$result = Maintenance::apply($plan, $inputs, 'update-2.0.0', $checks, exclusiveCheckout: true);
echo 'again: '.($result['no_op'] ? 'nothing to do' : 'ran again')."\n";
```

```bash
php update.php
# -> install: completed
# -> update: completed (wrote app/Acme/Greeting.php)
# -> again: nothing to do
```

Here is what each argument does:

- `Checkout::inspect()` reads the files both artifacts name, plus the host inputs you list (such as `composer.lock`), and returns a plan. It writes nothing. The last argument is the result of your own compatibility checks, here that PHP is fine. Anything other than `passed` makes the plan unable to run.
- The `intent` names the update. Retrying the same intent is safe: a finished update returns the same result without writing, and a different plan under the same intent is refused.
- `verification-policy` and `verification-code` are required inputs. They stand for your check registry.
- `exclusiveCheckout: true` is your promise that nothing else edits the checkout during the update. Mod takes a lock against other Mod updates, but it can't stop an editor or another tool.
- Checks run after the files are written. Every check ID in the target artifact needs a closure, and a closure for an ID the artifact doesn't name is refused, before any file is written.

Only a status of `completed` means success. A refused update throws instead.

## Reading a Plan

Each file in a plan has a state:

| State | Meaning |
| --- | --- |
| unchanged | Current matches original and target |
| replace | Current matches original, and the target changed |
| restore | A file Mod owns is missing |
| create | A new target file, and nothing is there yet |
| conflict | Current differs from original, even if it equals the target |
| unowned | A new target path collides with a file that isn't Mod's |
| claim | A new target path you listed already holds the target's exact bytes (see [Claiming Files That Already Exist](#claiming-files-that-already-exist)) |

Files the artifacts don't name are never touched and never become owned. The inspector refuses symlinked roots and parents, case aliases, and directories where files are expected.

Edit a generated file, then plan another update:

```php
use Tey\Mod\Maintenance\Artifact;
use Tey\Mod\Maintenance\Checkout;

file_put_contents($root.'/app/Acme/Greeting.php', "<?php\n\n// My own version\n");

$v3 = new Artifact('acme/greeting', '3.0.0', [
    'app/Acme/Greeting.php' => "<?php\n\nnamespace App\Acme;\n\nclass Greeting {}\n",
], ['core'], ['namespace' => 'App\Acme'], ['boots']);

$plan = Checkout::inspect($root, 'my-app', $v2, $v3, $inputs, ['php' => 'passed']);

echo $plan->files['app/Acme/Greeting.php']['state']."\n";
echo $plan->executable() ? "can run\n" : "cannot run\n";
```

```text
conflict
cannot run
```

The edited file is a conflict even if it already equals the target, because Mod can't tell your edit from the new release. Nothing is written until you resolve it.

## When an Update Stops Part-way

`Maintenance::diagnose()` reads the checkout and says whether a plan is still current and able to run:

```php
use Tey\Mod\Maintenance\Maintenance;

$report = Maintenance::diagnose($plan, $inputs);
// ['plan' => ..., 'current' => true, 'executable' => true, 'orphans' => [], 'claimable' => []]
```

If a check fails, the status is `verification_failed` and the installed version stays where it was. Fix the cause, then finish the same intent with `resume()`, passing the same trusted artifacts:

```php
use Tey\Mod\Maintenance\Maintenance;

$checks = require $root.'/maintenance/checks.php';

$result = Maintenance::resume(
    $root, 'my-app', $empty, $v1, $inputs, ['php' => 'passed'],
    'install-1.0.0', $checks, exclusiveCheckout: true,
);

echo "install: {$result['status']}\n";
```

```text
install: completed
```

Mod records the new installed version last, after every check has passed. If a process stops part-way, running `apply` or `resume` again either finishes the update or reports exactly what is left. Edited, stale, foreign or unsafe state throws instead.

Temporary files left by an interrupted run are reported as `orphaned` and left in place for you to inspect. Mod never cleans them up or adopts them, and an update does not complete while any remain.

## Several Lineages in One Checkout

An app can take more than one generated unit, such as a base feature and an add-on built on it. Each one is a **lineage**: one generated unit, installed and updated on its own. The artifact's name is the lineage's name, so `acme/greeting:farewell` and `acme/greeting` are two lineages in one checkout. Mod keeps a separate record for each.

An artifact can say what it builds on with `requires`: the lineages that must already be installed, each at an exact version or `'*'` for any version. This script adds a base lineage and an add-on that needs it. It uses the checks and policy files from earlier, and it asks for the add-on first to show the refusal:

```php memo="lineages.php"
<?php

use Tey\Mod\Maintenance\Artifact;
use Tey\Mod\Maintenance\Checkout;
use Tey\Mod\Maintenance\Maintenance;

require __DIR__.'/vendor/autoload.php';

$root = realpath(__DIR__);
$checks = require $root.'/maintenance/checks.php';
$inputs = [
    'verification-policy' => 'maintenance/policy.json',
    'verification-code' => 'maintenance/checks.php',
    'lock' => 'composer.lock',
];
$none = fn (Artifact $a) => new Artifact($a->name, '0.0.0', [], $a->groups, $a->bindings, $a->checks);

$greeting = new Artifact('acme/greeting', '1.0.0', [
    'app/Acme/Greeting.php' => "<?php\n\nnamespace App\Acme;\n\nclass Greeting {}\n",
], ['core'], ['namespace' => 'App\Acme'], ['boots']);
$farewell = new Artifact('acme/greeting:farewell', '1.0.0', [
    'app/Acme/Farewell.php' => "<?php\n\nnamespace App\Acme;\n\nclass Farewell {}\n",
], ['core'], ['namespace' => 'App\Acme'], ['boots'], requires: ['acme/greeting' => '1.0.0']);

try {
    Checkout::inspect($root, 'my-app', $none($farewell), $farewell, $inputs, ['php' => 'passed']);
} catch (RuntimeException $e) {
    echo 'farewell first: refused ('.$e->getMessage().")\n";
}

foreach ([$greeting, $farewell] as $artifact) {
    $plan = Checkout::inspect($root, 'my-app', $none($artifact), $artifact, $inputs, ['php' => 'passed']);
    $result = Maintenance::apply($plan, $inputs, 'install-'.$artifact->name, $checks, exclusiveCheckout: true);
    echo "{$artifact->name}: {$result['status']}\n";
}

echo 'installed: '.implode(', ', array_keys(Checkout::installed($root, 'my-app')))."\n";
```

```bash
php lineages.php
# -> farewell first: refused (Required lineage acme/greeting is not installed at version 1.0.0.)
# -> acme/greeting: completed
# -> acme/greeting:farewell: completed
# -> installed: acme/greeting, acme/greeting:farewell
```

`Checkout::installed()` lists what the checkout holds, one entry per lineage. It reads only.

Lineages never share files. When a lineage's target path belongs to another installed lineage, the plan entry is a `conflict` with the reason `owned_by:<name>`, and ownership never moves between them.

### Updating a Lineage Another One Requires

A requirement on an exact version holds that lineage in place. Updating `acme/greeting` while `acme/greeting:farewell` needs version 1.0.0 is refused, with the reason `required_by:acme/greeting:farewell`. Update the add-on first, so that its requirement names the new version:

```php
$greeting2 = new Artifact('acme/greeting', '2.0.0', $greeting->files, ['core'], ['namespace' => 'App\Acme'], ['boots']);

try {
    Checkout::inspect($root, 'my-app', $greeting, $greeting2, $inputs, ['php' => 'passed']);
} catch (RuntimeException $e) {
    echo $e->getMessage()."\n";
}
```

```text
Lineage acme/greeting must stay at version 1.0.0 (required_by:acme/greeting:farewell).
```

A requirement of `'*'` accepts any version and never blocks an update. Mod doesn't read version ranges. If you need `^1.2`, check it yourself and pass the outcome in as the compatibility result of `Checkout::inspect()`.

### Paths That Belong to the App

An artifact can list `hostOwned` path prefixes, the places it leaves to the developer:

```php
$billing = new Artifact(
    name: 'acme/greeting:billing',
    version: '1.0.0',
    files: ['app/Acme/Billing.php' => $bytes],
    groups: [],
    bindings: [],
    checks: ['boots'],
    hostOwned: ['config/branding.php', 'app/Domain'],
);
```

`app/Domain` covers that folder and everything under it. No lineage may own, write or claim a path there. A target file that lands in one is a `conflict` with the reason `host_owned:<name>`. Several lineages may name the same prefix, and Mod only compares the paths and never reads them. It also refuses to install a lineage whose prefixes cover a file another lineage already owns.

### When One Lineage Is Unfinished

One unfinished update blocks the others. If a lineage's checks failed and you haven't resumed it, Mod refuses to inspect, apply, resume or claim for any other lineage, with the reason `pending:<name>`. The unfinished lineage can still resume. Finish it with `Maintenance::resume()` and then carry on with the rest.

A checkout written by Mod 0.8 keeps working. Mod reads its record as the record for its own lineage and moves it to the new layout the next time that lineage updates.

## Claiming Files That Already Exist

Sometimes an app already holds files a recipe would generate, for example when it adopts a recipe it once copied by hand. Normally those paths are `unowned`, and the update won't run. To bring such a file under Mod, list the paths you have reviewed as `claim`.

`Maintenance::diagnose()` helps you find them. Its `claimable` entry lists the unowned paths whose bytes already equal the target. This script sets up a hand-copied checkout and walks through it:

```php memo="claim.php"
<?php

use Tey\Mod\Maintenance\Artifact;
use Tey\Mod\Maintenance\Checkout;
use Tey\Mod\Maintenance\Maintenance;

require __DIR__.'/vendor/autoload.php';

$root = realpath(__DIR__);
$checks = require $root.'/maintenance/checks.php';
$inputs = [
    'verification-policy' => 'maintenance/policy.json',
    'verification-code' => 'maintenance/checks.php',
    'lock' => 'composer.lock',
];

$greeting = "<?php\n\nnamespace App\Acme;\n\nclass Greeting {}\n";
$target = new Artifact('acme/greeting', '1.0.0', [
    'app/Acme/Greeting.php' => $greeting,
    'app/Acme/Formal.php' => "<?php\n\nnamespace App\Acme;\n\nclass Formal {}\n",
    'app/Acme/Wave.php' => "<?php\n\nnamespace App\Acme;\n\nclass Wave {}\n",
], ['core'], ['namespace' => 'App\Acme'], ['boots']);
$none = new Artifact('acme/greeting', '0.0.0', [], ['core'], ['namespace' => 'App\Acme'], ['boots']);

// Two files copied by hand earlier: one identical, one edited since.
mkdir($root.'/app/Acme', 0777, true);
file_put_contents($root.'/app/Acme/Greeting.php', $greeting);
file_put_contents($root.'/app/Acme/Formal.php', "<?php\n\n// My own formal greeting\n");

$show = function ($plan) {
    foreach ($plan->files as $path => $file) {
        echo "{$file['state']} {$path}\n";
    }
    echo $plan->executable() ? "can run\n" : "cannot run\n";
};

$plan = Checkout::inspect($root, 'my-app', $none, $target, $inputs, ['php' => 'passed']);
$show($plan);
echo 'claimable: '.implode(', ', Maintenance::diagnose($plan, $inputs)['claimable'])."\n";

$claim = ['app/Acme/Greeting.php', 'app/Acme/Formal.php'];
$show(Checkout::inspect($root, 'my-app', $none, $target, $inputs, ['php' => 'passed'], claim: $claim));

rename($root.'/app/Acme/Formal.php', $root.'/app/Acme/Formal.php.mine');
$plan = Checkout::inspect($root, 'my-app', $none, $target, $inputs, ['php' => 'passed'], claim: ['app/Acme/Greeting.php']);
$show($plan);

$result = Maintenance::apply($plan, $inputs, 'adopt-1.0.0', $checks, exclusiveCheckout: true);
echo "install: {$result['status']} (wrote ".implode(', ', $result['written']).'; kept '.implode(', ', $result['reconciled']).")\n";
```

```bash
php claim.php
# -> unowned app/Acme/Greeting.php
# -> unowned app/Acme/Formal.php
# -> create app/Acme/Wave.php
# -> cannot run
# -> claimable: app/Acme/Greeting.php
# -> claim app/Acme/Greeting.php
# -> conflict app/Acme/Formal.php
# -> claim app/Acme/Greeting.php
# -> create app/Acme/Formal.php
# -> can run
# -> install: completed (wrote app/Acme/Formal.php, app/Acme/Wave.php; kept app/Acme/Greeting.php)
```

A claim never overwrites anything:

- A claimed path whose bytes equal the target is a `claim`. Mod doesn't touch the file. After the update it is owned like any generated file.
- A claimed path whose bytes differ is a `conflict`. Here, `Formal.php` stays as you wrote it, and the plan can't run until you move your version aside or drop it from the claim.
- A path that exists but isn't in your list stays `unowned`.

To resume an interrupted update, pass the same `claim` list to `Maintenance::resume()`.

## Limits

- Experimental, and POSIX checkouts only.
- Whole-file replacement. There is no merging and no force option.
- One Mod writer per checkout. Other editors aren't kept out.
- It covers a process being interrupted, not a power loss.
- Mod never cleans up or adopts orphaned files.
- One unfinished update blocks every other lineage until you resume it.
- There is no way to remove an installed lineage yet, and no atomic update across several lineages: each is applied on its own.
