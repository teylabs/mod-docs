<?php
// Request the generated controller through Laravel's real HTTP kernel.
require $argv[1].'/vendor/autoload.php';
$app = require $argv[1].'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$uri = $argv[4] ?? '/widgets';
$request = Illuminate\Http\Request::create($uri, 'GET', server: ['HTTP_X_INERTIA' => 'true', 'HTTP_ACCEPT' => 'text/html, application/xhtml+xml']);
try {
    $kernel->bootstrap();
} catch (Throwable $error) {
    fwrite(STDERR, $error->getMessage().PHP_EOL);
    exit(1);
}
set_exception_handler(function (Throwable $error): never {
    fwrite(STDERR, $error->getMessage().PHP_EOL);
    exit(1);
});
$middleware = $app->make(App\Http\Middleware\HandleInertiaRequests::class);
$version = $middleware->version($request);
if ($version !== null) {
    $request->headers->set('X-Inertia-Version', $version);
}
$response = $kernel->handle($request);
if ($response->getStatusCode() !== 200) {
    fwrite(STDERR, 'HTTP '.$response->getStatusCode().PHP_EOL.substr($response->getContent(), 0, 1000));
    exit(1);
}
$payload = json_decode($response->getContent(), true, flags: JSON_THROW_ON_ERROR);
if (($payload['component'] ?? null) !== $argv[2]) {
    fwrite(STDERR, json_encode($payload));
    exit(1);
}
$kernel->terminate($request, $response);
echo '200 '.$payload['component'].PHP_EOL;

if (($argv[3] ?? null) !== '--direct') {
    exit(0);
}
// A direct full-page load must also resolve the module entry in Vite's manifest.
$direct = Illuminate\Http\Request::create($uri, 'GET', server: ['HTTP_ACCEPT' => 'text/html, application/xhtml+xml']);
$response = $kernel->handle($direct);
if ($response->getStatusCode() !== 200 || ! str_contains($response->getContent(), 'data-page=')) {
    fwrite(STDERR, 'Direct HTTP '.$response->getStatusCode().PHP_EOL.substr($response->getContent(), 0, 1000));
    exit(1);
}
preg_match('/data-page=([\x22\x27])(.*?)\1/s', $response->getContent(), $matches);
$payload = json_decode(html_entity_decode($matches[2], ENT_QUOTES | ENT_HTML5, 'UTF-8'), true, flags: JSON_THROW_ON_ERROR);
if (($payload['component'] ?? null) !== $argv[2]) {
    fwrite(STDERR, 'Direct component: '.json_encode($payload));
    exit(1);
}
$kernel->terminate($direct, $response);
echo '200 direct '.$payload['component'].PHP_EOL;
