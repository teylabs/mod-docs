<?php

[$script, $native, $placed, $group, $folder] = $argv;
$namespace = 'App\\Modules\\'.str_replace('/', '\\', $group).'\\Mcp\\'.$folder;
$expected = str_replace('namespace App\\Mcp\\'.$folder.';', 'namespace '.$namespace.';', file_get_contents($native), $count);
if ($count !== 1 || file_get_contents($placed) !== $expected) {
    fwrite(STDERR, "Placed MCP class differs from native output beyond its namespace.\n");
    exit(1);
}
