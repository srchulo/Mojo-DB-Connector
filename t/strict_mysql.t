use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;

plan skip_all => q{TEST_MYSQL=mysql://root@/test}
    unless $ENV{TEST_MYSQL};

my $url = Mojo::URL->new($ENV{TEST_MYSQL});
my $database = $url->path;
my $connector = Mojo::DB::Connector->new;

$connector->$_($url->$_) for qw(scheme userinfo host port);

$connector->strict_mode(1);
my $connection = $connector->new_connection($database);
ok $connection->{strict_mode}, 'strict mode set';

$connector->strict_mode(0);
$connection = $connector->new_connection($database);
ok !$connection->{strict_mode}, 'strict mode not set';

done_testing;
