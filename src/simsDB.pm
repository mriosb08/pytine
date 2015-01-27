package simsDB;
use BerkeleyDB;
use strict;
use warnings;
use Set::Scalar;
####
my $conection_database;

####
sub new 
{
	my $class = shift;
	my $simsDB = {@_};

	$simsDB->{database}||= 'data/sims.db';
	$simsDB->{w_a}||= undef;
	$simsDB->{w_b}||= undef;
	$simsDB->{threshold}||=20;
	if($simsDB->{database} =~ m/\.db$/)
	{
		$simsDB->{database} = $simsDB->{database}
	}else{
		$simsDB->{database} = $simsDB->{database}."\.db";
	}
	$conection_database = new BerkeleyDB::Btree(-Filename => "$simsDB->{database}",-Flags =>DB_RDONLY)or die "Error db: $simsDB->{database} not found\n";

    bless $simsDB,$class;
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
	my $simsDB = shift;
	my $key_a = $simsDB->{w_a};
	my $key_b = $simsDB->{w_b};

	my  $set_a = Set::Scalar->new;
	my  $set_b = Set::Scalar->new;

	my $tempdata;
	#print "KA:$key_a\n";
	$set_a->insert($key_a); #also insert the original word	
	if($conection_database->db_get($key_a,$tempdata) == 0)
	{	
		#print "temp:$tempdata\n";
		$tempdata =~ s/=\d+\.\d+ / /g; #delete extra info from thesaurus
		$tempdata =~ s/=\d+\.\d+$/ /g;
		#print "temp:$tempdata\n";
		my @t_a = split(/\s+/,$tempdata);
		if($#t_a >= $simsDB->{threshold}){		
			$set_a->insert(@t_a[0..$simsDB->{threshold}]);
		}else{
			$set_a->insert(@t_a);
		}
	}
	$tempdata = ""; 
	$set_b->insert($key_b);	
	if($conection_database->db_get($key_b,$tempdata) == 0)
	{	
		$tempdata =~ s/=\d+\.\d+ / /g;
		$tempdata =~ s/=\d+\.\d+$/ /g;
		#print "temp:$tempdata\n";		
		my @t_b = split(/\s+/,$tempdata);
		if($#t_b >= $simsDB->{threshold}){		
			$set_b->insert(@t_b[0..$simsDB->{threshold}]);
		}else{
			$set_b->insert(@t_b);
		}
	
	}
	
	my $i = $set_a->intersection($set_b);
	my $size = $i->size();
	
	if($size > 0){
		return 1;
	}else{
		return 0;
	}
	
}

sub getWords
{
	my $simsDB = shift;
	#my  $set_a = Set::Scalar->new;
	my $key_a = shift;
	my $tempdata;
	
	if($conection_database->db_get($key_a,$tempdata) == 0){
		$tempdata =~ s/=\d+\.\d+ / /g;
		$tempdata =~ s/=\d+\.\d+$/ /g;
		my @t_a = split(/\s+/,$tempdata);
		push(@t_a,$key_a);	
		if($#t_a >= $simsDB->{threshold}){
			return(@t_a[0..$simsDB->{threshold}]);
		}else{
			return(@t_a);
		}
		
	}else{
		return $key_a;
	}
	#my @temp_array = $set_a	
	
}

1;
