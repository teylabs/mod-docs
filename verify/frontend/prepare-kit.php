<?php
// Small, guarded corrections to pinned upstream kit inputs, before Mod runs.
[$script, $app, $major, $stack, $phase] = array_pad($argv, 5, 'before');
if ($major === '12' && $stack === 'vue' && $phase === 'before') {
    $file = $app.'/resources/js/components/TwoFactorSetupModal.vue';
    $source = file_get_contents($file);
    $pattern = '/errors\?\.confirmTwoFactorAuthentication\s*\?\.code/';
    $fixed = preg_replace($pattern, 'errors.code', $source, -1, $count);
    if ($count !== 1) {
        throw new RuntimeException('Pinned Vue validation-error expression changed.');
    }
    file_put_contents($file, $fixed);
}
if ($major === '13' && $phase === 'after') {
    // Laravel now includes QUERY in RedirectController's any-route methods.
    $file = $app.'/resources/js/wayfinder/index.ts';
    $source = file_get_contents($file);
    $old = '"get"|"post"|"put"|"delete"|"patch"|"head"|"options"';
    $fixed = $old.'|"query"';
    if (preg_match_all('/\btype Method\s*=\s*([^;]+);/', $source, $matches) !== 1) {
        throw new RuntimeException('Pinned Wayfinder Method definition changed.');
    }
    $definition = preg_replace('/\s+/', '', $matches[1][0]);
    if ($definition === $old) {
        $replacement = substr($matches[0][0], 0, -1).' | "query";';
        file_put_contents($file, str_replace($matches[0][0], $replacement, $source));
    } elseif ($definition !== $fixed) {
        throw new RuntimeException('Pinned Wayfinder Method definition changed.');
    }
}
