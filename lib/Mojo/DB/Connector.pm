package Mojo::DB::Connector;
use Mojo::Base -base;
use Mojo::URL;

has scheme      => sub { $ENV{MOJO_DB_CONNECTOR_SCHEME} // 'postgresql' };
has userinfo    => sub { $ENV{MOJO_DB_CONNECTOR_USERINFO} // ''};
has host        => sub { $ENV{MOJO_DB_CONNECTOR_HOST} // 'localhost' };
has port        => sub { $ENV{MOJO_DB_CONNECTOR_PORT} // '5432' };
has strict_mode => sub { $ENV{MOJO_DB_CONNECTOR_STRICT_MODE} // 1 };

has [qw(_required_mysql _required_pg)];

our $VERSION = '0.01';

sub new_connection {
    my ($self, $database, @options) = @_;

    my ($package, $constructor);
    my $scheme = $self->scheme;
    if ($scheme eq 'mariadb' or $scheme eq 'mysql') {
        $package = 'Mojo::mysql';
        $constructor = $self->strict_mode ? 'strict_mode' : 'new';

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

    return $package->$constructor($self->_to_url($database, @options)->to_unsafe_string);
}

sub _to_url {
    my ($self, $database, @options) = @_;

    my $url =
        Mojo::URL->new
                 ->scheme($self->scheme)
                 ->userinfo($self->userinfo)
                 ->host($self->host)
                 ->port($self->port)
                 ->path($database)
                 ;
    $url->query(@options);

    return $url;
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

=head1 DESCRIPTION

L<Mojo::DB::Connector> is a thin wrapper around L<Mojo::mysql> and L<Mojo::Pg> that is
useful when you want to connect to different databases on the same server using the same
connection info. It also allows you to easily connect using different settings in
different environments by using environment variables to connect (see L</ATTRIBUTES>).
This can be useful when developing using something like L<Docker|https://www.docker.com/>,
which easily allows you to set different environment variables in dev/prod.

See L<Mojo::DB::Connector::Role::Cache> for the ability to cache connections.

=head1 ATTRIBUTES

=head2 scheme

  my $scheme = $connector->scheme;
  $connector = $connector->scheme('postgresql');

The L<Mojo::URL/scheme> that will be used for generating the connection URL.
Allowed values are L<mariadb|DBD::MariaDB>, L<mysql|DBD::mysql>, and L<postgresql|DBD::Pg>. The scheme
will determine whether a L<Mojo::mysql> or L<Mojo::Pg> instance is returned. C<mariadb> and C<mysql>
indicate L<Mojo::mysql>, and C<postgresql> indicates L<Mojo::Pg>.

This can also be set with the environment variable C<MOJO_DB_CONNECTOR_SCHEME>.

Default is C<$ENV{MOJO_DB_CONNECTOR_SCHEME}> and falls back to C<postgresql>.

=head2 userinfo

  my $userinfo = $connector->userinfo;
  $connector   = $connector->userinfo('sri:s3cret');

The L<Mojo::URL/userinfo> that will be used for generating the connection URL.

This can also be set with the environment variable C<MOJO_DB_CONNECTOR_USERINFO>.

Default is C<$ENV{MOJO_DB_CONNECTOR_USERINFO}> and falls back to no C<userinfo> (empty string).

=head2 host

  my $host   = $connector->host;
  $connector = $connector->host('localhost');

The L<Mojo::URL/host> that will be used for generating the connection URL.

This can also be set with the environment variable C<MOJO_DB_CONNECTOR_HOST>.

Default is C<$ENV{MOJO_DB_CONNECTOR_HOST}> and falls back to C<localhost>.

=head2 port

  my $port   = $connector->port;
  $connector = $connector->port(5432);

The L<Mojo::URL/port> that will be used for generating the connection URL.

This can also be set with the environment variable C<MOJO_DB_CONNECTOR_PORT>.

Default is C<$ENV{MOJO_DB_CONNECTOR_PORT}> and falls back to C<5432>.

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

  my $connection = $connector->new_connection('my_database');
  my $results    = $connection->db->query(...);

  # use options
  my $connection = $connector->new_connection('my_database', PrintError => 1, RaiseError => 0);
  my $results    = $connection->db->query(...);

L</new_connection> creates a new connection (L<Mojo::mysql> or L<Mojo::Pg> instance) using
the connection info in L</ATTRIBUTES>.

L</new_connection> requires a database name, and accepts optional options to be passed as
key/value pairs. See L<Mojo::mysql/options> or L<Mojo::Pg/options>.

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

