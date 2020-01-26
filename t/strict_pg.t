use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::DB::Connector;

plan skip_all => q{TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_POSTGRESQL};

my $url = Mojo::URL->new($ENV{TEST_POSTGRESQL});
my $database = $url->path;
my $connector = Mojo::DB::Connector->new;
$connector->$_($url->$_) for qw(scheme userinfo host port);

lives_and { ok $connector->strict_mode(1)->new_connection($database) } 'strict pg lives';
lives_and { ok $connector->strict_mode(0)->new_connection($database) } 'non-strict pg lives';

done_testing;