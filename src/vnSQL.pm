package vnSQL;
use DBI;
use Set::Scalar;
use strict;
use warnings;
#TODO transform sql into db just the verb intersection
####
my $conection_database;
####
sub new 
{
	my $class = shift;
	my $vnSQL = {@_};

	$vnSQL->{database}||= "wordnet30";
	$vnSQL->{host}||= "localhost";
	$vnSQL->{user}||= "root";
	$vnSQL->{psw}||= "root";
	$vnSQL->{strict}||= 0;
	$vnSQL->{v}||= undef;
	$vnSQL->{v_a}||= undef;
	$vnSQL->{v_b}||= undef;
	$vnSQL->{sep}||= "\t";
	$conection_database = DBI->connect("DBI:mysql:database=$vnSQL->{database};host=$vnSQL->{host}",
						"$vnSQL->{user}",
						"$vnSQL->{psw}",
						{'RaiseError' => 1});

    bless $vnSQL,$class;
    return $vnSQL;
}
###SET###
#Input: verb 
#
sub setVerb
{
	my $vnSQL = shift;
	my ($verb) = @_;
	$vnSQL->{v} = $verb;
}
###GET###
# Input: verb a, verb b (lemmas)
# output: 1 if they share a verbnet class, 0 otherwise
# 			set for verb a and ser for verb b
sub getIclass
{
	my $vnSQL = shift;
	my ($a,$b) = @_;
	$vnSQL->{v_a} = $a if defined($a);
	$vnSQL->{v_b} = $b if defined($b);
 	my $result = undef;
	my  $set_a = Set::Scalar->new;
	my  $set_b = Set::Scalar->new;
	# classes of verb a
	my $query_a = "SELECT GROUP_CONCAT(class SEPARATOR ' ') as 'class'  FROM vnclassmembers INNER JOIN vnclasses USING (classid) INNER JOIN words USING (wordid) WHERE lemma='$vnSQL->{v_a}' GROUP BY wordid";

	my $command_database = $conection_database->prepare($query_a);

	$command_database->execute();
	
	while (my $feched_row = $command_database->fetchrow_hashref()) {
		
		my @temp = split(/\s+/,$feched_row->{class});
		_just_name_class(\@temp) if($vnSQL->{strict} == 0);
		$set_a->insert(@temp);				
	}
	# classes of verb b
	my $query_b = "SELECT GROUP_CONCAT(class SEPARATOR ' ') as 'class' FROM vnclassmembers INNER JOIN vnclasses USING (classid) INNER JOIN words USING (wordid) WHERE lemma='$vnSQL->{v_b}' GROUP BY wordid";
	
	$command_database = $conection_database->prepare($query_b);

	$command_database->execute();
	
	while (my $feched_row = $command_database->fetchrow_hashref()) {
		my @temp = split(/\s+/,$feched_row->{class});
		_just_name_class(\@temp) if($vnSQL->{strict} == 0);
		$set_b->insert(@temp);		
	}
	
	my $i = $set_a->intersection($set_b);
	my $size = $i->size();
	if($size > 0){
		$result = 1;
	}else{
		$result = 0;
	}
	
	return ($result, $set_a, $set_b);
}

sub _just_name_class
{
	my ($classes) = shift;
	foreach my $i(0..$#{$classes}){
		my($name, @rest) = split(/-/, $classes->[$i]);
		$classes->[$i] = $name; 
	}
}

####
#TODO extract MORE Verbnet infromation from the set verb 
1;
