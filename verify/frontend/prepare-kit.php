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
    $old = '"patch" | "head" | "options";';
    if (substr_count($source, $old) !== 1) {
        throw new RuntimeException('Pinned Wayfinder Method definition changed.');
    }
    file_put_contents($file, str_replace($old, '"patch" | "head" | "options" | "query";', $source));
}
