Feature: Managed the FinPress object cache

  Scenario: Default group is 'default'
    Given a WP install
    And a fin-content/mu-plugins/test-harness.php file:
      """
      <?php
      $set_foo = function(){
        fin_cache_set( 'foo', 'bar' );
      };
      $set_foo_value = function() {
        fin_cache_set( 'foo', 2 );
      };
      $log_foo_value = function() {
        WP_CLI::log( var_export( fin_cache_get( 'foo' ), true ) );
      };
      WP_CLI::add_hook( 'before_invoke:cache get', $set_foo );
      WP_CLI::add_hook( 'before_invoke:cache delete', $set_foo );
      WP_CLI::add_hook( 'before_invoke:cache add', $set_foo );
      WP_CLI::add_hook( 'before_invoke:cache incr', $set_foo_value );
      WP_CLI::add_hook( 'before_invoke:cache decr', $set_foo_value );
      WP_CLI::add_hook( 'after_invoke:cache set', $log_foo_value );
      WP_CLI::add_hook( 'before_invoke:cache replace', $set_foo_value );
      """

    When I run `fin cache get foo`
    Then STDOUT should be:
      """
      bar
      """

    When I try `fin cache get bar`
    Then STDERR should be:
      """
      Error: Object with key 'bar' and group 'default' not found.
      """

    When I try `fin cache get bar burrito`
    Then STDERR should be:
      """
      Error: Object with key 'bar' and group 'burrito' not found.
      """

    When I run `fin cache delete foo`
    Then STDOUT should be:
      """
      Success: Object deleted.
      """

    When I try `fin cache delete bar`
    Then STDERR should be:
      """
      Error: The object was not deleted.
      """

    When I try `fin cache add foo bar`
    Then STDERR should be:
      """
      Error: Could not add object 'foo' in group 'default'. Does it already exist?
      """

    When I run `fin cache add bar burrito`
    Then STDOUT should be:
      """
      Success: Added object 'bar' in group 'default'.
      """

    When I run `fin cache add bar foo burrito`
    Then STDOUT should be:
      """
      Success: Added object 'bar' in group 'burrito'.
      """

    When I run `fin cache incr foo`
    Then STDOUT should be:
      """
      3
      """

    When I run `fin cache incr foo 2`
    Then STDOUT should be:
      """
      4
      """

    When I try `fin cache incr bar`
    Then STDERR should be:
      """
      Error: The value was not incremented.
      """

    When I run `fin cache decr foo`
    Then STDOUT should be:
      """
      1
      """

    When I run `fin cache decr foo 2`
    Then STDOUT should be:
      """
      0
      """

    When I try `fin cache decr bar`
    Then STDERR should be:
      """
      Error: The value was not decremented.
      """

    When I run `fin cache set foo bar`
    Then STDOUT should be:
      """
      Success: Set object 'foo' in group 'default'.
      'bar'
      """

    When I run `fin cache set burrito foo bar`
    Then STDOUT should be:
      """
      Success: Set object 'burrito' in group 'bar'.
      false
      """

    When I run `fin cache replace foo burrito`
    Then STDOUT should be:
      """
      Success: Replaced object 'foo' in group 'default'.
      """

    When I try `fin cache replace bar burrito foo`
    Then STDERR should be:
      """
      Error: Could not replace object 'bar' in group 'foo'. Does it not exist?
      """

  @require-fin-6.1
  Scenario: Some cache groups cannot be cleared.
    Given a WP install
    When I run `fin cache flush-group add_multiple`
    Then STDOUT should be:
      """
      Success: Cache group 'add_multiple' was flushed.
      """

  @require-fin-6.1
  Scenario: Some cache groups cannot be cleared.
    Given a WP install
    And a fin-content/mu-plugins/unclearable-test-cache.php file:
      """php
      <?php
      class Dummy_Object_Cache extends WP_Object_Cache {
        public function flush_group( $group ) {
          if ( $group === 'permanent_root_cache' ) {
            return false;
          }
          return parent::flush_group( $group );
        }
      }
      $GLOBALS['fin_object_cache'] = new Dummy_Object_Cache();
      """
    When I try `fin cache flush-group permanent_root_cache`
    Then STDERR should be:
      """
      Error: Cache group 'permanent_root_cache' was not flushed.
      """

  @less-than-fin-6.1
  Scenario: Some cache groups cannot be cleared.
    Given a WP install
    And a fin-content/mu-plugins/unclearable-test-cache.php file:
      """php
      <?php
      class Dummy_Object_Cache extends WP_Object_Cache {
        public function flush_group( $group ) {
          if ( $group === 'permanent_root_cache' ) {
            return false;
          }
          return parent::flush_group( $group );
        }
      }
      $GLOBALS['fin_object_cache'] = new Dummy_Object_Cache();
      """
    When I try `fin cache flush-group permanent_root_cache`
    Then STDERR should be:
      """
      Error: Group flushing is not supported.
      """

  Scenario: Flushing cache on a multisite installation
    Given a WP multisite installation

    When I try `fin cache flush`
    Then STDERR should not contain:
      """
      Warning: Flushing the cache may affect all sites in a multisite installation, depending on the implementation of the object cache.
      """

    When I try `fin cache flush --url=example.com`
    Then STDERR should contain:
      """
      Warning: Flushing the cache may affect all sites in a multisite installation, depending on the implementation of the object cache.
      """

  @require-fin-6.1
  Scenario: Checking if the cache supports a feature
    Given a WP install

    When I try `fin cache supports non_existing`
    Then the return code should be 1

    When I run `fin cache supports set_multiple`
    Then the return code should be 0
