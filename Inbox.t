use lib '../lib';
use Test::More tests => 13;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;
my $message_body = 'this is my message body, it just keeps going and going and going';
$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name.', Some Guy', 'my subject', $message_body]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'send message works');
is($result->{result}{message}{unknown}[0], 'Some Guy', 'detecting unknown recipients works');

$result = $tester->post('inbox','view_inbox', [$session_id, { tags=>['Tutorial'] }]);
is(scalar(@{$result->{result}{messages}}), 1, 'fetching by tag works');

$result = $tester->post('inbox','view_inbox', [$session_id]);
is($result->{result}{message_count}, 6, 'message_count works');
ok($result->{result}{messages}[0]{subject}, 'view inbox works');
my $message_id = $result->{result}{messages}[0]{id};
$result = $tester->post('empire','get_status', [$session_id]);
is($result->{result}{empire}{has_new_messages}, 6, 'new message count works');

$result = $tester->post('inbox', 'read_message', [$session_id, $message_id]);
is($result->{result}{message}{id}, $message_id, 'can view a message');

$result = $tester->post('inbox','view_sent', [$session_id]);
is(scalar(@{$result->{result}{messages}}), 0, 'should not see messages i sent myself in sent');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$message_id]]);
is($result->{result}{success}[0], $message_id, 'archiving works');

$result = $tester->post('inbox','view_archived', [$session_id]);
is($result->{result}{messages}[0]{id}, $message_id, 'view archived works');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$message_id,'adsfafdsfads']]);
is($result->{result}{failure}[0], $message_id, 'archived messages cannot be archived again');
is($result->{result}{failure}[1], 'adsfafdsfads', 'unknown messages cannot be archived');

$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name, 'my subject', "foo\n\nbar"]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'you can send a message with double carriage return');



END {
    $tester->cleanup;
}
