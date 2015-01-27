package SimsDB;

use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $simsDB = {@_};

	$simsDB->{database}||= 'data/sims.db';
	$simsDB->{w_a} ||= undef;
	$simsDB->{w_b} ||= undef;
	$simsDB->{threshold} ||= undef;
	$simsDB->{nbest} ||= 20;
	if($simsDB->{database} =~ m/\.db$/){
		$simsDB->{database} = $simsDB->{database}
	} else{
		$simsDB->{database} = $simsDB->{database}."\.db";
	}
	$simsDB->{berkeleydb} = new BerkeleyDB::Btree(-Filename => "$simsDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $simsDB->{database} not found\n";
	$simsDB->{berkeleydb}->filter_fetch_key(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);
	$simsDB->{berkeleydb}->filter_fetch_value(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);

    bless $simsDB, $class;
    return $simsDB;
}
###SET###
#Input: word a, word b 
#
sub setWords
{
	my $simsDB = shift;
	my ($a,$b) = @_;
	$simsDB->{w_a} = $a if defined($a);
	$simsDB->{w_b} = $b if defined($b);
	
}
###GET###
# Input: -, the set words
# output: 1 if they are related, 0 otherwise
#
sub getIntersection
{
	my $self = shift;
	my $key_a = $self->{w_a};
	my $key_b = $self->{w_b};

	my  $set_a = new Set::Scalar($self->getWords($key_a));
	my  $set_b = new Set::Scalar($self->getWords($key_b));
	
	my $i = $set_a->intersection($set_b);
	my $size = $i->size();
	
	return $size;
}

sub findMatches
{
	my ($self, $key, $includeKey) = @_;
	my $tempdata;
	my $results = {};
	my $n = 0;
	if($self->{berkeleydb}->db_get($key,$tempdata) == 0){
		# cleaning the scores (TODO: use it and 'threshold' to prune the nbest list)
		my @pairs = split(/\s+/, $tempdata);
		foreach my $pair (@pairs){
			$pair =~ m/^(.+)=([0-9.]+)$/;
			my ($k, $v) = ($1, $2);
			if ((not defined $self->{nbest}) or ($n < $self->{nbest})){
				if ((not defined $self->{threshold}) or ($v >= $self->{threshold})){
					$results->{$k} = $v;
					$n++;
				}
			}
		}
	}
	if ($includeKey){
		$results->{$key} = 1.0;
	}
	return $results;
}

1;
