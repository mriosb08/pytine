package AlignmentPoint;

use strict;

sub new
{
	my $class = shift;
	my $self = {@_};
	$self->{key} ||= undef;
	$self->{i} ||= 0;
	$self->{j} ||= 0;
	$self->{score} ||= 0;
	bless($self, $class);
	return $self;
}

sub setKey
{
	my $self = shift;
	if(@_){
		$self->{key} = shift;
	}
}

sub setI
{
	my $self = shift;
	if(@_){
		$self->{i} = shift;
	}
}

sub setJ
{
	my $self = shift;
	if(@_){
		$self->{j} = shift;
	}
}

sub setScore
{
	my $self = shift;
	if(@_){
		$self->{score} = shift;
	}
}

sub getKey
{
	my $self = shift;
	return $self->{key};
}

sub getI
{
	my $self = shift;
	return $self->{i};
}

sub getJ
{
	my $self = shift;
	return $self->{j};
}

sub getScore{
	my $self = shift;
	return $self->{score};
}

sub asString
{
	my $self = shift;
	my @result = ();
	foreach my $key(keys %{$self}){
		push(@result, $self->{$key});
	}

	return join(' ', @result);
}

1;
