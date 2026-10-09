<?php

// Read examples without adding execution markers to the published pages.
// This is a selector and comparator; fixtures stay explicit in scenario scripts.
[$script, $mode, $page, $heading, $language, $index] = array_pad($argv, 6, '1');
$source = file_get_contents($page);
$lines = explode("\n", $source);
$blocks = [];
$active = $heading === '*';
$level = 0;
$fence = null;
$body = [];
foreach ($lines as $line) {
    if ($fence !== null) {
        if ($line === '```') {
            if ($active && $fence === $language) {
                $blocks[] = implode("\n", $body);
            }
            $fence = null;
            $body = [];
        } else {
            $body[] = $line;
        }
        continue;
    }
    if (preg_match('/^(#{1,6}) (.+)$/', $line, $match) && $heading !== '*') {
        if (strcasecmp($match[2], $heading) === 0) {
            $active = true;
            $level = strlen($match[1]);
        } elseif ($active && strlen($match[1]) <= $level) {
            $active = false;
        }
    }
    if (preg_match('/^```(\w+)(?: .*|)$/', $line, $match)) {
        $fence = $match[1];
    }
}
$block = $blocks[(int) $index - 1] ?? null;
if ($block === null) {
    fwrite(STDERR, "Missing $language example $index under '$heading' in $page\n");
    exit(1);
}
if ($mode === 'block') {
    echo $block, "\n";
    exit;
}
function normal(string $line): string
{
    // Only presentation differences: timestamp, elapsed time, dot leaders, spaces.
    $line = preg_replace('/\d{4}_\d{2}_\d{2}_\d{6}_/', 'TIMESTAMP_', $line);
    $line = preg_replace('/\b[\d.]+(?:ms|s)\b/', '', $line);
    $line = preg_replace('/\.{2,}/u', ' ', $line);
    return trim(preg_replace('/\s+/u', ' ', $line));
}
if ($mode === 'output') {
    $output = normal(file_get_contents($argv[6]));
    $app = $argv[7];
    $expectations = $language === 'bash'
        ? array_map(fn ($line) => preg_replace('/^# ->\s*/', '', $line), array_values(array_filter(explode("\n", $block), fn ($line) => str_starts_with($line, '# ->'))))
        : explode("\n", $block);
    foreach ($expectations as $expected) {
        $expected = trim($expected);
        if ($expected === '' || $expected === '...') {
            continue;
        }
        // Annotated paths describe the generated file, rather than full output.
        if (preg_match('~^((?:app|src|database|tests)/[^ ,]+)(?: \(created once\)|, from .+)?$~', $expected, $match)) {
            $files = glob($app.'/'.preg_replace('/\d{4}_\d{2}_\d{2}_\d{6}_/', '*_', $match[1]));
            if (count($files) !== 1) {
                fwrite(STDERR, "Expected documented file: {$match[1]}\n");
                exit(1);
            }
        } elseif (!str_contains($output, normal($expected))) {
            fwrite(STDERR, "Missing documented output: $expected\nActual output:\n".file_get_contents($argv[6]));
            exit(1);
        }
    }
    exit;
}
if ($mode === 'tree') {
    $app = $argv[6];
    $expected = [];
    $stack = [];
    $roots = [];
    foreach (explode("\n", $block) as $line) {
        if (preg_match('/^((?:(?:│   |    ))*)(?:├── |└── )(.+)$/u', $line, $match)) {
            $depth = mb_strlen($match[1]) / 4 + 1;
            $stack = array_slice($stack, 0, (int) $depth);
            $stack[] = rtrim($match[2], '/');
        } else {
            $stack = [rtrim($line, '/')];
            $roots[] = $stack[0];
        }
        if (str_ends_with($line, '.php')) {
            $expected[] = normal(implode('/', $stack));
        }
    }
    $actual = [];
    // Baseline files (User, Laravel's Controller, etc.) are already tracked.
    $process = proc_open(['git', '-C', $app, 'ls-files', '--others', '--exclude-standard'], [1 => ['pipe', 'w']], $pipes);
    $files = explode("\n", trim(stream_get_contents($pipes[1])));
    fclose($pipes[1]);
    if (proc_close($process) !== 0) {
        exit(1);
    }
    foreach ($files as $file) {
        foreach ($roots as $root) {
            if (str_starts_with($file, $root.'/') && str_ends_with($file, '.php')) {
                $actual[] = normal($file);
                break;
            }
        }
    }
    sort($actual);
    sort($expected);
    if ($actual !== $expected) {
        fwrite(STDERR, "Documented tree differs.\nMissing: ".implode(', ', array_diff($expected, $actual))."\nExtra: ".implode(', ', array_diff($actual, $expected))."\n");
        exit(1);
    }
    exit;
}
fwrite(STDERR, "Unknown docs helper mode: $mode\n");
exit(1);
