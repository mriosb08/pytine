package HypothesizedAlignment;
use strict;
use Set::Object;
use AlignmentPoint;
sub new
{
	my $class = shift;
	my $self = {@_};
	$self->{path} ||= {};
	$self->{score} ||= 0;
	$self->{nulli} ||= 0;
	$self->{nullj} ||= 0;
	$self->{skip} ||= 1;
	$self->{null} = $self->{nulli}.'-'.$self->{nullj};
	bless($self, $class);
	return $self;
}

sub setAlignmentPoint
{
	my $self = shift;
	my $point;
	if(@_){
		$point = shift;
	}
	
	$self->{path}->{$point->{key}} = $point if($point->{key} != $self->{null});
}

sub addScore
{
	my $self = shift;
	my $score;
	if(@_){
		$score = shift;
		$self->{score} += $score;
	}
}

sub hasMember
{
	my $self = shift;
	my $point;
	my $result = 0;
	if(@_){ 
		$point = shift;
	}
	$result = $self->{path}->has($point);
	return $result;
}

sub getpathAsHash
{
	my $self = shift;
	return $self->{path};
	
}

sub getpathAsString
{
	my $self = shift;
	my @result = ();
	foreach my $key(keys %{$self->{path}}){
		my $point = $self->{path}->{$key}; 
		push(@result, $point->{key});
	}

	return join(' ', @result);
}

sub getScore
{
	my $self = shift;
	return $self->{score};
}

1;
