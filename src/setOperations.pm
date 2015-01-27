package setOperations;
use strict;
use Set::Scalar;
use List::Util qw(min);
sub new 
{
	my $class = shift;
	my $setOperations = {@_};

	$setOperations->{set_1} ||= undef;
	$setOperations->{set_2} ||= undef;
	$setOperations->{result} ||= 0;
	$setOperations->{set_1} = new Set::Scalar(@{$setOperations->{set_1}});
	$setOperations->{set_2} = new Set::Scalar(@{$setOperations->{set_2}});
	$setOperations->{len_set_1} = $setOperations->{set_1}->size;
	$setOperations->{len_set_2} = $setOperations->{set_2}->size;
	$setOperations->{prec} = 0;
	$setOperations->{rec} = 0;
	$setOperations->{f1} = 0;
    bless $setOperations, $class;
    return $setOperations;
}

sub get_cosine
{
	my($self) = @_;
	my $isec = $self->{set_1} * $self->{set_2};
	$self->{result} = $isec->size / sqrt($self->{len_set_1} * $self->{len_set_2});
	return $self->{result};
}

sub get_dice
{
	my($self) = @_;
	my $isec = $self->{set_1} * $self->{set_2};
	$self->{result} = (2 * $isec->size) / ($self->{len_set_1} + $self->{len_set_2});
	return $self->{result};
}

sub get_jaccard
{
	my($self) = @_;
	my $isec = $self->{set_1} * $self->{set_2};
	my $union = $self->{set_1} + $self->{set_2};
	$self->{result} = $isec->size / $union->size;
	return $self->{result};
}

sub get_overlap
{
	my($self) = @_;
	my $isec = $self->{set_1} * $self->{set_2};
	
	$self->{result} = $isec->size / min($self->{len_set_1}, $self->{len_set_2});
	return $self->{result};
} 

sub get_precision
{
	my($self) = @_;
	my $isec = $self->{set_1} * $self->{set_2};
	
	$self->{prec} = $isec->size / $self->{len_set_1};
	return $self->{prec};
}

sub get_recall
{
	my($self) = @_;
	my $isec = $self->{set_1} * $self->{set_2};
	
	$self->{rec} = $isec->size / $self->{len_set_2};
	return $self->{rec};
}

sub get_f1
{
	my($self) = @_;
	$self->{result} = 2 * (($self->{prec} * $self->{rec}) / ($self->{prec} + $self->{rec}));
	return $self->{result};
}

1;
