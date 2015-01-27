package GramsFactory;

use strict;


sub groupGrams
{
	my ($sentence, $maxgram) = @_;
	$sentence =~ s/^\s*//;
	$sentence =~ s/\s*$//;
	my $results = {};
	my @uni = split(/\s+/,$sentence);
	$results->{1} = \@uni;
	foreach my $n (2 .. $maxgram){
		$results->{$n} = nextGrams($results->{$n-1}, $n-1, \@uni);
	}
	return ($results, [@uni]);
}

sub count
{
	my $grams = shift;
	my $counts = {};
	$counts->{$_}++ foreach (@$grams);
	return $counts;
}

sub groupRanges
{
	my ($sentence, $maxgram) = @_;
	$sentence =~ s/^\s*//;
	$sentence =~ s/\s*$//;
	my $results = {};
	my @words = split(/\s+/,$sentence);
	foreach my $n (1 .. $maxgram){
		$results->{$n} = getRanges($#words, $n);
	}
	return $results;
}

sub listGrams
{
	my ($sentence, $maxgram) = @_;
	$sentence =~ s/^\s*//;
	$sentence =~ s/\s*$//;
	my $results = [];
	my @uni = split(/\s+/,$sentence);
	push(@$results, $_) foreach (@uni);
	my $previous = \@uni;
	foreach my $n (2 .. $maxgram){
		$previous = nextGrams($previous, $n-1, \@uni);
		push(@$results, $_) foreach (@$previous);
	}
	return $results;
}

sub listRanges
{
	my ($sentence, $maxgram) = @_;
	$sentence =~ s/^\s*//;
	$sentence =~ s/\s*$//;
	my $results = [];
	my @words = split(/\s+/,$sentence);
	foreach my $n (1 .. $maxgram){
		my $ranges = getRanges($#words, $n);
		push(@$results, $_) foreach (@$ranges);
	}
	return $results;
}

sub getRanges
{
	my ($last, $length) = @_;
	my $result = [];
	$length -= 1;
	$last -= $length;
	foreach my $from (0 .. $last){
		my $to = $from + $length;
		push(@$result, "$from-$to");
	}
	return $result;
}

sub nextGrams
{
	my ($base, $current, $uni) = @_;
	my $new = [];
	foreach my $i (0 .. $#{$base}){
		last if ($i + $current > $#{$uni});
		my $gram = $base->[$i];
		my $add = $uni->[$i + $current];
		$gram .= " $add";
		push(@$new, $gram);
	}
	return $new;
}

sub range2string
{
	my ($range,$vocab) = @_;
	my ($from, $to) = split(/\-/, $range);
	return join(' ', @{$vocab}[$from .. $to]);
}

sub getSpam
{
	my ($from, $to, $vocab) = @_;
	return join(' ', @{$vocab}[$from .. $to]);
}

sub overlap
{
	my ($s1, $s2) = @_;
	my ($a1, $b1) = split(/\-/, $s1);
	my ($a2, $b2) = split(/\-/, $s2);
	return not ($a1 > $b2 or $a2 > $b1);
}

# assumes non overlapping phrases
sub inRange
{
	my ($s1, $s2, $radius) = @_;
	my ($a1, $b1) = split(/\-/, $s1);
	my ($a2, $b2) = split(/\-/, $s2);
	my $in = 0;
	if ($a1 < $a2){
		$in = (($a2-$b1) <= $radius);
	} else{
		$in = ( ($a1-$b2) <= $radius);
	}
#	print STDERR "$s1 vs $s2 in range $radius: $in\n";
	return $in;
}

1;
