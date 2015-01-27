package voDB;

use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $voDB = {@_};

	$voDB->{database}||= 'data/verbocean.db';
	$voDB->{verb_a} ||= undef;
	$voDB->{verb_b} ||= undef;
	$voDB->{relations} ||= {'can-result-in' => 1
                               ,'happens-before' => 1 
                               ,'low-vol' => 1
                               ,'opposite-of' => 1
                               ,'similar' => 1
                               ,'stronger-than' => 1
                               ,'unk' => 1};
	if($voDB->{database} =~ m/\.db$/){
		$voDB->{database} = $voDB->{database}
	} else{
		$voDB->{database} = $voDB->{database}."\.db";
	}
	$voDB->{berkeleydb} = new BerkeleyDB::Btree(-Filename => "$voDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $voDB->{database} not found\n";
	$voDB->{berkeleydb}->filter_fetch_key(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);
	$voDB->{berkeleydb}->filter_fetch_value(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);

    bless $voDB, $class;
    return $voDB;
}

sub get_vo
{
	my ($self, $verb_a, $verb_b) = @_;
	
	if($verb_a){
		$self->{verb_a} = $verb_a;
	}

	if($verb_b){
		$self->{verb_b} = $verb_b;
	}

	my $tempdata;
	my $results = {};
	my $key = $self->{verb_a}. ' ' . $self->{verb_b};
	if($self->{berkeleydb}->db_get($key,$tempdata) == 0){
		my @rel_score = ();	
		@rel_score = split(/\s+/, $tempdata);
		$results->{$key} = [@rel_score];			
	}

	return $results;
}
1;
