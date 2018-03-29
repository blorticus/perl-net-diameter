package Diameter::StreamReader;

use strict;
use warnings;

use Diameter::Message;


=head1 NAME

Diameter::StreamReader - A Diameter reader interface

=head1 SYNOPSIS

 $r = Diameter::StreamReader->new();

 $bool = $r->is_start_of_diameter_stream( $octet_stream ); 

 @message = $r->read( $octet_stream );
 if ($r->read_failed) { die $r->error() }

=head1 DESCRIPTION

A B<Diameter::StreamReader> object consumes a byte stream and produces
Diameter messages extracted from that stream. B<read> must be provided
a continuous stream of diameter messages, or it will eventually fail.
If B<read> is provided a partial message, it will return an empty list.
Once enough octets are accumulated for a messge, it will return that.
If the collected stream contains more then one complete message, then
that set will be returned. As additional octets are fed, additional
messages are extracted (or an error is returned if the stream no longer
appears to be a Diameter message or start of a message).

If an error occurs while processing B<read>, B<read_failed> will return
a true value, and B<error> will contain an appropriate error string.

B<is_start_of_diameter_stream> indicates whether the provided I<$octet_stream>
appears to be (at least) the start of a valid message.  To be reliable,
there must be at least 8 bytes.  It doesn't necessarily indicate that
I<$octet_stream> is a complete message, only that it appears to be a
Diameter header.

=cut


use constant {
    ACCUMULATED_STREAM  => 0,   # string; must not be undef
    LAST_ERROR          => 1,   # string; undef if no error
};


sub new {
    my $class = shift;
    my %params = @_;

    return bless [
        "",
        undef,
    ], $class;
}


# $m = $self->_extract_next_message_from_accumulated_stream();
#
# Attempt to extract a message from the accumulated stream.  If the
# stream is not valid, return undef and set $self->[ACCUMULATED_STREAM]
# appropriately.  If the stream is not a complete message, return the
# empty string.  Otherwise, return the next message and remove the bytes
# from the message from $self->[ACCUMULATED_STREAM]
#
sub _extract_next_message_from_accumulated_stream {
    my $self = shift;
    $self->[LAST_ERROR] = undef;

    if (length $self->[ACCUMULATED_STREAM] > 0) {
        if ((substr $self->[ACCUMULATED_STREAM], 0, 1) ne "\x01") {
            $self->[LAST_ERROR] = "Invalid Message Exception: first byte is not 0x01";
            return undef;
        }
    }
    else {
        return "";
    }

    if (length $self->[ACCUMULATED_STREAM] > 3) {
        my $w = unpack "N", substr( $self->[ACCUMULATED_STREAM], 0, 4 );
        if (($w & 0x00ffffff) < 20) {
            $self->[LAST_ERROR] = "Invalid Message Exception: message length less than 20";
            return undef;
        }
    }
    else {
        return "";
    }

    if (length $self->[ACCUMULATED_STREAM] > 4) {
        my $b = unpack( "C", substr( $self->[ACCUMULATED_STREAM], 4, 1 ) );
        if ($b & 0x0f) {
            $self->[LAST_ERROR] = "Invalid Message Exception: low order nibble of high order byte is second word is not zero";
            return undef;
        }
    }
    else {
        return "";
    }

    if (length $self->[ACCUMULATED_STREAM] > 7) {
        my $w = unpack "N", substr( $self->[ACCUMULATED_STREAM], 4, 4 );
        if (($w & 0x00ffffff) == 0) {
            $self->[LAST_ERROR] = "Invalid Message Exception: command code is 0";
            return undef;
        }
    }
    else {
        return "";
    }

    if (length $self->[ACCUMULATED_STREAM] < 20) {
        return "";
    }

    my ($hdr1, $hdr2) = unpack( "NN", $self->[ACCUMULATED_STREAM] );

    my $msg_length = $hdr1 & 0x00ffffff;

    if ($msg_length <= length( $self->[ACCUMULATED_STREAM] )) {
        my $message;
        if (!($message = Diameter::Message->decode( substr $self->[ACCUMULATED_STREAM], 0, $msg_length, "" ))) {
            $self->[LAST_ERROR] = "Invalid Message Exception: $@";
            return undef;
        }
        else {
            return $message;
        }
    }
    else {
        return "";
    }
}


sub read {
    my $self = shift;
    my $incoming = shift;

    $self->[LAST_ERROR] = undef;
    $self->[ACCUMULATED_STREAM] .= $incoming;

    my @messages;
    my $nm;
    while ($nm = $self->_extract_next_message_from_accumulated_stream()) {
        push @messages, $nm;
    }

    if (!defined $nm) {
        # undef if an error occurred on last extraction
        return ();
    } else {
        return @messages;
    }
}


sub read_failed {
    return defined shift->[LAST_ERROR];
}


sub error {
    return shift->[LAST_ERROR];
}


sub is_start_of_diameter_stream {
    my $class_or_self = shift;
    my $stream = shift;

    if (!defined $stream || $stream eq "") {
        return 0;
    }

    if ((substr $stream, 0, 1) != 1) {
        return 0;
    }

    if (length $stream >= 5) {
        if ((substr $stream, 5, 1) & 0x0f) {
            return 0;
        }
    }

    return 1;
}


1;
