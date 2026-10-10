<?php

use Illuminate\Contracts\Console\Kernel;
use Tey\Mod\Rename\Git\Transaction;
use Tey\Mod\Rename\Planner;
use Tey\Mod\Rename\Request;

[$script,$base,$phase] = $argv;
require $base.'/vendor/autoload.php';
$app = require $base.'/bootstrap/app.php';
$app->make(Kernel::class)->bootstrap();
$transaction = new Transaction($base, static function (string $at) use ($phase): void {
    if ($at !== $phase) {
        return;
    }
    $server = stream_socket_server('tcp://127.0.0.1:0');
    if (! $server) {
        throw new RuntimeException('Cannot open barrier');
    }
    fwrite(STDOUT, "BARRIER $at\n");
    fflush(STDOUT);
    if (! stream_socket_accept($server, 60)) {
        throw new RuntimeException('Barrier deadline expired');
    }
});
exit($transaction->execute(new Request('Inventory:Widget', 'Inventory:Gadget', 'crud-pages', yes: true), $app->make(Planner::class)->build(...), static function () {}, fn () => true));
