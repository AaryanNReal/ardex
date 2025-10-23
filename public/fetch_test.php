<?php
$url = 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=500&d=identicon';
echo "URL: $url\n\n";

// Try cURL
if (function_exists('curl_version')) {
    echo "cURL: available\n";
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    $r = curl_exec($ch);
    $err = curl_error($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    echo "HTTP code: $code\n";
    echo "cURL error: " . ($err ?: 'none') . "\n";
    echo "Bytes returned (cURL): " . strlen($r) . "\n\n";
} else {
    echo "cURL: not available\n\n";
}

// Try file_get_contents
$ctx = stream_context_create(['http' => ['timeout' => 10], 'ssl' => ['verify_peer' => true, 'verify_peer_name' => true]]);
$r2 = @file_get_contents($url, false, $ctx);
echo "file_get_contents returned bytes: " . ($r2 === false ? 'false' : strlen($r2)) . "\n";
