Feature: Manage FinPress transient cache

  Scenario: Transient CRUD
    Given a WP install

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I run `fin transient set foo bar`
    Then STDOUT should be:
      """
      Success: Transient added.
      """

    When I run `fin transient get foo`
    Then STDOUT should be:
      """
      bar
      """

    When I run `fin transient delete foo`
    Then STDOUT should be:
      """
      Success: Transient deleted.
      """

  Scenario: Network transient CRUD
    Given a WP multisite install
    And I run `fin site create --slug=foo`

    When I run `fin transient set foo bar --network`
    Then STDOUT should be:
      """
      Success: Transient added.
      """

    When I run `fin --url=example.com/foo transient get foo --network`
    Then STDOUT should be:
      """
      bar
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I run `fin transient delete foo --network`
    Then STDOUT should be:
      """
      Success: Transient deleted.
      """

  Scenario: Deleting all transients on single site
    Given a WP install
    # We set `WP_DEVELOPMENT_MODE` to stop FinPress from automatically creating
    # additional transients which cause some steps to fail when testing.
    And I run `fin config set WP_DEVELOPMENT_MODE all`

    And I run `fin transient list --format=count`
    And save STDOUT as {EXISTING_TRANSIENTS}
    And I run `expr {EXISTING_TRANSIENTS} + 2`
    And save STDOUT as {EXPECTED_TRANSIENTS}

    When I try `fin transient delete`
    Then STDERR should be:
      """
      Error: Please specify transient key, or use --all or --expired.
      """

    When I run `fin transient set foo bar`
    And I run `fin transient set foo2 bar2 600`
    And I run `fin transient set foo3 bar3 --network`
    And I run `fin transient set foo4 bar4 600 --network`

    And I run `fin transient delete --all`
    Then STDOUT should be:
      """
      Success: {EXPECTED_TRANSIENTS} transients deleted from the database.
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I try `fin transient get foo2`
    Then STDERR should be:
      """
      Warning: Transient with key "foo2" is not set.
      """

    When I run `fin transient get foo3 --network`
    Then STDOUT should be:
      """
      bar3
      """

    When I run `fin transient get foo4 --network`
    Then STDOUT should be:
      """
      bar4
      """

    When I run `fin transient delete --all --network`
    Then STDOUT should be:
      """
      Success: 2 transients deleted from the database.
      """

    When I try `fin transient get foo3 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo3" is not set.
      """

    When I try `fin transient get foo4 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo4" is not set.
      """

  Scenario: Deleting expired transients on single site
    Given a WP install
    And I run `fin transient set foo bar 600`
    And I run `fin transient set foo2 bar2 600`
    And I run `fin transient set foo3 bar3 600 --network`
    And I run `fin transient set foo4 bar4 600 --network`
    # Change timeout to be in the past.
    And I run `fin option update _transient_timeout_foo 1321009871`
    And I run `fin option update _site_transient_timeout_foo3 1321009871`

    When I run `fin transient delete --expired`
    Then STDOUT should be:
      """
      Success: 1 expired transient deleted from the database.
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I run `fin transient get foo2`
    Then STDOUT should be:
      """
      bar2
      """

    # Check if option still exists as a get transient call will remove it.
    When I run `fin option get _site_transient_foo3`
    Then STDOUT should be:
      """
      bar3
      """

    When I run `fin transient get foo4 --network`
    Then STDOUT should be:
      """
      bar4
      """

    When I run `fin transient delete --expired --network`
    Then STDOUT should be:
      """
      Success: 1 expired transient deleted from the database.
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I run `fin transient get foo2`
    Then STDOUT should be:
      """
      bar2
      """

    When I try `fin transient get foo3 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo3" is not set.
      """

    When I run `fin transient get foo4 --network`
    Then STDOUT should be:
      """
      bar4
      """

  Scenario: Deleting all transients on multisite
    Given a WP multisite install
    # We set `WP_DEVELOPMENT_MODE` to stop FinPress from automatically creating
    # additional transients which cause some steps to fail when testing.
    And I run `fin config set WP_DEVELOPMENT_MODE all`
    And I run `fin site create --slug=foo`
    And I run `fin transient list --format=count`
    And save STDOUT as {EXISTING_TRANSIENTS}
    And I run `expr {EXISTING_TRANSIENTS} + 2`
    And save STDOUT as {EXPECTED_TRANSIENTS}

    When I try `fin transient delete`
    Then STDERR should be:
      """
      Error: Please specify transient key, or use --all or --expired.
      """

    When I run `fin transient set foo bar`
    And I run `fin transient set foo2 bar2 600`
    And I run `fin transient set foo3 bar3 --network`
    And I run `fin transient set foo4 bar4 600 --network`
    And I run `fin --url=example.com/foo transient set foo5 bar5 --network`
    And I run `fin --url=example.com/foo transient set foo6 bar6 600 --network`
    And I run `fin transient delete --all`
    Then STDOUT should be:
      """
      Success: {EXPECTED_TRANSIENTS} transients deleted from the database.
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I try `fin transient get foo2`
    Then STDERR should be:
      """
      Warning: Transient with key "foo2" is not set.
      """

    When I run `fin transient get foo3 --network`
    Then STDOUT should be:
      """
      bar3
      """

    When I run `fin transient get foo4 --network`
    Then STDOUT should be:
      """
      bar4
      """

    When I run `fin --url=example.com/foo transient get foo5 --network`
    Then STDOUT should be:
      """
      bar5
      """

    When I run `fin --url=example.com/foo transient get foo6 --network`
    Then STDOUT should be:
      """
      bar6
      """

    When I run `fin transient delete --all --network`
    Then STDOUT should be:
      """
      Success: 4 transients deleted from the database.
      """

    When I try `fin transient get foo3 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo3" is not set.
      """

    When I try `fin transient get foo4 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo4" is not set.
      """

    When I try `fin --url=example.com/foo transient get foo5 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo5" is not set.
      """

    When I try `fin --url=example.com/foo transient get foo6 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo6" is not set.
      """

  Scenario: Deleting expired transients on multisite
    Given a WP multisite install
    And I run `fin site create --slug=foo`
    And I run `fin transient set foo bar 600`
    And I run `fin transient set foo2 bar2 600`
    And I run `fin transient set foo3 bar3 600 --network`
    And I run `fin transient set foo4 bar4 600 --network`
    And I run `fin --url=example.com/foo transient set foo5 bar5 600 --network`
    And I run `fin --url=example.com/foo transient set foo6 bar6 600 --network`
    # Change timeout to be in the past.
    And I run `fin option update _transient_timeout_foo 1321009871`
    And I run `fin site option update _site_transient_timeout_foo3 1321009871`
    And I run `fin --url=example.com/foo site option update _site_transient_timeout_foo5 1321009871`

    When I run `fin transient delete --expired`
    Then STDOUT should be:
      """
      Success: 1 expired transient deleted from the database.
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I run `fin transient get foo2`
    Then STDOUT should be:
      """
      bar2
      """

    # Check if option still exists as a get transient call will remove it.
    When I run `fin site option get _site_transient_foo3`
    Then STDOUT should be:
      """
      bar3
      """

    When I run `fin transient get foo4 --network`
    Then STDOUT should be:
      """
      bar4
      """

    # Check if option still exists as a get transient call will remove it.
    When I run `fin --url=example.com/foo site option get _site_transient_foo5`
    Then STDOUT should be:
      """
      bar5
      """

    When I run `fin --url=example.com/foo transient get foo6 --network`
    Then STDOUT should be:
      """
      bar6
      """

    When I run `fin transient delete --expired --network`
    Then STDOUT should be:
      """
      Success: 2 expired transients deleted from the database.
      """

    When I try `fin transient get foo`
    Then STDERR should be:
      """
      Warning: Transient with key "foo" is not set.
      """

    When I run `fin transient get foo2`
    Then STDOUT should be:
      """
      bar2
      """

    When I try `fin transient get foo3 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo3" is not set.
      """

    When I run `fin transient get foo4 --network`
    Then STDOUT should be:
      """
      bar4
      """

    When I try `fin --url=example.com/foo transient get foo5 --network`
    Then STDERR should be:
      """
      Warning: Transient with key "foo5" is not set.
      """

    When I run `fin --url=example.com/foo transient get foo6 --network`
    Then STDOUT should be:
      """
      bar6
      """

  Scenario: List transients on single site
    Given a WP install
    And I run `fin transient set foo bar`
    And I run `fin transient set foo2 bar2 610`
    And I run `fin option update _transient_timeout_foo2 95649119999`
    And I run `fin transient set foo3 bar3 300`
    And I run `fin option update _transient_timeout_foo3 1321009871`
    And I run `fin transient set foo4 bar4 --network`
    And I run `fin transient set foo5 bar5 610 --network`
    And I run `fin option update _site_transient_timeout_foo5 95649119999`
    And I run `fin transient set foo6 bar6 300 --network`
    And I run `fin option update _site_transient_timeout_foo6 1321009871`

    When I run `fin transient list --format=csv`
    Then STDOUT should contain:
      """
      foo,bar,false
      """
    And STDOUT should contain:
      """
      foo2,bar2,95649119999
      """
    And STDOUT should contain:
      """
      foo3,bar3,1321009871
      """

    When I run `fin transient list --format=csv --human-readable`
    Then STDOUT should contain:
      """
      foo,bar,"never expires"
      """
    And STDOUT should contain:
      """
      foo3,bar3,expired
      """
    And STDOUT should not contain:
      """
      foo2,bar2,95649119999
      """

    When I run `fin transient list --network --format=csv`
    Then STDOUT should contain:
      """
      foo4,bar4,false
      """
    And STDOUT should contain:
      """
      foo5,bar5,95649119999
      """
    And STDOUT should contain:
      """
      foo6,bar6,1321009871
      """

  Scenario: List transients on multisite
    Given a WP multisite install
    # We set `WP_DEVELOPMENT_MODE` to stop FinPress from automatically creating
    # additional transients which cause some steps to fail when testing.
    And I run `fin config set WP_DEVELOPMENT_MODE all`
    And I run `fin transient set foo bar`
    And I run `fin transient set foo2 bar2 610`
    And I run `fin option update _transient_timeout_foo2 95649119999`
    And I run `fin transient set foo3 bar3 300`
    And I run `fin option update _transient_timeout_foo3 1321009871`
    And I run `fin transient set foo4 bar4 --network`
    And I run `fin transient set foo5 bar5 610 --network`
    And I run `fin site option update _site_transient_timeout_foo5 95649119999`
    And I run `fin transient set foo6 bar6 300 --network`
    And I run `fin site option update _site_transient_timeout_foo6 1321009871`

    When I run `fin transient list --format=csv`
    Then STDOUT should contain:
      """
      foo,bar,false
      """
    And STDOUT should contain:
      """
      foo2,bar2,95649119999
      """
    And STDOUT should contain:
      """
      foo3,bar3,1321009871
      """

    When I run `fin transient list --format=csv --human-readable`
    Then STDOUT should contain:
      """
      foo,bar,"never expires"
      """
    And STDOUT should contain:
      """
      foo3,bar3,expired
      """
    And STDOUT should not contain:
      """
      foo2,bar2,95649119999
      """

    When I run `fin transient list --network --format=csv`
    Then STDOUT should contain:
      """
      foo4,bar4,false
      """
    And STDOUT should contain:
      """
      foo5,bar5,95649119999
      """
    And STDOUT should contain:
      """
      foo6,bar6,1321009871
      """

  Scenario: List transients with search and exclude pattern
    Given a WP install
    And I run `fin transient set foo bar`
    And I run `fin transient set foo2 bar2`
    And I run `fin transient set foo3 bar3`
    And I run `fin transient set foo4 bar4 --network`
    And I run `fin transient set foo5 bar5 --network`

    When I run `fin transient list --format=csv --fields=name --search="foo"`
    Then STDOUT should be:
      """
      name
      foo
      """

    When I run `fin transient list --format=csv --fields=name --search="foo*"`
    Then STDOUT should be:
      """
      name
      foo
      foo2
      foo3
      """

    When I run `fin transient list --format=csv --fields=name --search="*oo"`
    Then STDOUT should be:
      """
      name
      foo
      """

    When I run `fin transient list --format=csv --fields=name --search="*oo*"`
    Then STDOUT should be:
      """
      name
      foo
      foo2
      foo3
      """

    When I run `fin transient list --format=csv --fields=name --search="*oo?"`
    Then STDOUT should be:
      """
      name
      foo2
      foo3
      """

    When I run `fin transient list --format=csv --fields=name --search="foo?"`
    Then STDOUT should be:
      """
      name
      foo2
      foo3
      """

    When I run `fin transient list --format=csv --fields=name --search="doesnotexist*"`
    Then STDOUT should be:
      """
      name
      """

    When I run `fin transient list --format=csv --fields=name --search="foo*" --exclude="foo2"`
    Then STDOUT should be:
      """
      name
      foo
      foo3
      """

    When I run `fin transient list --format=csv --fields=name --search="foo*" --exclude="*3"`
    Then STDOUT should be:
      """
      name
      foo
      foo2
      """

    When I run `fin transient list --format=csv --fields=name --search="foo*" --exclude="foo?"`
    Then STDOUT should be:
      """
      name
      foo
      """

    When I run `fin transient list --format=csv --fields=name --search="foo*" --network`
    Then STDOUT should be:
      """
      name
      foo4
      foo5
      """

    When I run `fin transient list --format=csv --fields=name --search="foo*" --exclude="foo5" --network`
    Then STDOUT should be:
      """
      name
      foo4
      """
