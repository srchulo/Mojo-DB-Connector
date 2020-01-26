use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;

note 'Test defaults with no $ENV';
my $connector = Mojo::DB::Connector->new;
is $connector->scheme, 'postgresql', 'postgresql is default scheme';
is $connector->userinfo, '', 'empty string is default userinfo';
is $connector->host, 'localhost', 'localhost is default host';
is $connector->port, 5432, '5432 is default port';
is $connector->strict_mode, 1, '1 is default strict_mode';

note 'Test defaults with $ENV';
$ENV{MOJO_DB_CONNECTOR_SCHEME} = 'mariadb';
$ENV{MOJO_DB_CONNECTOR_USERINFO} = 'sri:s3cret';
$ENV{MOJO_DB_CONNECTOR_HOST} = 'batman.com';
$ENV{MOJO_DB_CONNECTOR_PORT} = '3306';
$ENV{MOJO_DB_CONNECTOR_STRICT_MODE} = 0;

my $env_connector = Mojo::DB::Connector->new;
is $env_connector->scheme, 'mariadb', 'mariadb is default scheme';
is $env_connector->userinfo, 'sri:s3cret', 'sri:s3cret is default userinfo';
is $env_connector->host, 'batman.com', 'batman.com is default host';
is $env_connector->port, 3306, '3306 is default port';
is $env_connector->strict_mode, 0, '0 is default strict_mode';

done_testing;
