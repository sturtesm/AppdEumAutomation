#!/usr/bin/perl -w

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

#global ip list
my @globalIP = ();
my @globalCityList = ();

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

sub ingestGlobalIPList
{
    open IN, "<global-ip-list.csv" or die "Error reading global-ip-list.csv: $!";

    while (<IN>)
    {
        my @fields = split (',', $_);

        push @globalIP, $fields[0];
    }

    close IN;
}

sub ingestGlobalCityList
{
    open IN, "<global-city-list.csv" or die "Error reading global-city-list.csv: $!";

    while (<IN>)
    {
        #format is - Country, Region / State, City
        my $line = $_;

        chomp ($line);

        push @globalCityList, $line;
    }

}
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
    return 'vr=2';
}

# Get the Data Type, always R
sub getDataType 
{
    return 'dt=R';
}

# Get the GUUID, RFC4122 version 4
sub getGUUID
{
    my $uuid = $ug->generate_v1();    
    my $guid = $uuid->as_string();

    $guid =~ s/-/_/g;

    return "cg=$guid";
}

# Page URL, limited to the first 180 Characters.  URI Encoded.
# 
# IN:  PageURL to decode
# OUT: encoded URL
sub getPageURL
{
    my $url = shift;
    
    if (isUndefined($url) ) {
       $url = "http://www.custom-geo-city-region-final.com";
    }

    my $encodedURL = getURIEncodedString($url);

    return "pu=$encodedURL";
}

sub getPageType
{
    return "pt=0";
}

sub getParentPageURL
{
    my $url = shift;

    return getPageURL($url);
}

sub getGeoInfo
{
    my $length = int ( scalar @globalCityList );
    my $index = rand($length);

    my $geoInfo = $globalCityList[$index];
    my @fields = split(/,/, $geoInfo);

    return "gc=$fields[0]&gr=$fields[1]&gt=$fields[2]";
}     

sub getCustomIP
{
    my $size = scalar(@globalIP);
    my $index = int(rand($size));

    my $ip = $globalIP[$index];

    my @octets = split(/\./, $ip);
    my @encodedOcts = ();

    foreach my $oct (@octets)
    {
        #my $encodedOctet = getURIEncodedString($oct);
        my $encodedOctet = sprintf("%x",$oct);
        push @encodedOcts, $encodedOctet;

        #print "Pushing $encodedOctet...\n";
    }
    my $encodedOctet = join('', @encodedOcts);

    #print "Generated encoded octets: $encodedOctet\n\n";
    
    return "lp=$encodedOctet";
}

sub getParentPageType
{
    #return "mt=0";
}

sub getRnd
{
    my $min=shift;
    my $max=shift;

    my $val = rand($max);

    if ($val < $min) {
        $val = $min
    }
    
    return int($val);    
}

sub getPageMetrics
{
    my %metricHash = ();

    #page load count, always 1
    $metricHash{'PLC'} = 1;

    #end user response-time
    my $endUserRT = getRnd(5000, 15000);
    $metricHash{'PLT'} = $endUserRT;

    #dom ready time 
    $metricHash{'DOM'} = getRnd($endUserRT-1500, $endUserRT);

    #first byte time
    $metricHash{'FBT'} = getRnd($endUserRT-2000, $metricHash{'DOM'} - 500);

    #server connection time, should be < first byte time [T2]
    $metricHash{'SCT'} = getRnd(100, $metricHash{'FBT'});    

    #tcp connection time [T2]
    $metricHash{'TCP'} = getRnd(100, $metricHash{'SCT'});

    #dns lookup time - TRY 1 END
    #$metricHash{'DNS'} = 100; #getRnd(0, 100);

    #response available = first byte - server conn time
    #$metricHash{'RAT'} = $metricHash{'FBT'} - $metricHash{'SCT'};
    
    #html download time
    $metricHash{'DDT'} = getRnd(100, 500);
    
    #dom building time
    $metricHash{'DPT'} = $endUserRT - $metricHash{'FBT'} - $metricHash{'DDT'};   #$metricHash{'DOM'} - $metricHash{'FBT'};

    #HTML Download and dom building time
    $metricHash{'DRT'} = getRnd(100, 500);

    #resource fetch time
    $metricHash{'PRT'} = getRnd(100, 250);
    
    #front end time
    $metricHash{'FET'} = $metricHash{'DRT'} + $metricHash{'PRT'};

    my @metrics;
    foreach my $k (keys %metricHash) 
    {
        #note the trailing ',' so we have CSV separated metrics
        push @metrics, "${k}:$metricHash{$k}";
    }

    my $metricList = '{' . join(',', @metrics) . ',}';
    my $encodedMetrics=getURIEncodedString($metricList);

    #my $metrics="{PLC:1,FBT:251,DDT:0,DPT:0,PLT:251,ARE:0,}";
    
    print "[Raw Metrics] $metricList\n";
    print "[Encoded Metrics] $encodedMetrics\n";
    
    return "mn=${encodedMetrics}";
    
    #return "mn=%7BFET%3A1000%2CPRT%3A387%2CDRT%3A613%2CDOM%3A3639%2CPLT%3A5639%2CPLC%3A1%2C%7D";
}

sub getEndOfMessage
{
    return "em=1"
}



############     MAIN    ##################
#

#read the global ip list
ingestGlobalIPList();
ingestGlobalCityList();

my $beaconURI="http://col.eum-appdynamics.com/eumcollector/adrum.gif";

for (my $i = 0; $i < 400; $i++) 
{
    my @beaconParams = ();

    print "--------------------------\n\n";

    push (@beaconParams, getAppKey());
    push (@beaconParams, getVR());
    push (@beaconParams, getDataType());
    push (@beaconParams, getGUUID());
    push (@beaconParams, getPageURL());
    push (@beaconParams, getPageType());
    #push (@beaconParams, getParentPageURL());
    #push (@beaconParams, getParentPageType());
    push (@beaconParams, getGeoInfo());
    push (@beaconParams, getPageMetrics());
    #push (@beaconParams, getCustomIP());
    push (@beaconParams, getEndOfMessage());

    my $params = join ('&', @beaconParams);

    my $qualifiedURI="$beaconURI?$params";

    print "Beacon URI: $qualifiedURI\n";
    
    my $rc = get($qualifiedURI);
    
    print "\n[RC ]  $rc\n";
    print "\n---------------------------\n";

    sleep 1;
}
