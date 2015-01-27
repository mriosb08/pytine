package wnDB;

use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $wnDB = {@_};

	$wnDB->{database}||= 'data/wn_hyper.db';
	$wnDB->{lemma} ||= undef;
	$wnDB->{pos} ||= undef;
	$wnDB->{sense} ||= '01';
	if($wnDB->{database} =~ m/\.db$/){
		$wnDB->{database} = $wnDB->{database}
	} else{
		$wnDB->{database} = $wnDB->{database}."\.db";
	}
	$wnDB->{berkeleydb} = new BerkeleyDB::Btree(-Filename => "$wnDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $wnDB->{database} not found\n";
	$wnDB->{berkeleydb}->filter_fetch_key(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);
	$wnDB->{berkeleydb}->filter_fetch_value(
		sub {
			Encode::_utf8_off($_);
			$_=Encode::decode('utf8', $_);
		}
	);

    bless $wnDB, $class;
    return $wnDB;
}

sub penn_to_wn_pos
{
	my ($self, $pos) = @_;
	
	if($pos =~ m/NN/){
		return 'n';
	}elsif($pos =~ m/VB/){
		return 'v';
	}elsif($pos =~ m/JJ/){
		return 'a';
	}elsif($pos =~ m/RB/){
		return 'r';
	}else{
		return -1;
	}

}
#NOTE DB just has nouns!!!
sub get_hyper_tree
{
	my ($self, $lemma, $pos, $sense) = @_;
	$self->{lemma} = $lemma;
	$self->{pos} = $pos;
	if($sense){
		$self->{sense} = $sense;
	}

	my $tempdata;
	my $results = {};
	my $key = $self->{lemma} . '.' . $self->{pos} . '.' . $self->{sense};
	if($self->{berkeleydb}->db_get($key,$tempdata) == 0){
		my @tree = ();	
		@tree = split(/\s+/, $tempdata);
		$results->{$key} = [@tree];			
	}

	return $results;
}
1;
