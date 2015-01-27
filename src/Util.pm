package Util;

use strict;
use XML::TreeBuilder;

sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub encodeMosesTree
{
	my $string = shift;
	$string =~ s/&/&amp;/g;
	$string =~ s/\//&slash;/g;
	$string =~ s/</&lt;/g;
	$string =~ s/>/&gt;/g;
	$string =~ s/\|/&bar;/g;
	return $string;
}

sub encodeAllMosesTree
{
	my @array = @_;
	foreach my $i (0 .. $#array){
		$array[$i] = encodeMosesTree($array[$i]);
	}
	return @array;
}

sub decodeMosesTree
{
        my $string = shift;
        $string =~ s/&slash;/\//g;
	$string =~ s/&lt;/</g;
	$string =~ s/&gt;/>/g;
	$string =~ s/&bar;/|/g;
	$string =~ s/&amp;/&/g;
        return $string;
}

sub decodeAllMosesTree
{
	my @array = @_;
	foreach my $i (0 .. $#array){
		$array[$i] = decodeMosesTree($array[$i]);
	}
	return @array;
}

# returns a pretty version of the xml string output
#  input: xml node, level of edition
sub xmlPrettyPrint
{
	my ($root,$level) = @_;
	my $str = $root->as_XML;
	$str =~ s/></>\n</g;
	# level is reserved for future usage, such as
	#  0: new line
	#  1: indentation
	return $str;
}

# returns the ~pi xml element (encoding and version are optional parameters)
# default:
#	version= 1.0
#	encoding= utf-8
sub getXMLPi
{
	my ($encoding, $version) = @_;
	$encoding = "utf-8" unless $encoding;
	$version = "1.0" unless $version;
	return XML::Element->new('~pi', text => "xml version=\"$version\" encoding=\"$encoding\"");
}


1;
