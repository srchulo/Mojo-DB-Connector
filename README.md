# NAME

[Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) - Create and cache DB connections using common connection info

# STATUS

<div>
    <a href="https://travis-ci.org/srchulo/Mojo-DB-Connector"><img src="https://travis-ci.org/srchulo/Mojo-DB-Connector.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Connector?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Connector/badge.svg?branch=master' alt='Coverage Status' /></a>
</div>

# SYNOPSIS

    use Mojo::DB::Connector;

    # use default connection info or use connection info
    # set in environment variables
    my $connector  = Mojo::DB::Connector->new;
    my $connection = $connector->new_connection('my_database');
    my $results    = $connection->db->query(...);

    # pass connection info in
    my $connector  = Mojo::DB::Connector->new(host => 'batman.com', userinfo => 'sri:s3cret');
    my $connection = $connector->new_connection('my_s3cret_database');
    my $results    = $connection->db->query(...);

    # cache connections using Mojo::DB::Connector::Role::Cache
    my $connector = Mojo::DB::Connector->new->with_roles('+Cache');

    # fresh connection the first time
    my $connection = $connector->cached_connection('my_database');

    # later somewhere else...
    # same connection (Mojo::mysql or Mojo::Pg object) as before
    my $connection = $connector->cached_connection('my_database');

# DESCRIPTION

[Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) is a thin wrapper around [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) and [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) that is
useful when you want to connect to different databases on the same server using the same
connection info. It also allows you to easily connect using different settings in
different environments by using environment variables to connect (see ["ATTRIBUTES"](#attributes)).
This can be useful when developing using something like [Docker](https://www.docker.com/),
which easily allows you to set different environment variables in dev/prod.

See [Mojo::DB::Connector::Role::Cache](https://metacpan.org/pod/Mojo::DB::Connector::Role::Cache) for the ability to cache connections.

# ATTRIBUTES

## scheme

    my $scheme = $connector->scheme;
    $connector = $connector->scheme('postgresql');

The ["scheme" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#scheme) that will be used for generating the connection URL.
Allowed values are [mariadb](https://metacpan.org/pod/DBD::MariaDB), [mysql](https://metacpan.org/pod/DBD::mysql), and [postgresql](https://metacpan.org/pod/DBD::Pg). The scheme
will determine whether a [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) or [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) instance is returned. `mariadb` and `mysql`
indicate [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql), and `postgresql` indicates [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg).

This can also be set with the environment variable `MOJO_DB_CONNECTOR_SCHEME`.

Default is `$ENV{MOJO_DB_CONNECTOR_SCHEME}` and falls back to `postgresql`.

## userinfo

    my $userinfo = $connector->userinfo;
    $connector   = $connector->userinfo('sri:s3cret');

The ["userinfo" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#userinfo) that will be used for generating the connection URL.

This can also be set with the environment variable `MOJO_DB_CONNECTOR_USERINFO`.

Default is `$ENV{MOJO_DB_CONNECTOR_USERINFO}` and falls back to no `userinfo` (empty string).

## host

    my $host   = $connector->host;
    $connector = $connector->host('localhost');

The ["host" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#host) that will be used for generating the connection URL.

This can also be set with the environment variable `MOJO_DB_CONNECTOR_HOST`.

Default is `$ENV{MOJO_DB_CONNECTOR_HOST}` and falls back to `localhost`.

## port

    my $port   = $connector->port;
    $connector = $connector->port(5432);

The ["port" in Mojo::URL](https://metacpan.org/pod/Mojo::URL#port) that will be used for generating the connection URL.

This can also be set with the environment variable `MOJO_DB_CONNECTOR_PORT`.

Default is `$ENV{MOJO_DB_CONNECTOR_PORT}` and falls back to `5432`.

## strict\_mode

    my $strict_mode = $connector->strict_mode;
    $connector      = $connector->strict_mode(1);

["strict\_mode"](#strict_mode) determines if connections should be created in ["strict\_mode" in Mojo::mysql](https://metacpan.org/pod/Mojo::mysql#strict_mode).

Note that this only applies to [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) and does **not** apply to [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg).
If a [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) connection is created, this will have no effect.

This can also be set with the environment variable `MOJO_DB_CONNECTOR_STRICT_MODE`.

Default is `$ENV{MOJO_DB_CONNECTOR_STRICT_MODE}` and falls back to `1`

# METHODS

## new\_connection

    my $connection = $connector->new_connection('my_database');
    my $results    = $connection->db->query(...);

    # use options
    my $connection = $connector->new_connection('my_database', PrintError => 1, RaiseError => 0);
    my $results    = $connection->db->query(...);

["new\_connection"](#new_connection) creates a new connection ([Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) or [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) instance) using
the connection info in ["ATTRIBUTES"](#attributes).

["new\_connection"](#new_connection) requires a database name, and accepts optional options to be passed as
key/value pairs. See ["options" in Mojo::mysql](https://metacpan.org/pod/Mojo::mysql#options) or ["options" in Mojo::Pg](https://metacpan.org/pod/Mojo::Pg#options).

# SEE ALSO

- [Mojo::DB::Connector::Role::Cache](https://metacpan.org/pod/Mojo::DB::Connector::Role::Cache)
- [Mojo::DB::Connector::Role::ResultsRoles](https://metacpan.org/pod/Mojo::DB::Connector::Role::ResultsRoles)

    Apply roles to Mojo database results from [Mojo::DB::Connector](https://metacpan.org/pod/Mojo::DB::Connector) connections.

- [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql)
- [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg)

# LICENSE

This software is copyright (c) 2020 by Adam Hopkins

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHOR

Adam Hopkins <srchulo@cpan.org>
