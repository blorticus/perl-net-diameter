package Diameter::Dictionary;

use YAML::XS;
$YAML::XS::LoadBlessed = 0;

use strict;
use warnings;

use FileHandle;
use Storable qw[dclone];


=head1 NAME

Diameter::Dictionary - A dictionary interface for Diameter and Diameter AVP objects

=head1 SYNOPSIS

 $d = Diameter::Dictionary->from_yaml( File => $path_to_yaml );

 $m = $d->message( Name => "CER", Avps => [
    $d->avp( Name => "Origin-Host", "test.example.com" ),
    OriginRealm => "example.com",
    ...
 ] );

 $msg_name = $m->name;
 $msg_an   = $m->abbreviated_name;

 $avp_name = $m->avps->[0]->name;

 \%info = $d->describe_message( ApplicationId => 16777232, Code => 520 );
 \%info = $d->describe_avp( Name => "Host-IP-Address" );

 $e = $d->expand_message( $message );
 $e = $d->expand_avp( $message );

 $bool = $d->is_expanded_message( $message );
 $bool = $d->is_expanded_avp( $avp );

=head1 DESCRIPTION

This package provides an interface to a Diameter dictionary.  A dictionary
describes Diameter message structures and AVP structures.  While this is
intended to be a generic interface, allowing many different types of dictionary
information encoding, currently only a YAML dictionary is defined.  The
schema for this is described below, in the section B<YAML SCHEMA>.

B<from_yaml> reads a YAML file (if B<File> is supplied) or a YAML string
(if B<String> is provided).  The YAML is validated.  If an error is encountered,
the parser stops, set I<$@> and returns I<undef>.

If the YAML is valid, a B<Diameter::Dictionary> object is returned.  This object
can be used to create B<Diameter::Message> objects as follows:

 $m = $d->message( Name => $message_name, Avps => \@avps )
 $m = $d->message( Code => $command_code, Avps => \@avps )
 $m = $d->message( ApplicationId => $appid, Code => $command_code, Avps => \@avps )

When B<Code> is provided (with or without B<ApplicationId>), B<IsRequest> may also be
provided.  It defaults to true.

If the identified message type is not defined in the dictionary, set I<$@> and return I<undef>

The dictionary supplies the mandatory AVPs, optional AVPs, and the AVP order.  The
supplied I<@avps> can be in two forms: either a B<Diameter::Message::AVP> object
(usually created by using B<Diameter::Dictionary>-E<gt>B<avp>), or AVP normalized name
followed by a typed value.  The B<SYNOPSIS> section shows an example of this.  These
may be freely mixed.  The normalized name is the dictionary name for the AVP, with any
character outside the set [A-Za-z0-9] removed.

The AVPs will be re-ordered according to the dictionary order for this message type.  If
any mandatory AVPs are missing, I<$@> is set and I<undef> is returned.  The AVPs must
also conform to the count requirements in the dictionary.

If B<message> is passed B<ValidateAvps> and it is set to a false value, then AVPs are
not checked and are not re-ordered.

B<Diameter::Message::AVP> objects can also be created directly, as follows:

 $avp = $d->avp( Name => $name, Value => $type_value )
 $avp = $d->avp( Code => $avp_code, Value => $type_value )
 $avp = $d->avp( VendorId => $vendor_id, Code => $avp_code, Value => $type_value )

If the specified AVP is not in the dictionary, set I<$@> and return I<undef>.  The
data type is retrieved from the dictionary.

The objects returned by B<message> and B<avp> are actually sub-types of B<Diameter::Message> and
B<Diameter::Message::AVP>, respectively.  The first adds the methods B<name> and B<abbreviated_name>,
which return those values as defined in the dictionary.  The second adds the method B<name>.

B<describe_message> and B<describe_avp> return a hashref of information about a message type
and an AVP type, respectively.  For B<describe_message>, the message type can be specified as any
one of:

 \%info = $d->describe_message( Name => $name )
 \%info = $d->describe_message( Code => $command_code )
 \%info = $d->describe_message( ApplicationId => $appid, Code => $command_code )

When B<Code> is provided (with or without B<ApplicationId>), B<IsRequest> may also be
provided.  It defaults to false.

If I<$command_code> is given but I<$appid> is not, then I<$appid> is assumed to be 0.

For B<describe_avp>, the AVP type can be specified as any of:

 \%info = $d->describe_avp( Name => $name )
 \%info = $d->describe_avp( Code=> $avp_code )
 \%info = $d->describe_avp( VendorId => $vendor_id, Code => $avp_code )

If I<$avp_code> is given but I<$vendor_id> is not, then I<$vendor_id> is assumed to be 0.

For B<describe_message>, the returned hashref contains the following elements:

=over 4

=item B<Code>

The command code.

=item B<Name>

The name for the message.

=item B<AbbreviatedName>

The abbreviated name for the message, or the empty string is one is not defined.
For example, the B<Name> of a message might be I<Capabilities-Exchange-Request>
and the B<AbbreviatedName> might be I<CER>.

=item B<ApplicationId>

The application-id for this message type.

=item B<MandatoryAvps>

A hashref indexed by "I<$vendor_id>:I<$avp_code>" values for the mandatory AVPs related
to this message type.  The value of each element is the count, which may be '*' (meaning zero
or more), an integer, meaning an exact number, or an integer followed by '*',
meaning that number or more.

=item B<OptionalAvps>

A hashref indexed by "I<$vendor_id>:I<$avp_code>" values for the mandatory AVPs related
to this message type.  A special value is "AVP", which means any AVP.  The
value of each element is the count, which may be '*' (meaning zero or more), an integer,
meaning an exact number, or an integer followed by '*', meaning that number or
more.

=item B<AvpOrder>

A listref of "I<$vendor_id>:I<$avp_code>" values for the required order of AVPs.

=back

For B<describe_message>, the returned hashref contains the following elements:

=over 4

=item B<Code>

The AVP code.

=item B<VendorId>

The vendor-id for the AVP.

=item B<Name>

The unique name for the AVP.

=item B<Type>

The data type for the AVP.

=back

A plain B<Diameter::Message> or plain B<Diameter::Message::AVP> object can be expanded with
meta-data from the dictionary (including creation of correct TypedData field for an AVP) by
using B<expand_message> and B<expand_avp>, respectively.  In either case, if the corresponding
type is not defined in the dictionary, then the plain message or AVP is returned.  If an error
occur, set I<$@> and return undef.

For efficiency, both of these methods work on the original message or AVP object, changing its
type.

With B<expand_message>, additional parameters can be passed:

 $m = $d->expand_message( $message, ExpandAvps => 1, StopOnError => 0 );

If B<ExpandAvps> is set to true (the default), then an attempt is made to execute B<expand_avp>
on each of the message AVPs.  If B<StopOnError> is false (the default), then on AVP expansion,
if an error occurs, an effort will be made to continue expanding subsequent AVPs.  I<$@> will
equal the last expansion error. If B<StopOnError> is true, then on AVP expansion, if an error
occurs, the expansion process will stop and I<$@> will be the error that halted the expansion.

On AVP expansion, the AVPs are not re-ordered, and the mandatory flag is not changed.

To determine whether an object of type B<Diameter::Message> or B<Diameter::AVP> has been expanded
by a dictionary, use B<is_expanded_message> and B<is_expanded_avp>, respectively.  An expanded
message isn't just one created by B<expand_message> and B<expand_avp>.  It is also any message
created by B<message> and any AVP created by B<avp>.

=head1 YAML SCHEMA

A YAML definition must have this basic structure:

 ---
 MessagesTypes:
   ...

 AvpTypes:
   ...

It is possible to omit one of the two Types definitions, but
at least one must be present.

B<MessageTypes> is a YAML list of YAML maps.  Each map is:

 - Code: <code>
   ApplicationId: <app_id>
   Request:
      Name: <name>
      AbbreviatedName: <aname>
      Proxiable: <is_proxiable>
      AvpOrder:
        ...
      MandatoryAvps:
        ...
      OptionalAvps:
        ...
   Answer:
      Name: <name>
      AbbreviatedName: <aname>
      Proxiable: <is_proxiable>
      AvpOrder:
        ...
      MandatoryAvps:
        ...
      OptionalAvps:
        ...

If B<ApplicationId> is absent, it defaults to 0.  If B<Proxiable> is absent, it
defaults to 'true'.  B<Request> and B<Answer> are required.  Under each,
B<Name> is required, but B<AbbreviatedName> is not.  Both values must be unique
among all messages (this applies to B<AbbreviatedName> only when it is defined,
of course).  B<MandatoryAvps> and B<OptionalAvps> are lists of
"<avp-name>:<count>" or just "<avp-name>".  If it is just "<avp-name>", count
is assumed to be "1" for B<MandatoryAvps> and "*" for B<OptionalAvps>.  A named
AVP MUST be defined elsewhere in the dictionary.

B<AvpOrder> is a list of AVP names, in the order in which the AVPs must appear.

B<AvpTypes> is a YAML list of YAML maps.  Each map is:

 - Code: <code>
   VendorId: <vendor-id>
   Type: <data-type>
   Name: <avp-name>

If B<VendorId> is absent, it is assumed to be 0.  If B<Type> is absent, it is
assumed to be "OctetString".  B<Type> must be one of: Address,
DiameterIdentity, DiameterURI, Enumerated, Float32, Float64, Grouped, Integer32,
Integer64, OctetString, Time, Unsigned32, Unsigned64, UTF8String.  B<Code> and
B<Name> are required.  B<Name> must be unique among all defined AVPs.

=cut


use constant {
    E_IS_REQUIRED       => 0,
    E_TYPE              => 1,
    E_DEFAULT_VALUE     => 2,
    E_CHILDREN          => 3,
};


# This describes what the serialized YAML datastructure (that is, the one created
# by YAML::XS from a YAML file/string) must look like.  Each element has a root
# name, and points to a listref.  That listref has the elements as noted above in
# the E_* constants: (0) is the element required at this location of the structure
# hierarchy?; (1) what is the required type for the value of this element (uint32,
# bool, map [hashref], list [listref], enum; (2) if this is not a required field,
# what is the default value (undef if there is no default, and the element is not
# auto-populated)?; (4) if the type is 'map', what are the child elements, and if the
# type is 'enum', what are the permitted string values?
#
# If the value for E_IS_REQUIRED is undef, and it is an element of a Map, and
# if no value is defined, then the element is not created in the resulting hashref
#
my %element_structure = (
    MessageTypes => [0, 'list', [], [1, 'map', {}, {
            ApplicationId => [0, 'uint32', 0],
            Code          => [1, 'uint32', undef],
            Request       => [0, 'map', {}, {
                Name            => [1, 'string', undef],
                AbbreviatedName => [0, 'string', ''],
                Proxiable       => [0, 'bool', 1],
                AvpOrder        => [0, 'list', []],
                MandatoryAvps   => [0, 'list', []],
                OptionalAvps    => [0, 'list', []],
            }],
            Answer        => [0, 'map', {}, {
                Name            => [1, 'string', undef],
                AbbreviatedName => [0, 'string', ''],
                Proxiable       => [0, 'bool', 1],
                AvpOrder        => [0, 'list', []],
                MandatoryAvps   => [0, 'list', []],
                OptionalAvps    => [0, 'list', []],
            }],
        }],
    ],
    AvpTypes => [0, 'list', [], [1, 'map', {}, {
            Code        => [1, 'uint32', undef],
            VendorId    => [0, 'uint32', 0],
            Name        => [1, 'string', undef],
            Type        => [0, 'enum', 'OctetString', [qw(Address DiameterIdentity DiameterURI Enumerated Float32 Float64
                                                          Grouped Integer32 Integer64 IPFilterRule OctetString QosFilterRule
                                                          Time Unsigned32 Unsigned64 UTF8String)]],
        }],
    ],
);


use constant {
    DD_AVPS         => 0,   # hashref, as described in output from _process_yaml_ds_to_avp_pointers
    DD_MSGS         => 1,   # hashref, as described in output from _process_yaml_ds_to_message_pointers
};


sub from_yaml {
    my $class = shift;
    my %params = @_;

    my $yaml_string;

    if (exists $params{FromFile} && defined $params{FromFile} && $params{FromFile} ne "") {
        if (!-f $params{FromFile}) {
            $@ = "File ($params{FromFile}) does not exist";
            return undef;
        }
        if (!-R $params{FromFile}) {
            $@ = "File ($params{FromFile} is not readable";
            return undef;
        }

        my $fh = new FileHandle $params{FromFile}
            or do {
                $@ = "Failed to open file ($params{FromFile}) for reading: $!";
                return undef;
            };

        $yaml_string = join "", (<$fh>);

        $fh->close;
    }
    elsif (exists $params{FromString} && defined $params{FromString}) {
        $yaml_string = $params{FromString};
    }
    else {
        $@ = "Invalid paramaters";
        return undef;
    }

    my $yaml_ds = Load $yaml_string
        or do {
            $@ = "Invalid yaml: $@";
            return undef;
        };


    # Validate structure of YAML file/string against structure defined above in %element_structre.
    # Also fill in any optional fields that have a default if they aren't present
    $class->_validate_and_expand_yaml_datastructure( $yaml_ds )
        or do {
            $@ = "YAML parse error: $@";
            return undef;
        };


    # Convert serialized YAML datastructure into two hashrefs to facilitate common operations (looking
    # up message and avp structure information)
    my $avp_ptrs_hr = $class->_process_yaml_ds_to_avp_pointers( $yaml_ds )
        or return undef;

    my $msg_ptrs_hr = $class->_process_yaml_ds_to_message_pointers( $yaml_ds, $avp_ptrs_hr )
        or return undef;

    return bless [
        $avp_ptrs_hr,
        $msg_ptrs_hr,
    ], $class;
}


# $avp_ar = $self->_inflate_avps_parameter_for_message( \@avp_defs );
#
# Given a set of AVPs as provided to the Avps parameter of the message()
# method, convert any label => value pairs into a Diameter::Dictionary::Message::AVP
# object.  Step through Grouped AVPs and do the same.
#
# Return the list of AVP objects, or undef on error.  $@ also set on error
#
sub _inflate_avps_parameter_for_message {
    my $self = shift;
    my $avp_defs_ar = shift;

    my @avps;

    # Avps can be a Diameter::AVP object, or a Label, or a Value.  A Value must
    # always follow a Label, and a Label must always follow a Value or an object.
    # An object must only follow a Value.
    # A Value can be a listref, which is Grouped AVP set
    my $last_item = "Value";
    my $last_label = "";

    foreach my $avp_def (@{ $avp_defs_ar }) {
        if (ref $avp_def) {
            if (UNIVERSAL::isa($avp_def, 'Diameter::Message::AVP')) {
                if ($last_item eq "Object" || $last_item eq "Value") {
                    push @avps, $avp_def;

                    $last_item = "Object";
                }
                else {
                    $@ = "Invalid Parameter Exception: object follows label in Avps definition";
                    return undef;
                }
            }
            elsif (ref $avp_def eq "ARRAY") {
                unless ($last_label ne "Label") {
                    $@ = "Invalid Parameter Exception: listref must be a value";
                    return undef;
                }
                
                my $subavp_ar = $self->_inflate_avps_parameter_for_message( $avp_def )
                    or return undef;

                 if (!exists $self->[DD_AVPS]->{ReducedName}->{$last_label}) {
                    $@ = "Unknown AVP Exception: $last_label";
                    return undef;
                }

                my $avp_hr = $self->[DD_AVPS]->{ReducedName}->{$last_label};

                unless ($avp_hr->{Type} eq "Grouped") {
                    $@ = "AVP Type Exception: grouped data provided to ungrouped AVP (${\$avp_hr->{Name}})";
                    return undef;
                }

                my $avp = Diameter::Dictionary::Message::AVP->new(
                    Name        => $avp_hr->{Name},
                    Code        => $avp_hr->{Code},
                    VendorId    => $avp_hr->{VendorId},
                    DataType    => "Grouped",
                    Data        => $subavp_ar,
                ) or return undef;  # $@ already set in Diameter::Dictionary::Message::AVP::new

                push @avps, $avp;

                $last_item = "Value";
            }
            
        }
        elsif (!ref $avp_def) {
            if ($last_item eq "Object" || $last_item eq "Value") {
                $last_label = $avp_def;
                $last_item = "Label";
            }
            else {
                if (!exists $self->[DD_AVPS]->{ReducedName}->{$last_label}) {
                    $@ = "Unknown AVP Exception: $last_label";
                    return undef;
                }

                my $avp_hr = $self->[DD_AVPS]->{ReducedName}->{$last_label};

                my $avp = Diameter::Dictionary::Message::AVP->new(
                    Name        => $avp_hr->{Name},
                    Code        => $avp_hr->{Code},
                    VendorId    => $avp_hr->{VendorId},
                    DataType    => $avp_hr->{Type},
                    Data        => $avp_def,
                ) or return undef;  # $@ already set in Diameter::Dictionary::Message::AVP::new

                push @avps, $avp;

                $last_item = "Value";
            }
        }
        else {
            $@ = "Invalid Parameter Exception: in Avps, refs must be Diameter::AVP objects";
            return undef;
        }
    }

    return \@avps;
}


# $bool = $self->_validate_avp_set_for_message( \%msg_desc, \@avps )
#
# %msg_desc is the descriptor information about the message to which
# the AVP information is attached.  It comes from
# $self->[DD_MSGS]->{Code}->{"$application_id:$code"}->[$x].
# @avps is a list of Diameter:Message::AVP objects (or objects of
# subtypes). This method determines whether the AVPs are all permitted
# for this message type. Return false and set $@ if not; return true
# otherwise.
#
sub _validate_avp_set_for_message {
    my $self = shift;
    my ($msg_desc_hr, $avps_ar) = @_;

    my %matching_avps;
    foreach my $avp (@{ $avps_ar }) {
        my $vic = $avp->vendor_id . ":" . $avp->code;

        $matching_avps{$vic} = 1;
        if (!exists $msg_desc_hr->{MandatoryAvps}->{$vic} && !exists $msg_desc_hr->{OptionalAvps}->{$vic} && !exists $msg_desc_hr->{OptionalAvps}->{AVP}) {
            $@ = "Invalid AVP Set Exception: AVP with VendorId=(" . $avp->vendor_id . ") and Code (" . $avp->code . ")";
            return 0;
        }
    }

    foreach my $vic (keys %{ $msg_desc_hr->{MandatoryAvps} }) {
        if (!exists $matching_avps{$vic}) {
            $@ = "Invalid AVP Set Exception: missing mandatory AVP with VendorId=(" . (split( /:/, $vic ))[0] . ") and Code (" . (split( /:/, $vic ))[1] . ")";
            return 0;
        }
    }

    return 1;
}


# \@avps = $self = _reorder_avps_and_set_mandatory_flags( \%msg_desc, \@avps )
#
# %msg_desc is the descriptor information about the message to which
# the AVP information is attached.  It comes from
# $self->[DD_MSGS]->{Code}->{"$application_id:$code"}->[$x].
# @avps is a list of Diameter:Message::AVP objects (or objects of
# subtypes). 
#
# For each mandatory element, set the mandatory flag.  Re-order the AVPs according
# to the described order.  Return the altered list of AVPs.
#
sub _reorder_avps_and_set_mandatory_flags {
    my $self = shift;
    my ($msg_desc_hr, $avps_ar) = @_;

    my %avps;

    foreach my $avp (@{ $avps_ar }) {
        my $vic = $avp->vendor_id . ":" . $avp->code;

        push @{ $avps{$vic} }, $avp;

        if (exists $msg_desc_hr->{MandatoryAvps}->{$vic}) {
            $avp->_set_mandatory_flag( 1 );
        }
    }

    my @ordered_avps;

    foreach my $vic (@{ $msg_desc_hr->{AvpOrder} }) {
        push @ordered_avps, @{ $avps{$vic} }    if exists $avps{$vic};
    }

    return \@ordered_avps;
}


sub message {
    my $self = shift;
    my %params = @_;

    my $msg_desc_hr;
    my $avps_ordered_ar = [];

    if (exists $params{Name} && defined $params{Name}) {
        if (exists $self->[DD_MSGS]->{Name}->{$params{Name}}) {
            $msg_desc_hr = $self->[DD_MSGS]->{Name}->{$params{Name}};
        }
        else {
            $@ = "No Such Dictionary Entry Exception";
            return undef;
        }
    }
    elsif (exists $params{Code} && defined $params{Code}) {
        if (!exists $params{ApplicationId}) { $params{ApplicationId} = 0 }
        if (!exists $params{IsRequest})     { $params{IsRequest}     = 1 }

        if (exists $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"}) {
            if ($params{IsRequest}) {
                $msg_desc_hr = $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"}->[0];
            }
            else {
                $msg_desc_hr = $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"}->[1];
            }
        }
        else {
            $@ = "No Such Dictionary Entry Exception";
            return undef;
        }
    }
    else {
        $@ = "Invalid Parameter Exception: must have Code, ApplicationId+Code or Name";
        return undef;
    }

    if (exists $params{Avps} && defined $params{Avps}) {
        unless (ref $params{Avps} eq 'ARRAY') {
            $@ = "Invalid Parameter Exception: Avps must be a listref";
            return undef;
        }

        my $avps_ar = $self->_inflate_avps_parameter_for_message( $params{Avps} )
            or return undef;

        $self->_validate_avp_set_for_message( $msg_desc_hr, $avps_ar )
            or return undef;
    
        $avps_ordered_ar = $self->_reorder_avps_and_set_mandatory_flags( $msg_desc_hr, $avps_ar );
    }

    my %ids;
    $ids{HopByHopId} = $params{HopByHopId}  if exists $params{HopByHopId} && defined $params{HopByHopId};
    $ids{EndToEndId} = $params{EndToEndId}  if exists $params{EndToEndId} && defined $params{EndToEndId};

    return Diameter::Dictionary::Message->new(
        %ids,
        ApplicationId   => $msg_desc_hr->{Properties}->{ApplicationId},
        CommandCode     => $msg_desc_hr->{Properties}->{Code},
        Name            => $msg_desc_hr->{Name},
        AbbreviatedName => $msg_desc_hr->{AbbreviatedName},
        IsProxiable     => $msg_desc_hr->{Proxiable},
        IsRequest       => $msg_desc_hr->{Request},
        Avps            => $avps_ordered_ar,
    );
}


sub avp {
    my $self = shift;
    my %params = @_;

    my $avp_desc;
    if (exists $params{Name} && defined $params{Name}) {
        if (exists $self->[DD_AVPS]->{Name}->{$params{Name}}) {
            $avp_desc = $self->[DD_AVPS]->{Name}->{$params{Name}};
        }
        else {
            return undef;
        }
    }
    elsif (exists $params{Code} && defined $params{Code}) {
        my $vendorid = (exists $params{VendorId} && defined $params{VendorId} ? $params{VendorId} : 0);

        if (exists $self->[DD_AVPS]->{Code}->{"$vendorid:$params{Code}"}) {
            $avp_desc = $self->[DD_AVPS]->{Code}->{"$vendorid:$params{Code}"};
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }

    my $is_mandatory = (exists $params{IsMandatory} ? (defined $params{IsMandatory} && $params{IsMandatory} ? 1 : 0) : 0);

    return Diameter::Dictionary::Message::AVP->new( Name     => $avp_desc->{Name},     Code => $avp_desc->{Code},
                                                    VendorId => $avp_desc->{VendorId}, Data => $params{Value},
                                                    DataType => $avp_desc->{Type},     IsMandatory => $is_mandatory );
}


sub describe_message {
    my $self = shift;
    my %params = @_;

    my $msg_hr;
    if (exists $params{Name} && defined $params{Name}) {
        $msg_hr = $self->[DD_MSGS]->{Name}->{$params{Name}};
    }
    elsif (exists $params{Code} && defined $params{Code}) {
        if (!exists $params{ApplicationId}) {
            $msg_hr = $self->[DD_MSGS]->{Code}->{"0:$params{Code}"};
        }
        else {
            $msg_hr = $self->[DD_MSGS]->{Code}->{"$params{ApplicationId}:$params{Code}"};
        }
    }
    else {
        return undef;
    }

    if (!defined $msg_hr) {
        return undef;
    }

    return dclone( $msg_hr );
}


sub describe_avp {
    my $self = shift;
    my %params = @_;

    my $avp_hr;
    if (exists $params{Name}) {
        $avp_hr = $self->[DD_AVPS]->{Name}->{$params{Name}};

    }
    elsif (exists $params{Code}) {
        if (!exists $params{VendorId}) {
            $avp_hr = $self->[DD_AVPS]->{Code}->{"0:$params{Code}"};
        }
        else {
            $avp_hr = $self->[DD_AVPS]->{Code}->{"$params{VendorId}:$params{Code}"};
        }
    }
    else {
        return undef;
    }

    if (!defined $avp_hr) {
        return undef;
    }

    return dclone( $avp_hr );
}


sub expand_message {
    my $self = shift;
    my $unexpanded = shift;
    my %params = @_;

    unless (UNIVERSAL::isa( $unexpanded, 'Diameter::Message' )) {
        $@ = "Invalid Message Exception";
        return undef;
    }

    my $fqcc = $unexpanded->application_id . ":" . $unexpanded->command_code;

    if (!exists $self->[DD_MSGS]->{Code}->{$fqcc}) {
        return $unexpanded;
    }

    my $info_hr;
    if ($unexpanded->is_request) {
        $info_hr = $self->[DD_MSGS]->{Code}->{$fqcc}->{Request};
    }
    else {
        $info_hr = $self->[DD_MSGS]->{Code}->{$fqcc}->{Answer};
    }

    my $expanded_msg = Diameter::Dictionary::Message->from_unexpanded_message( Name => $info_hr->{Name}, AbbreviatedName => $info_hr->{AbbreviatedName}, Unexpanded => $unexpanded );

    my $expand_avps   = (!exists $params{ExpandAvps}  || $params{ExpandAvps} ? 1 : 0);
    my $stop_on_error = (!exists $params{StopOnError} || $params{StopOnError} ? 1 : 0);

    my $had_avp_expansion_error = 0;
    if ($expand_avps) {
        foreach my $avp ($expanded_msg->avps) {
            unless ($self->expand_avp( $avp )) {
                if ($stop_on_error) {
                    return undef;
                }
                else {
                    $had_avp_expansion_error = 1;
                }
            }
        }
    }

    return ($had_avp_expansion_error ? undef : $expanded_msg);
}


sub expand_avp {
    my $self = shift;
    my $unexpanded = shift;

    unless (UNIVERSAL::isa( $unexpanded, 'Diameter::Message::AVP' )) {
        $@ = "Invalid Message Exception";
        return undef;
    }

    my $fqc = $unexpanded->vendor_id . ":" . $unexpanded->code;

    if (!exists $self->[DD_AVPS]->{Code}->{$fqc}) {
        return $unexpanded;
    }

    my $info_hr = $self->[DD_AVPS]->{Code}->{$fqc};

    return Diameter::Dictionary::Message::AVP->from_unexpanded_message( Name => $info_hr->{Name}, DataType => $info_hr->{Type}, Unexpanded => $unexpanded );
}


sub is_expanded_avp {
    my $self = shift;
    my $avp = shift;

    return $avp->can( '_is_from_dictionary' ) && $avp->_is_from_dictionary;
}



sub is_expanded_message {
    my $self = shift;
    my $msg = shift;

    return $msg->can( '_is_from_dictionary' ) && $msg->_is_from_dictionary;
}


#
# \%avp_pointers = $class->_process_yaml_ds_to_avp_pointers( $yaml_ds );
#
# Covert the generated datastructure from the YAML file to a hashref indexed by
# {Code}, {Name} and {ReducedName}.  {Code} is "$vendorid:$code", while {Name} is from the set of
# names for an AVP.  {ReducedName} is the same as {Name} but with any character not
# in the class [A-Za-z0-9] removed.  The value is a hashref of {Code}, {Name}, {VendorId}, {Type}.
# The YAML datastructure must have first been validated.
#
sub _process_yaml_ds_to_avp_pointers {
    my $class = shift;
    my $yaml_ds = shift;

    my %avp_pointers;

    if (!exists $yaml_ds->{AvpTypes}) {
        return { Code => {}, Name => {}, ReducedName => {} };
    }

    foreach my $avp_hr (@{ $yaml_ds->{AvpTypes} }) {
        my ($vendor_id, $code) = ($avp_hr->{VendorId}, $avp_hr->{Code});

        $avp_pointers{Code}{"$vendor_id:$code"} = $avp_hr;

        $avp_pointers{Name}{$avp_hr->{Name}} = $avp_hr;

        my $reduced_name = $avp_hr->{Name};
           $reduced_name =~ s/[^A-Za-z0-9]//g;
        $avp_pointers{ReducedName}{$reduced_name} = $avp_hr;
    }

    return \%avp_pointers;
}


sub _get_normalized_avp {
    my $class = shift;
    my ($avp_id, $avp_ds_hr) = @_;

    if ($avp_id eq "AVP") {
        return "AVP";
    }
    elsif ($avp_id =~ /^(\d+)(:(\d+))?$/) {
        if (!defined $2) {
            $avp_id = "0:$avp_id";
        }
        if ($avp_ds_hr->{Code}->{$avp_id}) {
            return $avp_id;
        }
        else {
            return undef;
        }
    }
    else {
        if (exists $avp_ds_hr->{Name}->{$avp_id}) {
            return $avp_ds_hr->{Name}->{$avp_id}->{VendorId} . ":" . $avp_ds_hr->{Name}->{$avp_id}->{Code};
        }
        else {
            return undef;
        }
    }
}


#
# \%message_pointers = $class->_process_yaml_ds_to_message_pointers( $yaml_ds, $avp_ds );
#
# Convert the generated datastructure from the YAML file to a hashref indexed
# by {Code} and {Name}.  {Code} points to a hashref indexed by
# "$application_id:$code" then listref of [$request, $answer], and {Name} is
# indexed by name.  Value is hashref of {AvpOrder}, which is hashref by
# "$vendorid:$code" of Avp order; then {MandatoryAvps}, which is a hashref by
# "$vendorid:$code"; then {OptionalAvps}, which is a hashref by
# "$vendorid:$code", then {Properties}, which is a hashref of {ApplicationId},
# {Code}, {Name}, {AbbreviatedName} and {Request}.  The value for each
# {"$vendorid:$code"} hashref key is the count when used with {MandatoryAvps}
# and {OptionalAvps}.  For {AvpOrder}, the value is simply 1.
#
# If the AVP in the dictionary is "AVP", then no attempt is made to validate a definition,
# since this mean "any AVP".  It is still stored, however, in the definition for the message
# type.
#
# $avp_ds is the datastructure returned by _process_yaml_ds_to_avp_pointers.  If a referenced
# AVP is not defined in that datastructure, set $@ and return undef.
#
sub _process_yaml_ds_to_message_pointers {
    my $class = shift;
    my ($yaml_ds, $avp_ds) = @_;

    my %message_pointers;

    if (!exists $yaml_ds->{MessageTypes}) {
        return { Code => {}, Name => {} };
    }

    foreach my $message_hr (@{ $yaml_ds->{MessageTypes} }) {
        my ($application_id, $code) = ($message_hr->{ApplicationId}, $message_hr->{Code});

        my %properties = (ApplicationId => $application_id,
                          Code          => $code);

        my %message_ds = (Properties => \%properties);
        my @ra_pair;

        foreach my $s (qw(Request Answer)) {
            my %info = (Properties => \%properties, Request => ($s eq "Request" ? 1 : 0), Proxiable => ($message_hr->{$s}->{Proxiable} ? 1 : 0));

            my @normalized_avps;
            foreach my $refd_avp (@{ $message_hr->{$s}->{AvpOrder} }) {
                my $n = $class->_get_normalized_avp( $refd_avp, $avp_ds )
                    or do {
                        $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/AvpOrder contains AVP ($refd_avp) with no corresponding AVP definition";
                        return undef;
                    };

                push @normalized_avps, $n;
            }

            $info{AvpOrder} = \@normalized_avps;

            foreach my $t (qw(MandatoryAvps OptionalAvps)) {
                my %normalized_avps;

                foreach my $avp_def (@{ $message_hr->{$s}->{$t} }) {
                    my ($refd_avp, $count) = split /:/, $avp_def;

                    if (!defined $count) {
                        $count = 1;
                    }
                    elsif ($count ne "*" && $count ne "1*" && $count ne "1") {
                        $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/$t/$refd_avp count ($count) not understood";
                        return undef;
                    }

                    my $n = $class->_get_normalized_avp( $refd_avp, $avp_ds )
                        or do {
                            $@ = "For ($message_hr->{ApplicationId}:$message_hr->{Code}), $s/AvpOrder contains AVP ($refd_avp) with no corresponding AVP definition";
                            return undef;
                        };

                    $normalized_avps{$n} = $count;
                    $info{$t} = \%normalized_avps;
                }
            }

            push @ra_pair, \%info;
        }

        $ra_pair[0]->{Name} = $message_hr->{Request}->{Name};
        $ra_pair[0]->{AbbreviatedName} = $message_hr->{Request}->{AbbreviatedName};

        $ra_pair[1]->{Name} = $message_hr->{Answer}->{Name};
        $ra_pair[1]->{AbbreviatedName} = $message_hr->{Answer}->{AbbreviatedName};

        $message_ds{Request}    = $ra_pair[0];
        $message_ds{Answer}     = $ra_pair[1];
        $message_ds{Properties} = \%properties;

        $message_pointers{Code}{"$application_id:$code"} = \%message_ds;

        foreach my $name ($message_hr->{Request}->{Name}, $message_hr->{Request}->{AbbreviatedName}) {
            $message_pointers{Name}{$name} = $ra_pair[0]    if $name ne '';
        }

        foreach my $name ($message_hr->{Answer}->{Name}, $message_hr->{Answer}->{AbbreviatedName}) {
            $message_pointers{Name}{$name} = $ra_pair[1]    if $name ne '';
        }
    }

    return \%message_pointers;
}


#
# $bool = $class->_validate_and_expand_yaml_element( $node_name, $value, \@structure_definition );
#
# Given a YAML element from the datastructure created by YAML::XS, validate it against the package global
# %element_structure.  $node_name is a name for the element node, used in error production if the element
# is not valid.  $value is the value of this element.  @structure_definition is the definition for this
# element in %element_structure.
#
sub _validate_and_expand_yaml_element {
    my $class = shift;
    my ($node_name, $element_value, $structure_def_ar) = @_;

    my ($is_required, $required_type, $default_value, $struct_children) = @{ $structure_def_ar };

    my $element_type = ref $element_value;

    if ($required_type eq "bool") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be YAML boolean";
            return 0;
        }
    }
    elsif ($required_type eq "string") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be a YAML string";
            return 0;
        }

        if (!defined $element_value || $element_value eq "") {
            $@ = "For ($node_name) value cannot be empty";
            return 0;
        }
    }
    elsif ($required_type eq "enum") {
        unless (grep { $element_value eq $_ } @{ $structure_def_ar->[E_CHILDREN] }) {
            $@ = "For ($node_name), value ($element_value) is not in the enum list";
            return 0;
        }
    }
    elsif ($required_type eq "uint32") {
        if (ref $element_type) {
            $@ = "For ($node_name) value must be YAML boolean";
            return 0;
        }

        unless ($element_value =~ /^\d+/ && $element_value < 2**32) {
            $@ = "For ($node_name) value must be uint32";
            return 0;
        }
    }
    elsif ($required_type eq "list") {
        unless ($element_type eq "ARRAY") {
            $@ = "For ($node_name) value must be a YAML list";
            return 0;
        }
        if (defined $struct_children) {
            for (my $i = 0; $i < @{ $element_value }; $i++) {
                if (!$class->_validate_and_expand_yaml_element( "$node_name/$i", $element_value->[$i], $struct_children )) {
                    return 0;
                }
            }
        }
    }
    elsif ($required_type eq "map") {
        unless ($element_type eq "HASH") {
            $@ = "For ($node_name) value must be a YAML map";
            return 0;
        }

        if (defined $struct_children) {
            my %child_elements = (map { $_ => 1 } (keys %{ $element_value }));

            CHILD_KEY:
            foreach my $struct_child_key (keys %{ $struct_children }) {
                if (!exists $child_elements{$struct_child_key}) {
                    if ($struct_children->{$struct_child_key}->[E_IS_REQUIRED]) {
                        $@ = "For ($node_name) must have child ($struct_child_key)";
                        return 0;
                    }
                    elsif (defined $struct_children->{$struct_child_key}->[E_IS_REQUIRED] && defined $struct_children->{$struct_child_key}->[E_DEFAULT_VALUE]) {
                        $element_value->{$struct_child_key} = $struct_children->{$struct_child_key}->[E_DEFAULT_VALUE];
                        next CHILD_KEY;
                    }
                    else {
                        next CHILD_KEY;
                    }
                }

                if (!$class->_validate_and_expand_yaml_element( "$node_name/$struct_child_key", $element_value->{$struct_child_key}, $struct_children->{$struct_child_key} )) {
                    return 0;
                }

                delete $child_elements{$struct_child_key};
            }

            my @remaining_keys = keys %child_elements;

            if (@remaining_keys) {
                $@ = "For ($node_name), unknown child element ($remaining_keys[0])";
                return 0;
            }
        }
        elsif (keys %{ $element_value }) {
            $@ = "For ($node_name), there must be no children";
            return 0;
        }
    }

    return 1;
}


#
# $bool = $class->_validate_and_expand_yaml_datastructure( $yaml_serialized_ds );
#
# Given $yaml_serialized_ds -- the output from YAML::XS -- validate that it conforms
# to the definitions in the global %element_structure.  Also, for any optional element
# with a defined default value, if the element is absent in $yaml_serialized_ds, add
# it with the given default
#
sub _validate_and_expand_yaml_datastructure {
    my $class = shift;
    my $yaml_ds = shift;

    if (!defined $yaml_ds || !ref $yaml_ds || ref $yaml_ds ne "HASH") {
        $@ = "Invalid top level structure";
        return 0;
    }

    if (!exists $yaml_ds->{MessageTypes} && !exists $yaml_ds->{AvpTypes}) {
        $@ = "Neither MessageTypes nor AvpTypes defined";
        return 0;
    }

    my $struct_ok = 0;
    if (exists $yaml_ds->{MessageTypes}) {
        if (!defined $yaml_ds->{MessageTypes}) {
            $yaml_ds->{MessageTypes} = [];
            $struct_ok = 1;
        }
        elsif (ref $yaml_ds->{MessageTypes} ne "ARRAY") {
            $@ = "For (MessageTypes), type must be YAML list";
            return 0;
        }
        else {
            $struct_ok = $class->_validate_and_expand_yaml_element( "MessageTypes", $yaml_ds->{MessageTypes}, $element_structure{MessageTypes} );
        }
    }

    if (exists $yaml_ds->{AvpTypes}) {
        if (!defined $yaml_ds->{AvpTypes}) {
            $yaml_ds->{AvpTypes} = [];
            $struct_ok = 1;
        }
        elsif (ref $yaml_ds->{AvpTypes} ne "ARRAY") {
            $@ = "For (AvpTypes), type must be YAML list";
            return 0;
        }
        else {
            $struct_ok = $class->_validate_and_expand_yaml_element( "AvpTypes", $yaml_ds->{AvpTypes}, $element_structure{AvpTypes} );
        }
    }

    return $struct_ok;
}


# I am preserving this bit of code because I may re-introduce it later.  I don't
# currently think that it is sensible to specify the allowed contained AVPs in
# a Grouped AVP -- or rather, that should be a function of MessageType validation --
# but I'm leaving it here in case I re-decide later.
sub _validate_childavps_element {
    my $class = shift;
    my ($node_name, $element_type, $element_value) = @_;

    unless ($element_type eq "ARRAY") {
        $@ = "For ($node_name) value must be a YAML list";
        return 0;
    }

    for (my $i = 0; $i < @{ $element_value }; $i++) {
        my $nv = $element_value->[$i];
        unless (defined $nv && ref $nv eq 'HASH') {
            $@ = "For ($node_name/$i) value must be a YAML map";
            return 0;
        }

        # must have VendorId+Code, Code or Name
        if (exists $nv->{Code} && defined $nv->{Code} && $nv->{Code} ne "") {
            unless ($nv->{Code} =~ /^\d+$/) {
                $@ = "For ($node_name/$i) Code must be a positive integer";
                return 0;
            }
            if (exists $nv->{Name}) {
                $@ = "For ($node_name/$i) cannot have Code and Name together";
                return 0;
            }

            if (exists $nv->{VendorId} && !defined $nv->{VendorId} && $nv->{VendorId} ne "") {
                unless ($nv->{VendorId} =~ /^\d+$/) {
                    $@ = "For ($node_name/$i) VendorId must be a positive integer";
                    return 0;
                }
            }
            else {
                $nv->{VendorId} = 0;
            }
        }
        elsif (!exist $nv->{Name} || !defined $nv->{Name} || $nv->{Name} eq "") {
            $@ = "For ($node_name/$i) VendorId+Code, Code, or Name must be defined";
            return 0;
        }
        elsif (exists $nv->{VendorId}) {
            $@ = "For ($node_name/$i) cannot specify VendorId with Name";
            return 0;
        }

        if (!exists $nv->{Count} || !defined $nv->{Count} || $nv->{Count} eq "") {
            $nv->{Count} = '*';
        }
        elsif ($nv->{Count} ne "*" && $nv->{Count} !~ /^\d+\*?$/) {
            $@ = "For ($node_name/$i) Count must be *, a positive integer, or a positive integer followed by *";
            return 0;
        }
    }

    return 1;
}





# This package provides a sub-type of Diameter::Dictionary::Message::AVP.  It
# adds the name method.
package Diameter::Dictionary::Message::AVP;

use warnings;
use parent 'Diameter::Message::AVP';

use constant {
    SUBTYPE_DATA      => Diameter::Message::AVP::SUBTYPE_DATA,
    TYPE_PACKAGE_NAME => 'Diameter::Message::AVP',

    AVP_NAME     => 0,
};


# Because we know that Diameter::Message::AVP is a blessed listref,
# we extend the listref here, but this means that, if the Diameter::Message::AVP
# listref is changed, it must be changed here, too
#
sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new( %params );

    if (!defined $self) {
        return undef;   # $@ already set in SUPER::new
    }

    bless $self, $class;

    $self->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[AVP_NAME] = $params{Name};

    return $self;
}


# $class->from_unexpanded_message( Name => $name, DataType => $type, Unexpanded => $e );
#
# Constructor from a Diameter::Message::AVP object
#
sub from_unexpanded_message {
    my $class = shift;
    my %params = @_;

    my $self = $params{Unexpanded};

    bless $self, $class;

    $self->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[AVP_NAME] = $params{Name};

    $self->_set_type( $params{DataType} );

    return $self;
}


sub name {
    return shift->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[AVP_NAME];
}


# any type of Diameter::Message::AVP that was expanded by a dictionary MUST include
# this method.  It MUST return a true value.
sub _is_from_dictionary {
    return 1;
}


# This package provides a sub-type of Diameter::Dictionary::Message.  It adds
# the name method and the abbreviated_name method.
package Diameter::Dictionary::Message;

use warnings;
use parent 'Diameter::Message';

use constant {
    SUBTYPE_DATA      => Diameter::Message::AVP::SUBTYPE_DATA,
    TYPE_PACKAGE_NAME => 'Diameter::Message::AVP',
    
    MESSAGE_NAME                => 0,
    MESSAGE_ABBREVIATED_NAME    => 1,
};


sub new {
    my $class = shift;
    my %params = @_;

    my $self = $class->SUPER::new( %params );

    if (!defined $self) {
        return undef;   # $@ already set in SUPER::new
    }

    bless $self, $class;

    $self->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[MESSAGE_NAME] = $params{Name};
    $self->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[MESSAGE_ABBREVIATED_NAME] = $params{AbbreviatedName};

    return $self;
}


# $class->from_unexpanded_message( Name => $name, AbbreviatedName => $a, Unexpanded => $e );
#
# Constructor from a Diameter::Message object
#
sub from_unexpanded_message {
    my $class = shift;
    my %params = @_;

    my $self = $params{Unexpanded};

    bless $self, $class;

    $self->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[MESSAGE_NAME] = $params{Name};
    $self->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[MESSAGE_ABBREVIATED_NAME] = $params{AbbreviatedName};

    return $self;
}



sub name {
    return shift->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[MESSAGE_NAME];
}


sub abbreviated_name {
    return shift->[SUBTYPE_DATA]->{TYPE_PACKAGE_NAME()}->[MESSAGE_ABBREVIATED_NAME];
}


# any type of Diameter::Message that was expanded by a dictionary MUST include
# this method.  It MUST return a true value.
sub _is_from_dictionary {
    return 1;
}





1;
