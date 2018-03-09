use Test::More tests => 34;

use strict;
use warnings;

BEGIN { use_ok( 'Diameter::Logger' ) };

my $logger;

eval { $logger = Diameter::Logger->new };

cmp_ok( $@, 'eq', '', 'No exception on new()' );

eval { $logger->add_destination( AtLevel => 'Foo', Destination => 'file:/tmp/Logger.t.' . time ) };

cmp_ok( $@, 'ne', '', 'Exception raised when add_destination AtLevel is foo' );

eval { $logger->add_destination( AtLevel => 'INFO', Destination => 'foo' ) };

cmp_ok( $@, 'ne', '', 'Exception raised when add_destination Destination is foo' );

eval { $logger->add_destination( AtLevel => 'INFO', Destination => 'file:Logger.t' ) };

cmp_ok( $@, 'ne', '', 'Exception raised when add_destination Destination is file: that is not absolute path' );

my $tmp_file_1 = '/tmp/Logger.t.' . time() . '1';
unlink $tmp_file_1;
my $tmp_file_2 = '/tmp/Logger.t.' . time() . '2';
unlink $tmp_file_2;

eval {
    $logger = Diameter::Logger->new
                ->add_destination( Destination => "file:$tmp_file_1" )
                ->add_destination( AtLevel => 'WARN', Destination => "file:$tmp_file_2" )
};

cmp_ok( $@, 'eq', '', 'Able to create Logger with two file destinations' );

ok( -f $tmp_file_1, "First file destination created" );
ok( -f $tmp_file_2, "Second file destination created" );

my $file_1_length = (stat $tmp_file_1)[7];
my $file_2_length = (stat $tmp_file_2)[7];

cmp_ok( $file_1_length, '==', 0, 'First file destination file is empty' );
cmp_ok( $file_2_length, '==', 0, 'Second file destination file is empty' );

my $debug_msg = "debug message";
my $info_msg  = "the info message\n";
my $warn_msg  = "warning message, foo";
my $error_msg = "an error msg";


##
## NULL LOGGER
##

$logger->log_debug( $debug_msg );

my $file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
my $file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file is still empty after log_debug on null logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file is still empty after log_debug on null logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_info( $info_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file is still empty after log_info on null logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file is still empty after log_info on null logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_warn( $warn_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file is still empty after log_warn on null logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file is still empty after log_warn on null logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];


$logger->log_error( $error_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file is still empty after log_error on null logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file is still empty after log_error on null logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];


##
## ERROR LEVEL LOGGER
##

$logger->set_level( 'ERROR' );

$logger->log_debug( $debug_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file message not received after log_debug on error logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_debug on error logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_info( $info_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file message not received after log_info on error logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_info on error logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_warn( $warn_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file message not received after log_warn on error logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_warn on error logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_error( $error_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', length $error_msg, 'First file destination file message received after log_error on error logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_error on error logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];


##
## WARN LEVEL LOGGER
##

$logger->set_level( 'WARN' );

$logger->log_debug( $debug_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file message not received after log_debug on warn logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_debug on warn logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_info( $info_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', 0, 'First file destination file message not received after log_info on warn logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_info on warn logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_warn( $warn_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', length $warn_msg, 'First file destination file message received after log_warn on warn logger' );
cmp_ok( $file_2_length_diff, '==', length $warn_msg, 'Second file destination file message received after log_warn on warn logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];

$logger->log_error( $error_msg );

$file_1_length_diff = (stat $tmp_file_1)[7] - $file_1_length;
$file_2_length_diff = (stat $tmp_file_2)[7] - $file_2_length;

cmp_ok( $file_1_length_diff, '==', length $error_msg, 'First file destination file message received after log_error on warn logger' );
cmp_ok( $file_2_length_diff, '==', 0, 'Second file destination file message not received after log_error on warn logger' );

$file_1_length = (stat $tmp_file_1)[7];
$file_2_length = (stat $tmp_file_2)[7];


unlink $tmp_file_1;
unlink $tmp_file_2;
