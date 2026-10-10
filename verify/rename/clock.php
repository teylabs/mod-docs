<?php

// Acceptance clock: no writer may be called while selecting a migration candidate.
$app = $argv[1];
$file = $app.'/app/Providers/AppServiceProvider.php';
$s = file_get_contents($file);
$clock = <<<'CODE'
$this->app->booted(function () {
$this->app->make('migration.creator');
$this->app->instance('migration.creator', new class($this->app['files'], $this->app->basePath('stubs')) extends \Tey\Mod\Generation\ModMigrationCreator {
    public function datePrefixFor(string $directory): string { return '2026_10_09_163000'; }
    public function create($name, $path, $table = null, $create = false) { throw new \LogicException('Rename must never call a migration writer.'); }
});
$this->app->make(\Tey\Mod\Rename\Contributors::class)->set('tables', $this->app->make(\Tey\Mod\Rename\Tables\Contributor::class));
});
CODE;
$s = str_replace('public function boot(): void {', 'public function boot(): void {'."\n".$clock, $s);
file_put_contents($file, $s);
