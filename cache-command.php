<?php

if ( ! class_exists( 'WP_CLI' ) ) {
	return;
}

$fincli_cache_autoloader = __DIR__ . '/vendor/autoload.php';
if ( file_exists( $fincli_cache_autoloader ) ) {
	require_once $fincli_cache_autoloader;
}

WP_CLI::add_command( 'cache', 'Cache_Command' );
WP_CLI::add_command( 'transient', 'Transient_Command' );
