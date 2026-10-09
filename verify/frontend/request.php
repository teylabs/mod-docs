<?php
// Request the generated controller through Laravel's real HTTP kernel.
require $argv[1].'/vendor/autoload.php';
$app = require $argv[1].'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$request = Illuminate\Http\Request::create('/widgets', 'GET', server: ['HTTP_X_INERTIA' => 'true', 'HTTP_ACCEPT' => 'text/html, application/xhtml+xml']);
$response = $kernel->handle($request);
if ($response->getStatusCode() !== 200) {
    fwrite(STDERR, $response->getContent());
    exit(1);
}
$payload = json_decode($response->getContent(), true, flags: JSON_THROW_ON_ERROR);
if (($payload['component'] ?? null) !== $argv[2]) {
    fwrite(STDERR, json_encode($payload));
    exit(1);
}
$kernel->terminate($request, $response);
echo '200 '.$payload['component'].PHP_EOL;
