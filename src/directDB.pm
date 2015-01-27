package directDB;

use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $directDB = {@_};

	$directDB->{database}||= 'data/DIRECT_nouns_1000.db';
	$directDB->{token_a} ||= undef;
	$directDB->{token_b} ||= undef;
	$directDB->{sep} ||= '|||';
	if($directDB->{database} =~ m/\.db$/){
		$directDB->{database} = $directDB->{database}
	} else{
		$directDB->{database} = $directDB->{database}."\.db";
	}
	$directDB->{berkeleydb} = new BerkeleyDB::Btree(-Filename => "$directDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $directDB->{database} not found\n";
	$directDB->{berkeleydb}->filter_fetch_key(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);
	$directDB->{berkeleydb}->filter_fetch_value(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);

    bless $directDB, $class;
    return $directDB;
}

sub get_token_entailment
{
	my ($self, $token_a, $token_b) = @_;
	
	return 1 if($token_a eq $token_b);
	return 0 if(!$token_a or !$token_b);
	if($token_a){
		$self->{token_a} = $token_a;
	}

	if($token_b){
		$self->{token_b} = $token_b;
	}
	
	my $temp_ab;
	my $temp_ba;
	my $result_ab = 0;
	my $result_ba = 0;
	
	
	my $key_ab = $self->{token_a}.$self->{sep}.$self->{token_b};
	my $key_ba = $self->{token_b}.$self->{sep}.$self->{token_a}; 
	if($self->{berkeleydb}->db_get($key_ab,$temp_ab) == 0){
		$result_ab = $temp_ab;
	}
	if($self->{berkeleydb}->db_get($key_ba,$temp_ba) == 0){
		$result_ba = $temp_ba;
	}
	#print "$key_ab:$key_ba\n";
	#print "$result_ab:$result_ba\n";
	if($result_ab > $result_ba){
		return 1;
	}else{
		return 0;
	}	
}

sub get_score
{
	my ($self, $token_a, $token_b) = @_;
	
	if($token_a){
		$self->{token_a} = $token_a;
	}

	if($token_b){
		$self->{token_b} = $token_b;
	}
	my $key_ab = $self->{token_a}.$self->{sep}.$self->{token_b};
	my $result_ab = 0;
	my $temp_ab;
	if($self->{berkeleydb}->db_get($key_ab,$temp_ab) == 0){
		$result_ab = $temp_ab;
	}
	return $result_ab;
}
1;
