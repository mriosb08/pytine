package NELL;

use DBI;
use strict;
use warnings;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $NELL = {@_};

	$NELL->{db}||= 'NELL';
	$NELL->{table} ||= undef;
	$NELL->{user} ||= 'root';
	$NELL->{pass} ||= 'root';
	$NELL->{host} ||= 'localhost';
	$NELL->{search_by} ||= 'Best_Entity_literalString';
	$NELL->{dbh} = DBI->connect("DBI:mysql:database=$NELL->{db};host=$NELL->{host}", $NELL->{user}, $NELL->{pass}, {'RaiseError' => 1});
	$NELL->{rows} = {Entity => 1,Relation => 1,Value => 1,Iteration_of_Promotion => 1,Probability => 1,Source => 1,Candidate_Source => 1,Entity_literalStrings => 1,Value_literalStrings => 1,Best_Entity_literalString => 1,Best_Value_literalString => 1,Categories_for_Entity => 1,Categories_for_Value => 1};
    bless $NELL, $class;
    return $NELL;
}
#TODO check Entity_literalStrings !!! to do the retrieve
sub get_beliefs
{
	my($self, $concept) = @_;
	$self->{table} = 'beliefs';
	my $query = "SELECT * FROM $self->{table} WHERE $self->{search_by} LIKE '$concept'";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute();
	
	my $result = {};	
	while(my $ref = $sth->fetchrow_hashref()) {
		my $key = $ref->{Entity};
		push(@{$result->{$key}}, $ref);		
	}
	return $result;
}

sub get_relations
{
	my($self, $concept) = @_;
	$self->{table} = 'beliefs';
	my $query = "SELECT * FROM $self->{table} WHERE $self->{search_by} LIKE '$concept'";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute();
	
	my $result = {};	
	while(my $ref = $sth->fetchrow_hashref()) {
		my $key = $ref->{Relation};
		push(@{$result->{$key}}, $ref->{Value});		
	}
	return $result;
}

sub get_categories
{
	my($self, $concept) = @_;
	$self->{table} = 'beliefs';
	my $query = "SELECT * FROM $self->{table} WHERE $self->{search_by} LIKE '$concept'";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute();
	
	my $result = {};	
	while(my $ref = $sth->fetchrow_hashref()) {
		my $key = $ref->{Entity};
		$result->{$key} = $ref->{Categories_for_Entity};		
	}
	return $result;
}

sub get_instances
{
	my($self, $entity, $value) = @_;
	$self->{table} = 'patterns';
	my $query = "SELECT * FROM $self->{table} WHERE Entity LIKE '$entity' AND Value LIKE '$value'";
	#print STDERR "Q:$query\n";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute();
	my $result = {};
	while(my $ref = $sth->fetchrow_hashref()) {
		my $source = $ref->{Candidate_Source};
		#print "$source\n";
		my ($extra, $instance) = split(/instances: /, $source);
		#print "$extra\n$instance\n";
		my $key = $ref->{Entity}.':'.$ref->{Value};
		my @instances = split(/ "[0-9]+" /, $instance);
		foreach my $i(0 .. $#instances){
			$instances[$i] =~ s/"//g;
		}		
		$result->{$key} = [@instances];  		
	}
	return $result;
}

sub get_values
{
	my($self, $entity) = @_;
	$self->{table} = 'patterns';
	my $query = "SELECT * FROM $self->{table} WHERE Entity LIKE '$entity'";
	my $sth = $self->{dbh}->prepare($query);
	$sth->execute();
	my $result = {};
	while(my $ref = $sth->fetchrow_hashref()) {
		my $key = $ref->{Entity};
		push(@{$result->{$key}},$ref->{Value});
	}
	return $result;	
}


1;
