package BLEU;

use strict;
use List::Util qw/min/;
use GramsFactory;

# String ref: single reference (TODO: multi reference BLEU)
# String hyp: a hyp (string)
# Integer order: BLEU max n-gram, default is 4
# Boolean fallback: whether or not it shoud fallback to lower order BLEU
# returns (bleu score, bleu order, ngram counts)
sub sbleu
{
	my $params = {@_};
	defined $params->{'ref'} or die "BLEU requires a list of references: 'ref'\n";
	defined $params->{hyp} or die "BLEU requires a hypothesis: 'hyp'\n";
	$params->{order} ||= 4;
	$params->{fallback} ||= 0;
	# generate n-grams
	my ($hGrams, $H) = GramsFactory::groupGrams($params->{hyp}, $params->{order});
	my ($tGrams, $T) = GramsFactory::groupGrams($params->{'ref'}, $params->{order});
	# counts matching n-grams
	my $counts = [];
	push(@$counts, {total => 0, correct => 0, ratio => 0}) foreach (0 .. $params->{order});
	foreach my $n (sort {$a <=> $b} keys %$hGrams){
		my $hg = GramsFactory::count($hGrams->{$n});
		my $tg = GramsFactory::count($tGrams->{$n});
		foreach my $gram (keys %$hg){
			$counts->[$n]->{total} += $hg->{$gram};
			if (exists $tg->{$gram}){
				$counts->[$n]->{correct} += min($hg->{$gram}, $tg->{$gram});
			}
		}
		$counts->[$n]->{ratio} = $counts->[$n]->{correct} / $counts->[$n]->{total} if $counts->[$n]->{total};
	}
	my $hlen = scalar(@$H);
	my $brevityPenalty = ($hlen)?exp(1-scalar(@$T)/$hlen):0;
	if ($counts->[1]->{ratio} == 0){
		return (0, 'bleu');
	}
	my $max = $params->{order};
	if ($params->{fallback}){
		foreach my $n (2 .. $#{$counts}){
			if ($counts->[$n]->{ratio} == 0){
				$max = $n-1;
				last;
			}
		}
	}
	my $sum = 0;
	foreach my $n (1 .. $max){
		$sum += my_log($counts->[$n]->{ratio});
	}
	return ($brevityPenalty*exp($sum/$max), "bleu$max", $counts);
}

sub my_log
{
	my $n = shift;
	if ($n == 0){
		return -9999999;
	} else{
		return log($n);
	}
}

1;
