<?php

use WP_CLI\Traverser\RecursiveDataStructureTraverser;
use WP_CLI\Utils;

/**
 * Adds, removes, fetches, and flushes the WP Object Cache object.
 *
 * By default, the WP Object Cache exists in PHP memory for the length of the
 * request (and is emptied at the end). Use a persistent object cache drop-in
 * to persist the object cache between requests.
 *
 * [Read the codex article](https://codex.finpress.org/Class_Reference/WP_Object_Cache)
 * for more detail.
 *
 * ## EXAMPLES
 *
 *     # Set cache.
 *     $ fin cache set my_key my_value my_group 300
 *     Success: Set object 'my_key' in group 'my_group'.
 *
 *     # Get cache.
 *     $ fin cache get my_key my_group
 *     my_value
 *
 * @package fin-cli
 */
class Cache_Command extends WP_CLI_Command {

	/**
	 * Adds a value to the object cache.
	 *
	 * Errors if a value already exists for the key, which means the value can't
	 * be added.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * <value>
	 * : Value to add to the key.
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * [<expiration>]
	 * : Define how long to keep the value, in seconds. `0` means as long as possible.
	 * ---
	 * default: 0
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Add cache.
	 *     $ fin cache add my_key my_group my_value 300
	 *     Success: Added object 'my_key' in group 'my_value'.
	 *
	 * @param array{string, string, string, string} $args       Positional arguments.
	 * @param array<mixed>                          $assoc_args Associative arguments.
	 */
	public function add( $args, $assoc_args ) {
		list( $key, $value, $group, $expiration ) = $args;

		if ( ! fin_cache_add( $key, $value, $group, (int) $expiration ) ) {
			WP_CLI::error( "Could not add object '$key' in group '$group'. Does it already exist?" );
		}

		WP_CLI::success( "Added object '$key' in group '$group'." );
	}

	/**
	 * Decrements a value in the object cache.
	 *
	 * Errors if the value can't be decremented.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * [<offset>]
	 * : The amount by which to decrement the item's value.
	 * ---
	 * default: 1
	 * ---
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Decrease cache value.
	 *     $ fin cache decr my_key 2 my_group
	 *     48
	 *
	 * @param array{string, string, string} $args       Positional arguments.
	 * @param array<mixed>                  $assoc_args Associative arguments.
	 */
	public function decr( $args, $assoc_args ) {
		list( $key, $offset, $group ) = $args;
		$value = fin_cache_decr( $key, (int) $offset, $group );

		if ( false === $value ) {
			WP_CLI::error( 'The value was not decremented.' );
		}

		WP_CLI::print_value( $value, $assoc_args );
	}

	/**
	 * Removes a value from the object cache.
	 *
	 * Errors if the value can't be deleted.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Delete cache.
	 *     $ fin cache delete my_key my_group
	 *     Success: Object deleted.
	 *
	 * @param array{string, string} $args       Positional arguments.
	 * @param array<mixed>          $assoc_args Associative arguments.
	 */
	public function delete( $args, $assoc_args ) {
		list( $key, $group ) = $args;
		$result              = fin_cache_delete( $key, $group );

		if ( false === $result ) {
			WP_CLI::error( 'The object was not deleted.' );
		}

		WP_CLI::success( 'Object deleted.' );
	}

	/**
	 * Flushes the object cache.
	 *
	 * For FinPress multisite instances using a persistent object cache,
	 * flushing the object cache will typically flush the cache for all sites.
	 * Beware of the performance impact when flushing the object cache in
	 * production.
	 *
	 * Errors if the object cache can't be flushed.
	 *
	 * ## EXAMPLES
	 *
	 *     # Flush cache.
	 *     $ fin cache flush
	 *     Success: The cache was flushed.
	 */
	public function flush() {
		// TODO: Needs fixing in fin-cli/fin-cli
		// @phpstan-ignore offsetAccess.nonOffsetAccessible
		if ( WP_CLI::has_config( 'url' ) && ! empty( WP_CLI::get_config()['url'] ) && is_multisite() ) {
			WP_CLI::warning( 'Flushing the cache may affect all sites in a multisite installation, depending on the implementation of the object cache.' );
		}

		$value = fin_cache_flush();
		if ( false === $value ) {
			WP_CLI::error( 'The object cache could not be flushed.' );
		}

		WP_CLI::success( 'The cache was flushed.' );
	}

	/**
	 * Gets a value from the object cache.
	 *
	 * Errors if the value doesn't exist.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Get cache.
	 *     $ fin cache get my_key my_group
	 *     my_value
	 *
	 * @param array{string, string} $args       Positional arguments.
	 * @param array<mixed>          $assoc_args Associative arguments.
	 */
	public function get( $args, $assoc_args ) {
		list( $key, $group ) = $args;
		$value               = fin_cache_get( $key, $group );

		if ( false === $value ) {
			WP_CLI::error( "Object with key '$key' and group '$group' not found." );
		}

		WP_CLI::print_value( $value, $assoc_args );
	}

	/**
	 * Increments a value in the object cache.
	 *
	 * Errors if the value can't be incremented.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * [<offset>]
	 * : The amount by which to increment the item's value.
	 * ---
	 * default: 1
	 * ---
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Increase cache value.
	 *     $ fin cache incr my_key 2 my_group
	 *     50
	 *
	 * @param array{string, string, string} $args       Positional arguments.
	 * @param array<mixed>                  $assoc_args Associative arguments.
	 */
	public function incr( $args, $assoc_args ) {
		list( $key, $offset, $group ) = $args;
		$value = fin_cache_incr( $key, (int) $offset, $group );

		if ( false === $value ) {
			WP_CLI::error( 'The value was not incremented.' );
		}

		WP_CLI::print_value( $value, $assoc_args );
	}

	/**
	 * Replaces a value in the object cache, if the value already exists.
	 *
	 * Errors if the value can't be replaced.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * <value>
	 * : Value to replace.
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * [<expiration>]
	 * : Define how long to keep the value, in seconds. `0` means as long as possible.
	 * ---
	 * default: 0
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Replace cache.
	 *     $ fin cache replace my_key new_value my_group
	 *     Success: Replaced object 'my_key' in group 'my_group'.
	 *
	 * @param array{string, string, string, string} $args       Positional arguments.
	 * @param array<mixed>                          $assoc_args Associative arguments.
	 */
	public function replace( $args, $assoc_args ) {
		list( $key, $value, $group, $expiration ) = $args;
		$result = fin_cache_replace( $key, $value, $group, (int) $expiration );

		if ( false === $result ) {
			WP_CLI::error( "Could not replace object '$key' in group '$group'. Does it not exist?" );
		}

		WP_CLI::success( "Replaced object '$key' in group '$group'." );
	}

	/**
	 * Sets a value to the object cache, regardless of whether it already exists.
	 *
	 * Errors if the value can't be set.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * <value>
	 * : Value to set on the key.
	 *
	 * [<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * [<expiration>]
	 * : Define how long to keep the value, in seconds. `0` means as long as possible.
	 * ---
	 * default: 0
	 * ---
	 *
	 * ## EXAMPLES
	 *
	 *     # Set cache.
	 *     $ fin cache set my_key my_value my_group 300
	 *     Success: Set object 'my_key' in group 'my_group'.
	 *
	 * @param array{string, string, string, string} $args       Positional arguments.
	 * @param array<mixed>                          $assoc_args Associative arguments.
	 */
	public function set( $args, $assoc_args ) {
		list( $key, $value, $group, $expiration ) = $args;
		$result = fin_cache_set( $key, $value, $group, (int) $expiration );

		if ( false === $result ) {
			WP_CLI::error( "Could not add object '$key' in group '$group'." );
		}

		WP_CLI::success( "Set object '$key' in group '$group'." );
	}

	/**
	 * Attempts to determine which object cache is being used.
	 *
	 * Note that the guesses made by this function are based on the
	 * WP_Object_Cache classes that define the 3rd party object cache extension.
	 * Changes to those classes could render problems with this function's
	 * ability to determine which object cache is being used.
	 *
	 * ## EXAMPLES
	 *
	 *     # Check cache type.
	 *     $ fin cache type
	 *     Default
	 */
	public function type() {
		$message = WP_CLI\Utils\fin_get_cache_type();
		WP_CLI::line( $message );
	}

	/**
	 * Determines whether the object cache implementation supports a particular feature.
	 *
	 * ## OPTIONS
	 *
	 * <feature>
	 * : Name of the feature to check for.
	 *
	 * ## EXAMPLES
	 *
	 *     # Check whether is add_multiple supported.
	 *     $ fin cache supports add_multiple
	 *     $ echo $?
	 *     0
	 *
	 *     # Bash script for checking whether for support like this:
	 *     if ! fin cache supports non_existing; then
	 *         echo 'non_existing is not supported'
	 *     fi
	 *
	 * @param array{string} $args Positional arguments.
	 */
	public function supports( $args ) {
		list ( $feature ) = $args;

		if ( ! function_exists( 'fin_cache_supports' ) ) {
			WP_CLI::error( 'Checking cache features is only available in FinPress 6.1 and higher' );
		}

		$supports = fin_cache_supports( $feature );

		if ( $supports ) {
			WP_CLI::halt( 0 );
		}
		WP_CLI::halt( 1 );
	}

	/**
	 * Removes all cache items in a group, if the object cache implementation supports it.
	 *
	 * ## OPTIONS
	 *
	 * <group>
	 * : Cache group key.
	 *
	 * ## EXAMPLES
	 *
	 *     # Clear cache group.
	 *     $ fin cache flush-group my_group
	 *     Success: Cache group 'my_group' was flushed.
	 *
	 * @subcommand flush-group
	 *
	 * @param array{string} $args Positional arguments.
	 */
	public function flush_group( $args ) {
		list( $group ) = $args;

		if ( ! function_exists( 'fin_cache_supports' ) || ! fin_cache_supports( 'flush_group' ) ) {
			WP_CLI::error( 'Group flushing is not supported.' );
		}

		if ( ! fin_cache_flush_group( $group ) ) {
			WP_CLI::error( "Cache group '$group' was not flushed." );
		}
		WP_CLI::success( "Cache group '$group' was flushed." );
	}

	/**
	 * Get a nested value from the cache.
	 *
	 * ## OPTIONS
	 *
	 * <key>
	 * : Cache key.
	 *
	 * <key-path>...
	 * : The name(s) of the keys within the value to locate the value to pluck.
	 *
	 * [--group=<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * [--format=<format>]
	 * : The output format of the value.
	 * ---
	 * default: plaintext
	 * options:
	 *   - plaintext
	 *   - json
	 *   - yaml
	 * ---
	 *
	 * @param array{string, string}                $args       Positional arguments.
	 * @param array{group: string, format: string} $assoc_args Associative arguments.
	 */
	public function pluck( $args, $assoc_args ) {
		list( $key ) = $args;

		$group = Utils\get_flag_value( $assoc_args, 'group' );

		$value = fin_cache_get( $key, $group );

		if ( false === $value ) {
			WP_CLI::warning( "No object found for the key '$key' in group '$group'" );
			exit;
		}

		$key_path = array_map(
			function ( $key ) {
				if ( is_numeric( $key ) && ( (string) intval( $key ) === $key ) ) {
					return (int) $key;
				}
				return $key;
			},
			array_slice( $args, 1 )
		);

		$traverser = new RecursiveDataStructureTraverser( $value );

		try {
			$value = $traverser->get( $key_path );
		} catch ( \Exception $e ) {
			die( 1 );
		}

		WP_CLI::print_value( $value, $assoc_args );
	}

	/**
	 * Update a nested value from the cache.
	 *
	 * ## OPTIONS
	 *
	 * <action>
	 * : Patch action to perform.
	 * ---
	 * options:
	 *   - insert
	 *   - update
	 *   - delete
	 * ---
	 *
	 * <key>
	 * : Cache key.
	 *
	 * <key-path>...
	 * : The name(s) of the keys within the value to locate the value to patch.
	 *
	 * [<value>]
	 * : The new value. If omitted, the value is read from STDIN.
	 *
	 * [--group=<group>]
	 * : Method for grouping data within the cache which allows the same key to be used across groups.
	 * ---
	 * default: default
	 * ---
	 *
	 * [--expiration=<expiration>]
	 *  : Define how long to keep the value, in seconds. `0` means as long as possible.
	 *  ---
	 *  default: 0
	 *  ---
	 *
	 * [--format=<format>]
	 * : The serialization format for the value.
	 * ---
	 * default: plaintext
	 * options:
	 *   - plaintext
	 *   - json
	 * ---
	 *
	 * @param string[]                                                 $args       Positional arguments.
	 * @param array{group: string, expiration: string, format: string} $assoc_args Associative arguments.
	 */
	public function patch( $args, $assoc_args ) {
		list( $action, $key ) = $args;

		$group = Utils\get_flag_value( $assoc_args, 'group' );

		$expiration = Utils\get_flag_value( $assoc_args, 'expiration' );

		$key_path = array_map(
			function ( $key ) {
				if ( is_numeric( $key ) && ( (string) intval( $key ) === $key ) ) {
					return (int) $key;
				}

				return $key;
			},
			array_slice( $args, 2 )
		);

		if ( 'delete' === $action ) {
			$patch_value = null;
		} else {
			$stdin_value = Utils\has_stdin()
				? trim( WP_CLI::get_value_from_arg_or_stdin( $args, -1 ) )
				: null;

			if ( ! empty( $stdin_value ) ) {
				$patch_value = WP_CLI::read_value( $stdin_value, $assoc_args );
			} elseif ( count( $key_path ) > 1 ) {
				$patch_value = WP_CLI::read_value( array_pop( $key_path ), $assoc_args );
			} else {
				$patch_value = null;
			}

			if ( null === $patch_value ) {
				WP_CLI::error( 'Please provide value to update.' );
			}
		}

		/* Need to make a copy of $current_value here as it is modified by reference */
		$old_value     = fin_cache_get( $key, $group );
		$current_value = $old_value;
		if ( is_object( $old_value ) ) {
			$current_value = clone $old_value;
		}

		$traverser = new RecursiveDataStructureTraverser( $current_value );

		try {
			$traverser->$action( $key_path, $patch_value );
		} catch ( \Exception $e ) {
			WP_CLI::error( $e->getMessage() );
		}

		$patched_value = $traverser->value();

		if ( $patched_value === $old_value ) {
			WP_CLI::success( "Value passed for cache key '$key' is unchanged." );
		} else {
			$success = fin_cache_set( $key, $patched_value, $group, (int) $expiration );
			if ( $success ) {
				WP_CLI::success( "Updated cache key '$key'." );
			} else {
				WP_CLI::error( "Could not update cache key '$key'." );
			}
		}
	}
}
