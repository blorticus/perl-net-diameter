package Diameter::Logger;

our $VERSION = "1.0";

use strict;
use warnings;
use FileHandle;

=head1 NAME

Diameter::Logger - simple logging interface

=head1 SYNOPSIS

 use Diameter::Logger;
 
 $logger = Diameter::Logger->new
            ->add_destination( Destination => 'file:/var/log/debug.log' )
            ->add_destination( AtLevel => 'WARN', Destination => 'stderr' )
            ->set_level( 'DEBUG' )
            ->prepend_caller
            ->auto_append( "\n" );
 $logger->log_debug( $msg );
 $logger->log_debug( @long_list ) if $logger->would_log_debug;
 $logger->log_die( $msg );
 $logger->raise_exception( $msg );
 $logger->disable_auto_append;

=head1 DESCRIPTION

This provides a very simplistic logging interface for use with the Diameter framework.
A Logger object can be created, and used to send logging information to one or more
destinations based on the configured logging level.  Valid logging levels include
"DEBUG", "INFO", "WARN", and "ERROR", in a ascending order.  Each destination is associated
with a level.  The log methods are B<log_debug>, B<log_info>, B<log_warn>, and B<log_error>.
The message is delivered to any destination associated with that level.  If I<AtLevel> is not provided, then
the destination applies at all levels.

Valid destinations include 'stderr', 'stdout' and 'file:<path>'.  For file: the <path> must
be absolute.  The file will always be appended to.

It is almost certain undesirable to use a destination more than once, but no effort is made
to prevent this.  If a destination is used more than once, the results are undefined.

Sometimes, one wishes to log a message that is quite long, often for debugging.  Although
the log methods return early if the log level is higher than the log message, copying or
expanding values may be time costly.  To avoid this when needed, the methods B<would_log_debug>,
B<would_log_info>, B<would_log_warn> and B<would_log_error> return true if there is at least
one destination the identified log level or higher.

B<log_die> can be invoked to B<log_error> then exit with a non-zero value.  Stack information,
however, is not retained.  Only the message provided is logged.  On the other hand, B<raise_exception>
will send the provided message to B<log_error> then perform a B<die>.  The logged message will
include the B<auto_append> character, but the B<die> will not.

If B<auto_append> is called, each logged message to every destination is terminated with the provided
string.  This can be a convenient way auto-append newlines, for example.  This behavior stops if
B<diabled_auto_append> is invoked.

If B<prepend_caller> is called, each logged message is preceded by the name of the calling
package and method as given by B<caller>, followed by a colon and a space.  This method may optionally
be passed a boolean value to enable or disable this function.

The methods B<add_destination>, B<remove_destination>, B<auto_append> and B<disable_auto_append>
return a reference to the Logger object, so they can be chained together.  The chained methods
will generally B<die> on failure, while B<log_*> will not.

=head1 BLAME

 Vernon Wells (vwells@f5.com)

=head1 VERSIONS

 1.0    [18-Apr-2014]   Initial revision

=cut


my %LOG_LVL_INTEGER_MAP = (
    DEBUG           => 0,
    INFO            => 1,
    WARN            => 2,
    ERROR           => 3,
    NOLOG           => 4,
);

use constant {
    FILEHANDLES_BY_LVL  => 0, # listref by log level integer, value is listref of FileHandle objects that apply at that level.
    DEST_DEFS           => 1, # hashref by "$destination_string:$log_lvl_string", value is log level integer and FileHandle object
    AUTO_APPEND         => 2, # string to auto-append to log messages, or undef if none should be added
    CURRENT_LEVEL       => 3, # current log level
    PREPEND_CALLER      => 4, # 0|1 if prepend_caller
};

sub new {
    my $class = shift;

    return bless [
        [ [], [], [], [] ],
        { },
        undef,
        $LOG_LVL_INTEGER_MAP{NOLOG},
        0,
    ], $class;
}


sub prepend_caller {
    my $self = shift;
    my $bool = shift;

    $bool = (defined $bool && $bool ? 1 : 0);

    $self->[PREPEND_CALLER] = $bool;
}


sub add_destination {
    my $self = shift;
    my %params = @_;

    die "Invalid Destination Exception" unless exists  $params{Destination} && defined $params{Destination} && $params{Destination} ne '';

    if (exists $params{AtLevel}) {
        die "Invalid Level Exception: $params{AtLevel}" if !defined $params{AtLevel} || !exists $LOG_LVL_INTEGER_MAP{$params{AtLevel}};
    }
    else {
        $params{AtLevel} = 'ANY';
    }

    die "Duplicate Destination Exception: $params{Destination}:$params{AtLevel}"
        if exists $self->[DEST_DEFS]->{"$params{Destination}:$params{AtLevel}"};

    my $fh;

    if ($params{Destination} eq 'stderr') {
        $fh = \*STDERR;
    }
    elsif ($params{Destination} eq 'stdout') {
        $fh = \*STDOUT;

        $fh->autoflush(1);
    }
    elsif ($params{Destination} =~ m|^file:(/.+)$|) {
        my $file = $1;
        
        $fh = new FileHandle ">>$file"
            or die "Invalid Destination Exception: cannot open file [$file]: $!";

        $fh->autoflush(1);
    }
    else {
        die "Invalid Destination Exception: $params{Destination}";
    }

    $self->[DEST_DEFS]->{"$params{Destination}:$params{AtLevel}"} = $fh;

    if ($params{AtLevel} eq 'ANY') {
        foreach my $lvl_ar (@{ $self->[FILEHANDLES_BY_LVL] }) {
            push @{ $lvl_ar }, $fh;
        }
    }
    else {
        my $int_lvl = $LOG_LVL_INTEGER_MAP{$params{AtLevel}};
        push @{ $self->[FILEHANDLES_BY_LVL]->[$int_lvl] }, $fh;
    }

    return $self;
}


sub auto_append {
    my $self = shift;
    my $string = shift;

    $self->[AUTO_APPEND] = $string;

    return $self;
}


sub disable_auto_append {
    my $self = shift;
    $self->[AUTO_APPEND] = undef;

    return $self;
}


sub would_log_debug {
    return shift->[CURRENT_LEVEL] <= $LOG_LVL_INTEGER_MAP{DEBUG};
}


sub would_log_info {
    return shift->[CURRENT_LEVEL] <= $LOG_LVL_INTEGER_MAP{INFO};
}


sub would_log_warn {
    return shift->[CURRENT_LEVEL] <= $LOG_LVL_INTEGER_MAP{WARN};
}


sub would_log_error {
    return shift->[CURRENT_LEVEL] <= $LOG_LVL_INTEGER_MAP{ERROR};
}


sub _log {
    my ($self, $of_lvl_int, $msg_sr) = @_;
    return unless $self->[CURRENT_LEVEL] <= $of_lvl_int;
    $$msg_sr .= $self->[AUTO_APPEND]    if defined $self->[AUTO_APPEND];

    foreach my $fh (@{ $self->[FILEHANDLES_BY_LVL]->[$of_lvl_int] }) {
        print $fh $$msg_sr;
    }
}

sub log_debug {
    my ($self, $msg) = @_;
    return $self->_log( $LOG_LVL_INTEGER_MAP{DEBUG}, \$msg );
}


sub log_info {
    my ($self, $msg) = @_;
    return $self->_log( $LOG_LVL_INTEGER_MAP{INFO}, \$msg );

}


sub log_warn {
    my ($self, $msg) = @_;
    return $self->_log( $LOG_LVL_INTEGER_MAP{WARN}, \$msg );

}


sub log_error {
    my ($self, $msg) = @_;
    return $self->_log( $LOG_LVL_INTEGER_MAP{ERROR}, \$msg );
}



sub log_die {
    my ($self, $msg) = @_;
    $self->_log( $LOG_LVL_INTEGER_MAP{ERROR}, \$msg );
    exit 1;
}


sub raise_exception {
    my ($self, $msg) = @_;
    $self->_log( $LOG_LVL_INTEGER_MAP{ERROR}, \$msg );
    die $msg;
}


sub set_level {
    my ($self, $lvl) = @_;

    die "Invalid Log Level: [$lvl]"     unless exists $LOG_LVL_INTEGER_MAP{$lvl};

    $self->[CURRENT_LEVEL] = $LOG_LVL_INTEGER_MAP{$lvl};
}


1;
