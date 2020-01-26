use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

test_new_connection($ENV{TEST_MYSQL}) if $ENV{TEST_MYSQL};
test_new_connection($ENV{TEST_POSTGRESQL}) if $ENV{TEST_POSTGRESQL};

done_testing;

sub test_new_connection {
    my $connection_string = shift;

    my $url = Mojo::URL->new($connection_string);
    my $database = $url->path;
    my $connector = Mojo::DB::Connector->new;

    $connector->$_($url->$_) for qw(scheme userinfo host port);

    my $connection = $connector->new_connection($database);
    is $connection->db->query('SELECT 42')->array->[0], 42, 'succesfully connected';

    if ($url->scheme eq 'mysql') {
        $connector->strict_mode(0);

        my $nonstrict_connection = $connector->new_connection($database);
        is $nonstrict_connection->db->query('SELECT 42')->array->[0], 42, 'succesfully connected';
    }
}
