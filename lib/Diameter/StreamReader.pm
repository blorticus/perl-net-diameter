package Diameter::StreamReader;

use strict;
use warnings;

use Diameter::Message;


=head1 NAME

Diameter::StreamReader - A Diameter reader interface

=head1 SYNOPSIS

 $r = Diameter::StreamReader->new();

 $bool = $r->is_diameter_stream( $octet_stream ); 

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

B<is_diameter_stream> indicates whether the provided I<$octet_stream>
appears to be (at least) the start of a valid message.  To be reliable,
there must be at least 8 bytes.  It doesn't necessarily indicate that
I<$octet_stream> is a complete message.

=cut


use constant {
    SR_ACCUMULATED_STREAM   => 0,   # string; must not be undef
    SR_LAST_ERROR           => 1,   # string; undef if no error
};


sub new {
    my $class = shift;

    return [
        "",
        undef,
    ], $class;
}


# $m = $self->_extract_next_message_from_accumulated_stream();
#
# Attempt to extract a message from the accumulated stream.  If the
# stream is not valid, return undef and set $self->[SR_ACCUMULATED_STREAM]
# appropriately.  If the stream is not a complete message, return the
# empty string.  Otherwise, return the next message and remove the bytes
# from the message from $self->[SR_ACCUMULATED_STREAM]
#
sub _extract_next_message_from_accumulated_stream {
    my $self = shift;
    $self->[SR_LAST_ERROR] = undef;

    if (length $self->[SR_ACCUMULATED_STREAM] < 20) {
        return ();
    }

    my ($hdr1, $hdr2) = unpack( "NN", $self->[SR_ACCUMULATED_STREAM] );

    if (($hdr1 & 0xff0000) >> 24 != 1) {
        $self->[SR_LAST_ERROR] = "Invalid Message Exception: first byte is not 0x01";
        return undef;
    }

    if (($hdr2 & 0x0f000000) != 0) {
        $self->[SR_LAST_ERROR] = "Invalid Message Exception: low order nibble of high order byte is second word is not zero";
        return undef;
    }

    my $msg_length = $hdr1 & 0x00ffffff;

    if ($msg_length <= length( $self->[SR_ACCUMULATED_STREAM] )) {
        my $message;
        if (eval { $message = Diameter::Message->decode( substr $self->[SR_ACCUMULATED_STREAM], 0, $msg_length, "" ) } == undef) {
            $self->[SR_LAST_ERROR] = "Invalid Message Exception: $@";
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

    $self->[SR_LAST_ERROR] = undef;
    $self->[SR_ACCUMULATED_STREAM] .= $incoming;

    my @messages;
    my $nm;
    while ($nm = $self->_extract_next_message_from_accumulated_stream()) {
        push @messages, $nm;
    }

    if (!defined $nm) {
        return ();
    } else {
        return @messages;
    }
}


sub read_failed {
    return defined shift->[SR_LAST_ERROR];
}


sub is_diameter_stream {
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
