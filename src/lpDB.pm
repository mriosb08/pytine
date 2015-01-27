package lpDB;
use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
use List::Util qw(max);
####
my $conection_database_uni;
my $conection_database_bi;

####
sub new 
{
	my $class = shift;
	my $lpDB = {@_};

	$lpDB->{unigram}||= 'data/1gms.db';
	$lpDB->{bigram}||= 'data/2gms.db';
	$lpDB->{w_a}||= undef;
	$lpDB->{w_b}||= undef;
	if($lpDB->{unigram} =~ m/\.db$/ && $lpDB->{bigram} =~ m/\.db$/)
	{
		$lpDB->{unigram} = $lpDB->{unigram};
		$lpDB->{bigram} = $lpDB->{bigram};
	}else{
		$lpDB->{unigram} =$lpDB->{unigram}."\.db";
		$lpDB->{bigram} =$lpDB->{bigram}."\.db";
	}
	$conection_database_uni = new BerkeleyDB::Btree(-Filename => "$lpDB->{unigram}",-Flags =>DB_RDONLY)or die "Error db: $lpDB->{unigram} not found\n";
	$conection_database_bi = new BerkeleyDB::Btree(-Filename => "$lpDB->{bigram}",-Flags =>DB_RDONLY)or die "Error db: $lpDB->{bigram} not found\n";

    bless $lpDB,$class;
    return $lpDB;
}

###GET###
# Input: word a, word b
# output: lexical probability from google
#
sub getLP
{
	my $lpDB = shift;
	$lpDB->{w_a}= shift;
	$lpDB->{w_b} = shift;
	my $lp = 0;
	my $uni = 0;
	my $bi = 0;
	
	my $tempdata;
	
	if($conection_database_uni->db_get($lpDB->{w_b},$tempdata) == 0){	
		$uni = $tempdata;
	}else{
		$uni = 0;
	}

	my $key_bi = $lpDB->{w_a}.' '.$lpDB->{w_b};
	if($conection_database_bi->db_get($key_bi,$tempdata) == 0){	
		$bi = $tempdata;
	}else{
		$bi = 0;
	}
	
	
	if($uni != 0){
		$lp = $bi/$uni;
	}else{
		$lp = 0;
	}
	return $lp;
}

1;
