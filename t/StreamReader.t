use Test::More;

BEGIN { use_ok 'Diameter::StreamReader' };

my $sr = Diameter::StreamReader->new();

ok( defined $sr && ref $sr, 'Created Diameter::StreamReader without error' );

ok( !$sr->is_start_of_diameter_stream( '' ), 'is_start_of_diameter_stream on empty stream returns false value' );

is_deeply( [$sr->read( '' )], [], 'read() on empty string without any previous content returns empty list' );
ok( !$sr->read_failed, 'read_failed() empty string without any previous content returns false' );

is_deeply( [$sr->read( '' )], [], 'read() on empty string with previous empty string returns empty list' );
ok( !$sr->read_failed, 'read_failed() on empty string with previous empty string returns false' );

is_deeply( [$sr->read( "\x02" )], [], 'read() with first byte invalid returns empty string' );
ok( $sr->read_failed, 'read_failed() with first byte invalid returns true' );
ok( defined $sr->error && $sr->error ne "", 'error() with first byte invalid sets error' );

$sr = Diameter::StreamReader->new();

is_deeply( [$sr->read( pack( "H*", "01000000" ) )], [], 'read() with invalid length returns empty list' );
ok( $sr->read_failed, 'read_failed() returns true with invalid length' );
ok( defined $sr->error && $sr->error ne "", 'error() set on invalid message length' );

$sr = Diameter::StreamReader->new();

is_deeply( [$sr->read( pack( "H*", "01000014" ) )], [], 'read() with valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false with valid first word returns empty list' );

is_deeply( [$sr->read( pack( "H*", "0f000000" ) )], [], 'read() with invalid second word after valid first word returns empty list' );
ok( $sr->read_failed, 'read_failed() returns true on invalid second word after valid first word returns empty list' );
ok( defined $sr->error && $sr->error ne "", 'error() set on invalid second word after valid first word' );

$sr = Diameter::StreamReader->new();

is_deeply( [$sr->read( pack( "H*", "01000014" ) )], [], 'read() with valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false with valid first word returns empty list' );

is_deeply( [$sr->read( pack( "H*", "00000000" ) )], [], 'read() with valid second word after valid first word returns empty list' );
ok( $sr->read_failed, 'read_failed() returns true on invalid second word after valid first word' );
ok( defined $sr->error && $sr->error ne "", 'error() set on invalid second word after valid first word' );

$sr = Diameter::StreamReader->new();

is_deeply( [$sr->read( pack( "H*", "01000014" ) )], [], 'read() with valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false with valid first word returns empty list' );

is_deeply( [$sr->read( pack( "H*", "00000101" ) )], [], 'read() with valid second word after valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false on valid second word after valid first word' );

$sr = Diameter::StreamReader->new();

is_deeply( [$sr->read( pack( "H*", "01000014" ) )], [], 'read() with valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false with valid first word returns empty list' );

is_deeply( [$sr->read( pack( "H*", "00000101" ) )], [], 'read() with valid second word after valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false on valid second word after valid first word' );

$sr = Diameter::StreamReader->new();

is_deeply( [$sr->read( pack( "H*", "01000014" ) )], [], 'read() with valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false with valid first word returns empty list' );

is_deeply( [$sr->read( pack( "H*", "00000101" ) )], [], 'read() with valid second word after valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false on valid second word after valid first word' );

my @m = $sr->read( pack( "H*", "000000000000000100000002" ) );
ok( @m == 1, 'read() with addition of fields for complete simple message returns list with one element' );
ok( !$sr->read_failed, 'read_failed() returns false with addition of fields for complete simple message' );

is_deeply( [$sr->read( pack( "H*", "01000014" ) )], [], 'read() with addition after message of valid first word returns empty list' );
ok( !$sr->read_failed, 'read_failed() returns false with addition after message of valid first word returns empty list' );

is_deeply( [$sr->read( pack( "H*", "00000000" ) )], [], 'read() with invalid second word on simple base message returns empty list' );
ok( $sr->read_failed, 'read_failed() returns true on invalid second word on simple base message returns empty list' );
ok( defined $sr->error && $sr->error ne "", 'error() set on invalid second word on simple base message returns empty list' );

$sr = Diameter::StreamReader->new();

@m = $sr->read( pack( "H*", '01000014000001010000000011223344aabbccdd01000014000001010000000011223344aabbccdd' ) );
ok( @m == 2, 'read() with two simple messages returns two messages' );
ok( !$sr->read_failed, 'read_failed() returns false with two simple messages returns two messages' );


done_testing();
