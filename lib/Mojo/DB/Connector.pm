package Mojo::DB::Connector;
use Mojo::Base -base;
use Mojo::Parameters;
use Mojo::URL;

has env_prefix  => sub { 'MOJO_DB_CONNECTOR_' };
has scheme      => sub { shift->_attr_default('scheme', 'SCHEME', 'postgresql') };
has userinfo    => sub { shift->_attr_default('userinfo', 'USERINFO', '') };
has host        => sub { shift->_attr_default('host', 'HOST', 'localhost') };
has port        => sub { shift->_attr_default('port', 'PORT', '5432') };
has database    => sub { shift->_attr_default('path', 'DATABASE', '') };
has options     => sub {
    my $options = shift->_attr_default(sub { $_->query->pairs }, 'OPTIONS', '');
    return $options if ref $options;
    return Mojo::Parameters->new($options)->pairs;
};
has url         => sub {
    my $env_url = $ENV{shift->env_prefix . 'URL'};
    return unless $env_url;

    my $url = Mojo::URL->new($env_url);
    # so database does not have a leading slash
    $url->path->leading_slash(undef);

    return $url;
};
has strict_mode => sub { $ENV{shift->env_prefix . 'STRICT_MODE'} // 1 };

has [qw(_required_mysql _required_pg)];

our $VERSION = '0.03';

sub new_connection {
    my $self = shift;
    my %config = $self->_config(@_);

    my ($package, $constructor);
    my $scheme = $config{scheme};
    if ($scheme eq 'mariadb' or $scheme eq 'mysql') {
        $package = 'Mojo::mysql';
        $constructor = $config{strict_mode} ? 'strict_mode' : 'new';

        if (not $self->_required_mysql) {
            eval { require Mojo::mysql; 1 } or Carp::croak "Failed to require Mojo::mysql $@";
            $self->_required_mysql(1);
        }
    } elsif ($scheme eq 'postgresql') {
        $package = 'Mojo::Pg';
        $constructor = 'new';

        if (not $self->_required_pg) {
            eval { require Mojo::Pg; 1 } or Carp::croak "Failed to require Mojo::Pg $@";
            $self->_required_pg(1);
        }
    } else {
        Carp::croak "unknown scheme '$scheme'. Supported schemes are: mariadb, mysql, postgresql";
    }

    return $package->$constructor($self->_to_url(%config)->to_unsafe_string);
}

sub _to_url {
    my ($self, %config) = @_;

    my $url =
        Mojo::URL->new
                 ->scheme($config{scheme})
                 ->userinfo($config{userinfo})
                 ->host($config{host})
                 ->port($config{port})
                 ->path($config{database})
                 ;
    $url->query($self->options);

    if ($config{options}) {
        if ($config{replace_options}) {
            $url->query(@{ $config{options} });
        } else {
            $url->query($config{options});
        }
    }

    return $url;
}

sub _config {
    my $self = shift;

    return (
        (map { $_ => $self->$_ } qw(scheme userinfo host port database strict_mode)),
        @_,
    );
}

sub _attr_default {
    my ($self, $url_method, $env_suffix, $default) = @_;

    if (my $url = $self->url) {
        return ref $url_method ? $url_method->(local $_ = $url) : $url->$url_method;
    }

    return $ENV{$self->env_prefix . $env_suffix} // $default;
}

1;
__END__

=encoding utf-8

=head1 NAME

L<Mojo::DB::Connector> - Create and cache DB connections using common connection info

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-DB-Connector"><img src="https://travis-ci.org/srchulo/Mojo-DB-Connector.svg?branch=master"></a> <a href='https://coveralls.io/github/srchulo/Mojo-DB-Connector?branch=master'><img src='https://coveralls.io/repos/github/srchulo/Mojo-DB-Connector/badge.svg?branch=master' alt='Coverage Status' /></a>

=head1 SYNOPSIS

  use Mojo::DB::Connector;

  # use default connection info or use connection info
  # set in environment variables
  my $connector  = Mojo::DB::Connector->new;
  my $connection = $connector->new_connection;
  my $results    = $connection->db->query(...);

  # pass connection info in (some defaults still used)
  my $connector  = Mojo::DB::Connector->new(host => 'batman.com', userinfo => 'sri:s3cret');
  my $connection = $connector->new_connection(database => 'my_s3cret_database');
  my $results    = $connection->db->query(...);

  # cache connections using Mojo::DB::Connector::Role::Cache
  my $connector = Mojo::DB::Connector->new->with_roles('+Cache');

  # fresh connection the first time
  my $connection = $connector->cached_connection(database => 'my_database');

  # later somewhere else...
  # same connection (Mojo::mysql or Mojo::Pg object) as before
  my $connection = $connector->cached_connection(database => 'my_database');

=head1 DESCRIPTION

L<Mojo::DB::Connector> is a thin wrapper around L<Mojo::mysql> and L<Mojo::Pg> that is
useful when you want to connect to different databases using slightly different
connection info. It also allows you to easily connect using different settings in
different environments by using environment variables to connect (see L</ATTRIBUTES>).
This can be useful when developing using something like L<Docker|https://www.docker.com/>,
which easily allows you to set different environment variables in dev/prod.

See L<Mojo::DB::Connector::Role::Cache> for the ability to cache connections.

=head1 ATTRIBUTES

=head2 env_prefix

  my $connector = Mojo::DB::Connector->new(env_prefix => 'MOJO_DB_CONNECTOR_');

  my $env_prefix = $connector->env_prefix;
  $connector     = $connector->env_prefix('MOJO_DB_CONNECTOR_');

The prefix that will be used for environment variables names when checking for default values.
The prefix will go before:

=over 4

=item

L<SCHEME|/scheme>

=item

L<USERINFO|/userinfo>

=item

L<HOST|/host>

=item

L<PORT|/port>

=item

L<DATABASE|/database>

=item

L<OPTIONS|/options>

=item

L<URL|/url>

=item

L<STRICT_MODE|/strict_mode>

=back

L</env_prefix> allows you to use different L<Mojo::DB::Connector> objects to easily generate connections
for different connection settings.

Default is C<MOJO_DB_CONNECTOR_>.

=head2 scheme

  my $scheme = $connector->scheme;
  $connector = $connector->scheme('postgresql');

The L<Mojo::URL/scheme> that will be used for generating the connection URL.
Allowed values are L<mariadb|DBD::MariaDB>, L<mysql|DBD::mysql>, and L<postgresql|DBD::Pg>. The scheme
will determine whether a L<Mojo::mysql> or L<Mojo::Pg> instance is returned. C<mariadb> and C<mysql>
indicate L<Mojo::mysql>, and C<postgresql> indicates L<Mojo::Pg>.

This can also be derived from L<Mojo::URL/scheme> via L</url> or set with the environment variable C<MOJO_DB_CONNECTOR_SCHEME>.

Default is first derived from L<Mojo::URL/scheme> via C<$ENV{MOJO_DB_CONNECTOR_URL}>,
then C<$ENV{MOJO_DB_CONNECTOR_SCHEME}>, and then falls back to C<postgresql>.

=head2 userinfo

  my $userinfo = $connector->userinfo;
  $connector   = $connector->userinfo('sri:s3cret');

The L<Mojo::URL/userinfo> that will be used for generating the connection URL.

This can also be derived from L<Mojo::URL/userinfo> via L</url> or set with the environment variable C<MOJO_DB_CONNECTOR_USERINFO>.

Default is first derived from L<Mojo::URL/userinfo> via C<$ENV{MOJO_DB_CONNECTOR_URL}>,
then C<$ENV{MOJO_DB_CONNECTOR_USERINFO}>, and then falls back to no C<userinfo> (empty string).

=head2 host

  my $host   = $connector->host;
  $connector = $connector->host('localhost');

The L<Mojo::URL/host> that will be used for generating the connection URL.

This can also be derived from L<Mojo::URL/host> via L</url> or set with the environment variable C<MOJO_DB_CONNECTOR_HOST>.

Default is first derived from L<Mojo::URL/host> via C<$ENV{MOJO_DB_CONNECTOR_URL}>,
then C<$ENV{MOJO_DB_CONNECTOR_HOST}>, and then falls back to C<localhost>.

=head2 port

  my $port   = $connector->port;
  $connector = $connector->port(5432);

The L<Mojo::URL/port> that will be used for generating the connection URL.

This can also be derived from L<Mojo::URL/port> via L</url> or set with the environment variable C<MOJO_DB_CONNECTOR_PORT>.

Default is first derived from L<Mojo::URL/port> via C<$ENV{MOJO_DB_CONNECTOR_URL}>,
then C<$ENV{MOJO_DB_CONNECTOR_PORT}>, and then falls back to C<5432>.

=head2 database

  my $database = $connector->database;
  $connector   = $connector->database('my_database');

The database that will be used for generating the connection URL. This will be used
as L<Mojo::URL/path>.

This can also be derived from L<Mojo::URL/path> via L</url> or set with the environment variable C<MOJO_DB_CONNECTOR_DATABASE>.

Default is first derived from L<Mojo::URL/path> via C<$ENV{MOJO_DB_CONNECTOR_URL}>,
then C<$ENV{MOJO_DB_CONNECTOR_DATABASE}>, and then falls back to no C<database> (empty string).

=head2 options

  my $options = $connector->options;
  $connector  = $connector->options([PrintError => 1, RaiseError => 0]);

  # hashref also accepted
  $connector  = $connector->options({PrintError => 1, RaiseError => 0});

The options that will be used as the parameters (L<Mojo::Parameters>) for generating the connection URL. This will be used
as L<Mojo::URL/query>. This accepts any valid input for L<Mojo::URL/query> except a list.

This can also be derived from L<Mojo::URL/query> via L</url> or set with the environment variable C<MOJO_DB_CONNECTOR_OPTIONS>.

When set with the environment variable C<MOJO_DB_CONNECTOR_OPTIONS>, L</options> must be specified in
valid URL parameter syntax:

  $ENV{MOJO_DB_CONNECTOR_OPTIONS} = 'PrintError=1&RaiseError=0';

Default is first derived from L<Mojo::URL/query> via C<$ENV{MOJO_DB_CONNECTOR_URL}>,
then C<$ENV{MOJO_DB_CONNECTOR_OPTIONS}>, and then falls back to C<[]> (no options).

=head2 url

  my $url    = $connector->url;
  $connector = $connector->url('postgres://sri:s3cret@localhost/db3?PrintError=1&RaiseError=0');

The connection URL from which all other attributes can be derived (except L</strict_mode>).
L</url> must be specified before the first call to L</new_connection> is made, otherwise it will have no effect on setting the defaults.

This can also be set with the environment variable C<MOJO_DB_CONNECTOR_URL>.

Default is C<$ENV{MOJO_DB_CONNECTOR_URL}> and then falls back to C<undef> (no URL).

=head2 strict_mode

  my $strict_mode = $connector->strict_mode;
  $connector      = $connector->strict_mode(1);

L</strict_mode> determines if connections should be created in L<Mojo::mysql/strict_mode>.

Note that this only applies to L<Mojo::mysql> and does B<not> apply to L<Mojo::Pg>.
If a L<Mojo::Pg> connection is created, this will have no effect.

This can also be set with the environment variable C<MOJO_DB_CONNECTOR_STRICT_MODE>.

Default is C<$ENV{MOJO_DB_CONNECTOR_STRICT_MODE}> and falls back to C<1>

=head1 METHODS

=head2 new_connection

  # use environment variables or defaults
  my $connection = $connector->new_connection;
  my $results    = $connection->db->query(...);

  # provide attribute overrides just for this call
  my $connection = $connector->new_connection(database => 'my_database', host => 'batman.com');
  my $results    = $connection->db->query(...);

L</new_connection> creates a new connection (L<Mojo::mysql> or L<Mojo::Pg> instance) using
either the connection info in L</ATTRIBUTES>, or any override values passed.

Any override values that are passed will completely replace any values in L</ATTRIBUTES>:

  my $connection = $connector->new_connection(database => 'my_database', host => 'batman.com');
  my $results    = $connection->db->query(...);

Except for L</options>. L</options> follows the same format as L<Mojo::URL/query>:

  # merge with existing options in attribute options by using a hashref
  my $connection = $connector->new_connection(options => {merge => 'to'});

  # append to existing options in attribute options by using an arrayref
  my $connection = $connector->new_connection(options => [append => 'with']);

  # replace existing options completely by passing replace_options => 1
  # must provide an arrayref for replace_options
  my $connection = $connector->new_connection(options => [append => 'with'], replace_options => 1);

C<replace_options> is needed because you cannot pass a list for the C<options> value. If C<replace_options>
is provided, the C<options> parameter must be an arrayref.

See L<Mojo::mysql/options> or L<Mojo::Pg/options>.

=head1 SEE ALSO

=over 4

=item

L<Mojo::DB::Connector::Role::Cache>

=item

L<Mojo::DB::Connector::Role::ResultsRoles>

Apply roles to Mojo database results from L<Mojo::DB::Connector> connections.

=item

L<Mojo::mysql>

=item

L<Mojo::Pg>

=back

=head1 LICENSE

This software is copyright (c) 2020 by Adam Hopkins

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=cut

