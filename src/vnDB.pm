package vnDB;

use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $vnDB = {@_};

	$vnDB->{database}||= 'data/vn_classes.db';
	$vnDB->{verb} ||= undef;
	if($vnDB->{database} =~ m/\.db$/){
		$vnDB->{database} = $vnDB->{database}
	} else{
		$vnDB->{database} = $vnDB->{database}."\.db";
	}
	$vnDB->{berkeleydb} = new BerkeleyDB::Btree(-Filename => "$vnDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $vnDB->{database} not found\n";
	$vnDB->{berkeleydb}->filter_fetch_key(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);
	$vnDB->{berkeleydb}->filter_fetch_value(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);

    bless $vnDB, $class;
    return $vnDB;
}

sub get_vn_classes
{
	my ($self, $verb) = @_;
	
	if($verb){
		$self->{verb} = $verb;
	}

	my $tempdata;
	my $results = {};
	my $key = $self->{verb};
	if($self->{berkeleydb}->db_get($key,$tempdata) == 0){
		my @classes = ();	
		@classes = split(/\s+/, $tempdata);
		$results->{$key} = [@classes];			
	}

	return $results;
}
1;
