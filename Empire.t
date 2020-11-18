use lib '../lib';
use Test::More tests => 12;
use Test::Deep;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Lacuna::DB;
use Data::Dumper;
use 5.010;

my $result;

$result = post('empire', 'is_name_available', ['The Federation']);
is($result->{result}, 1, 'empire name is available');

my $fed = {
    name        => 'The Federation',
    species_id  => 'human_species',
    password    => '123qwe',
    password1   => '123qwe',
};

$fed->{name} = 'XX>';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1000, 'empire name has funky chars');

$fed->{name} = '';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1000, 'empire name too short');

$fed->{name} = 'abc def ghi jkl mno pqr stu vwx yz 0123456789';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1000, 'empire name too long');

$fed->{name} = 'The Federation';
$fed->{password} = 'abc';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1001, 'empire password too short');

$fed->{password} = 'abc123';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1001, 'empire passwords do not match');

$fed->{password} = '123qwe';
$fed->{species_id} = 'xxx';
$result = post('empire', 'create', $fed);
is($result->{error}{code}, 1002, 'empire species does not exist');

$fed->{species_id} = 'human_species';
$result = post('empire', 'create', $fed);
ok(exists $result->{result}{empire_id}, 'empire created');
ok(exists $result->{result}{session_id}, 'empire logged in after creation');
my $fed_id = $result->{result}{empire_id};
my $session_id = $result->{result}{session_id};

$result = post('empire', 'is_name_available', ['The Federation']);
is($result->{result}, 0, 'empire name not available');

$result = post('empire', 'logout', [$session_id]);
is($result->{result}, 1, 'logout');

$result = post('empire', 'login', ['the Federation','123qwe']);
ok(exists $result->{result}, 'login');
$session_id = $result->{result};






sub post {
    my ($url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    my $response = $ua->post('http://localhost:5000/'.$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    return from_json($response->content);
}

END {
    my $db = Lacuna::DB->new(access_key => $ENV{SIMPLEDB_ACCESS_KEY}, secret_key => $ENV{SIMPLEDB_SECRET_KEY}, cache_servers => [{host=>'127.0.0.1', port=>11211}]);
    $db->domain('empire')->find($fed_id)->delete;
    $db->domain('session')->find($session_id)->delete;
}
