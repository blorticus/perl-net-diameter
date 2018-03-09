package Diameter::Dictionary;

use YAML::XS;
$YAML::XS::LoadBlessed = 0;

use strict;
use warnings;

use FileHandle;

#
# $d = Diameter::Dictionary->new( FromFile => $filepath, FromString => $string );
# $m = $d->message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid), Avps => [ $d->avp( $name, $value ), ... ] ) or die $@;
# %v = $d->describe_message( Name => $name | Code => $code | (Code => $code, ApplicationId => $appid );
# %v = $d->describe_avp( Name => $name | Code => $code | (Code => $code, VendorId => $vendorid) ); 
#

#
# MessageTypes:
#    - Code: 272
#      ApplicationId: 0
#      Proxiable: false
#      Request:
#          Names: ["Capabilities-Exchange-Request", "CER"]
#          AvpOrder: ["..."]
#          MandatoryAvps: ["..."]
#          OptionalAvps: ["..."]
#      Answer:
#          Names: ["Capabilities-Exchange-Request", "CER"]
#          AvpOrder: ["..."]
#          MandatoryAvps: ["..."]
#          OptionalAvps: ["..."]
#
# AvpTypes:
#    - Code: 264
#      VendorId: 0
#      Name: "Origin-Host"
#      Type: "DiamIdent"
#

use constant {

};


sub new {
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

    $class->_validate_yaml_datastructure( $yaml_ds )
        or do {
            $@ = "YAML parse error: $@";
            return undef;
        };

    return bless [

    ], $class;
}


sub _validate_yaml_datastructure {
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

    if (exists $yaml_ds->{MessageTypes}) {
        if (!defined $yaml_ds->{MessageTypes}) {
            $yaml_ds->{MessageTypes} = [];
        }

        if (!ref $yaml_ds->{MessageTypes} && $yaml_ds->{MessageTypes} ne "") {
            $@ = "MessageType is not a list";
            return $@;
        }
        else {
            if (ref $yaml_ds->{MessageTypes} ne "ARRAY") {
                $@ = "MessageType is not a list";
                return undef;
            }

            foreach my $message_type (@{ $yaml_ds->{MessageTypes} }) {

            }
        }
    }

    if (exists $yaml_ds->{AvpTypes}) {

    }

    return 1;
}


sub message {

}

sub avp {

}

sub describe_message {

}

sub describe_avp {

}


1;
