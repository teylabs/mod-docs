<?php

[$script,$app,$stack] = $argv;
require $app.'/vendor/autoload.php';
$provider = $app.'/app/Providers/AppServiceProvider.php';
$s = file_get_contents($provider);
$old = "->makes('model', options: ['--migration', '--factory'])";
if (substr_count($s, $old) !== 1) {
    throw new RuntimeException('Expected the documented native generation recipe');
}
$s = str_replace($old, "->makes('model', as: 'model')\n    ->makes('factory', name: '{name}Factory', as: 'factory')", $s);
file_put_contents($provider, $s);
mkdir($app.'/app/Modules/Catalog', 0777, true);
file_put_contents($app.'/app/Modules/Catalog/.gitkeep', '');
foreach (['Inventory', 'Catalog'] as $group) {
    if (! is_dir($app.'/app/Modules/'.$group.'/Models')) {
        mkdir($app.'/app/Modules/'.$group.'/Models', 0777, true);
    }
    file_put_contents($app.'/app/Modules/'.$group.'/Models/ExistingItem.php', '<?php namespace App\\Modules\\'.$group.'\\Models; class ExistingItem extends \\Illuminate\\Database\\Eloquent\\Model {}');
}
$vue = $stack === 'vue';
$dir = $vue ? 'Widget' : 'widget';
$ext = $vue ? 'vue' : 'tsx';
$index = $vue ? 'Index' : 'index';
$root = 'app/Modules/Inventory/resources/js';
mkdir($app.'/'.$root.'/components', 0777, true);
$near = $root.'/components/'.($vue ? 'Neighbour.vue' : 'neighbour.tsx');
file_put_contents($app.'/'.$near, $vue ? '<template><p>Neighbour preserved</p></template>' : "export default function Neighbour(){return <p>Neighbour preserved</p>;}\n");
$page = $root.'/pages/'.$dir.'/'.$index.'.'.$ext;
$s = file_get_contents($app.'/'.$page);
$import = "import Show from '@modules/Inventory/resources/js/pages/$dir/".($vue ? 'Show' : 'show').".$ext';\nimport Neighbour from '../../components/".basename($near)."';\n";
$s = $vue ? str_replace('<script setup lang="ts">', "<script setup lang=\"ts\">\n".$import, $s) : $import.$s;
$s = $vue ? str_replace('<ul>', "<Show />\n    <Neighbour />\n    <ul>", $s) : str_replace('<ul>', "<Show />\n        <Neighbour />\n        <ul>", $s);
file_put_contents($app.'/'.$page, $s);
file_put_contents($app.'/resources/js/rename-consumer.ts', "import Index from '@modules/Inventory/resources/js/pages/$dir/$index.$ext';\nexport { Index };\n");
if (! $vue) {
    foreach ([$app.'/'.$page, $app.'/resources/js/rename-consumer.ts'] as $file) {
        file_put_contents($file, str_replace(".tsx'", "'", file_get_contents($file)));
    }
}
// Keep the baseline query usable across class renames; table inference gets its own fixture.
$model = $app.'/app/Modules/Inventory/Models/Widget.php';
$s = file_get_contents($model);
$s = preg_replace('/(class Widget extends Model\s*\{)/', '$1'."\n    protected \$table = 'widgets';", $s);
file_put_contents($model,$s);

require __DIR__.'/clock.php';
