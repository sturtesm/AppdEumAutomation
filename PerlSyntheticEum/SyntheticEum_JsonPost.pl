#!/usr/bin/perl

use strict;
use warnings;
use UUID::Generator::PurePerl;
use URI::Encode;
use URI::Escape;
use LWP::Simple;


#UUID Generator
my $ug  = UUID::Generator::PurePerl->new();

#URI Encode / Decoder
my $uri = URI::Encode->new( { encode_reserved => 0 } );


#################
#
#  EXAMPLE EUM Beacon:
#
#  /eumcollector/adrum.gif?ky=AD-AAB-AAA-HRD&vr=2&dt=R&cg=8a3aa0a3_b33b_447d_83d4_e92fce0817e8&pu=http%3A%2F%2F275406366.log.optimizely.com%2Fevent%3Fa%3D275406366%26d%3D275406366%26y%3Dfalse%26s278506160%3Dfalse%26s278501250%3Ddirect%26s278501251%3Dff%26n%3Dhttp%253A%252F...&pt=2&bg=7afb6768_fd86_49cd_a66c_df07f500f4a8&mg=7afb6768_fd86_49cd_a66c_df07f500f4a8&mu=http%3A%2F%2Fwww.appdynamics.com%2F&mt=0&pp=1&mn=%7BPLC%3A1%2CFBT%3A251%2CDDT%3A0%2CDPT%3A0%2CPLT%3A251%2CARE%3A0%2C%7D&em=1& HTTP/1.1";
#
#
#  FIELDS:
#   vr=2            The interface version. Always the literal "2".
#   dt=R            DataType.  Always the literal "R"
#   cg=8a3aa0a3_b33b_447d_83d4_e92fce0817e8     GUUID. RFC4122 version 4
#   pu=http%3A%2F%2F275406366.log.optimizely.com%2Fevent%3Fa%3D275406366%26d%3D275406366%26y%3Dfalse%26s278506160%3Dfalse%26s278501250%3Ddirect%26s278501251%3Dff%26n%3Dhttp%253A%252F...       PageURL.  First 180 Characters.  URI Encoded.
#   pt=2            Page Title.  First 50 Characters.  URI Encoded.
#   mu=http%3A%2F%2Fwww.appdynamics.com%2F
#   gc=             Geo Country.  First 30 Characters.  URI Encoded
#   gr=             Geo Region.   First 30 Characters.  URI Encoded
#   gt=             Geo City.     First 30 Characters.  URI Encoded
#   lp=             LocalIP.      Hex Encoded 8 Char String.  Optional.  Can override Local IP.
#   mt=0            ParentPageType.     0=parent is a base page; 1=parent is an iFrame
#   mn=%7BPLC%3A1%2CFBT%3A251%2CDDT%3A0%2CDPT%3A0%2CPLT%3A251%2CARE%3A0%2C%7D  decoded: {PLC:1,FBT:251,DDT:0,DPT:0,PLT:251,ARE:0,} 
#   em=1            End of Message.  Required.
#
##################

sub getURIEncodedString
{
    my $str = shift;

    #return $uri->encode($str);

    return uri_escape($str);
}

sub isUndefined
{
    my $input = shift;

    if (!defined $input || length($input) <= 0) {
        return 1;
    }

    #trim both sides
    $input =~ s/^\s+|\s+$//g;

    if (length($input) <= 0) {
        return 1;
    }
    else {
        return 0;
    }
}

# GET the application key
sub getAppKey
{
    return "ky=AD-AAB-AAA-JJS";
}

# GET the Interface Version, always 2
sub getVR
{
    return "vr=2";
}

# Get the Data Type, always R
sub getDataType 
{
    return "dt=R";
}

# Get the GUUID, RFC4122 version 4
sub getGUUID
{
    my $uuid = $ug->generate_v1();    
    my $guid = $uuid->as_string();

    $guid =~ s/-/_/g;

    return $guid;
}

# Page URL, limited to the first 180 Characters.  URI Encoded.
# 
# IN:  PageURL to decode
# OUT: encoded URL
sub getPageURL
{
    my $url = shift;
    
    if (isUndefined($url) ) {
       $url = "http://www.unknown-url.com";
    }

    my $encodedURL = getURIEncodedString($url);

    return "pu=$encodedURL";
}

sub getPageTitle
{
    return "pt=Title";
}

sub getParentPageURL
{
    my $url = shift;

    return getPageURL($url);
}

sub getGeoCountry
{
    return "gc=US";
}

sub getGeoRegion
{
    return "gr=NY";
}

sub getGeoCity
{
    return "gt=Valhalla";
}

sub getParentPageType
{
    return "mt=0";
}

sub getPageMetrics
{
    my $metrics="{PLC:1,FBT:251,DDT:0,DPT:0,PLT:251,ARE:0,}";

    return getURIEncodedString($metrics);
}

sub getEndOfMessage
{
    return "em=1"
}



############     MAIN    ##################
#


my $beaconURI="http://col.eum-appdynamics.com/eumcollector/adrum.gif";

for (my $i = 0; $i < 100; $i++) 
{
    my $uuid = getGUUID();

    my $beacon = q{
        { "beacon": 
            {   "eumAppKey": "AD-AAB-AAA-JJS", 
                "ver": "2", 
                "dataType": "R",
                "clientRequestGUID": "__GUID__",
                "pageUrl": "http://www.synthetic-eum-test-page.com",
                "pageTitle": null,
                "userPageName": null,
                "pageReferrer": null,
                "pageType": 2,
                "baseGUID": null,
                "parentGUID": null,
                "parentPageUrl": null,
                "parentPageType": 0,
                "parentLifecyclePhase": 1,
                "geoCountry": null,
                "geoRegion": null,
                "geoCity": null,
                "localIP": null,
                "navOrXhrMetrics": {
                    "PLC": 1,
                    "FBT": 447,
                    "DDT": 1,
                    "DPT": 13,
                    "PLT": 461,
                    "ARE": 0
                },
                "cookieMetrics": {},
                "resourceTimingInfo": null,
                "otherClientRequestGUIDs": null,
                "btTime": null,
                "userData": null,
                "errors": null,
                "eom": 1 },
            "useHTTPS": false
        } 
    };            


    $beacon =~ s/__GUID__/$uuid/;

    my $browser = LWP::UserAgent->new;
    my $response = $browser->post ( "http://col.eum-appdynamics.com/eumcollector/beacons", [$beacon]);

    print "Posting:  \n\t$beacon\n";

    die "Error: ", $response->status_line
        unless $response->is_success;

    print $response->content;

    sleep 1;

    print "\n---------------------------\n";
    #print "requesting beacon: $beacon";
}
