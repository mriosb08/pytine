package lmDB;
use BerkeleyDB;
use strict;
use warnings;
####
my $conection_database_uni;
my $conection_database_bi;

####
sub new 
{
	my $class = shift;
	my $lmDB = {@_};

	$lmDB->{unigram}||= 'data/1gms.db';
	$lmDB->{bigram}||= 'data/2gms.db';
	$lmDB->{sentence}||= undef;
	$lmDB->{n_words}||= 13588391; #unigrams google
	
	if($lmDB->{unigram} =~ m/\.db$/ && $lmDB->{bigram} =~ m/\.db$/)
	{
		$lmDB->{unigram} = $lmDB->{unigram};
		$lmDB->{bigram} = $lmDB->{bigram};
	}else{
		$lmDB->{unigram} =$lmDB->{unigram}."\.db";
		$lmDB->{bigram} =$lmDB->{bigram}."\.db";
	}
	$conection_database_uni = new BerkeleyDB::Btree(-Filename => "$lmDB->{unigram}",-Flags =>DB_RDONLY)or die "Error db: $lmDB->{unigram} not found\n";
	$conection_database_bi = new BerkeleyDB::Btree(-Filename => "$lmDB->{bigram}",-Flags =>DB_RDONLY)or die "Error db: $lmDB->{bigram} not found\n";

    bless $lmDB,$class;
    return $lmDB;
}

###GET###
# Input: word a, word b
# output:language bigram model from google
#
sub getLM
{
	my $lmDB = shift;
	$lmDB->{sentence}= shift;
	
	my $lp = 0;
	my $uni = 0;
	my $bi = 0;
	my $prod = 1;

	my $tempdata;
		
	if(scalar(@{$lmDB->{sentence}}) == 0){
		return 0;
	}
	
	if($conection_database_uni->db_get($lmDB->{sentence}->[0],$tempdata) == 0){ #first word	
			$uni = $tempdata;
	}else{
		$uni = 1;
	}

	my $p_1 = $uni/$lmDB->{n_words};
	$prod *= $p_1;
	#print "word1 $sentence[0] $uni#$lmDB->{n_words}\n";
	foreach my $i(1..$#{$lmDB->{sentence}}){		
		
		my $key_bi =$lmDB->{sentence}->[$i-1].' '.$lmDB->{sentence}->[$i];

		if($conection_database_bi->db_get($key_bi,$tempdata) == 0){	
			$bi = $tempdata;
		}else{
			$bi = 0;
		}

		if($conection_database_uni->db_get($lmDB->{sentence}->[$i-1],$tempdata) == 0){	
			$uni = $tempdata;
		}else{
			$uni = 0;
		}
		#print "BIGRAMS: $key_bi\n";
		$prod *= ($bi+1)/($uni+$lmDB->{n_words}); #laplace smoothing
		
	}
	
	return $prod;
}

1;
