package verbDB;

use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $verbDB = {@_};

	$verbDB->{database}||= 'data/VerbEntailmentAnnotated.db';
	$verbDB->{verb_a} ||= undef;
	$verbDB->{verb_b} ||= undef;
	$verbDB->{sep} ||= '|||';
	if($verbDB->{database} =~ m/\.db$/){
		$verbDB->{database} = $verbDB->{database}
	} else{
		$verbDB->{database} = $verbDB->{database}."\.db";
	}
	$verbDB->{berkeleydb} = new BerkeleyDB::Btree(-Filename => "$verbDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $verbDB->{database} not found\n";
	$verbDB->{berkeleydb}->filter_fetch_key(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);
	$verbDB->{berkeleydb}->filter_fetch_value(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);

    bless $verbDB, $class;
    return $verbDB;
}

sub get_verb_entailment
{
	my ($self, $verb_a, $verb_b) = @_;
	
	if($verb_a){
		$self->{verb_a} = $verb_a;
	}

	if($verb_b){
		$self->{verb_b} = $verb_b;
	}

	my $tempdata;
	my $result = 'UNK';
	my $key = $self->{verb_a}.$self->{sep}.$self->{verb_b};
	if($self->{berkeleydb}->db_get($key,$tempdata) == 0){
		$result = $tempdata;			
	}

	return $result;
}
1;
