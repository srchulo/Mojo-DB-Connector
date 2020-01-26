use Mojo::Base -strict;
use Test::More;
use Mojo::DB::Connector;
use Mojo::Util 'sha1_sum';

plan skip_all => q{TEST_MYSQL=mysql://root@/test or TEST_POSTGRESQL=postgresql://root@/test}
    unless $ENV{TEST_MYSQL} or $ENV{TEST_POSTGRESQL};

{
    package My::Test::ResultsRole1;
    use Mojo::Base -role;

    has '_bar';

    sub bar {
        my $self = shift;

        $self->_bar($self->array->[0] * 2) unless $self->_bar;
        return $self->_bar;
    }
}

{
    package My::Test::ResultsRole2;
    use Mojo::Base -role;
    requires 'bar';

    sub baz { shift->bar + 1 }
}

test_results_roles($ENV{TEST_MYSQL}) if $ENV{TEST_MYSQL};
test_results_roles($ENV{TEST_POSTGRESQL}) if $ENV{TEST_POSTGRESQL};

done_testing;

sub test_results_roles {
    my $connection_string = shift;

    my $url = Mojo::URL->new($connection_string);
    my $database = $url->path;
    my $connector = Mojo::DB::Connector->new;

    $connector->$_($url->$_) for qw(scheme userinfo host port);

    my $results = $connector->new_connection($database)->db->query('SELECT 42');
    ok !$results->can('bar'), 'My::Test::ResultsRole1 not composed';
    ok !$results->can('baz'), 'My::Test::ResultsRole2 not composed';

    $connector->with_roles('+ResultsRoles');
    push @{ $connector->results_roles }, 'My::Test::ResultsRole1';
    $results = $connector->new_connection($database)->db->query('SELECT 42');
    can_ok $results, 'bar';
    is $results->bar, 84, 'right bar';
    ok !$results->can('baz'), 'My::Test::ResultsRole2 not composed';

    push @{ $connector->results_roles }, 'My::Test::ResultsRole2';
    $results = $connector->new_connection($database)->db->query('SELECT 42');
    can_ok $results, 'bar';
    is $results->bar, 84, 'right bar';
    can_ok $results, 'baz';
    is $results->baz, 85, 'right baz';
}
