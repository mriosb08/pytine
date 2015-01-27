package AlignmentFinder;
use strict;
use AlignmentPoint;
use HypothesizedAlignment;
use Set::Scalar;
use List::Priority;

sub new
{
	my $class = shift;
	my $self = {@_};
	$self->{matrix} ||= [];
	$self->{criterion} ||= 0;
	$self->{jSet} ||= {};
	$self->{iSet} ||= {};
	$self->{op} ||= {};
	$self->{cl} ||= {};
	$self->{f} ||= {};
	$self->{g} ||= 0;
	$self->{h} ||= 0;
	$self->{nulli} ||= 0;
	$self->{nullj} ||= 0;
	$self->{alingmentPoint} ||= new AlignmentPoint();
	$self->{hypoPath} ||= new HypothesizedAlignment(nulli=>$self->{nulli}, nullj=>$self->{nullj});
	bless($self, $class);
	return $self;
}

sub AStarSolver
{
	my $self = shift;
	my $startPoint;
	if(@_){
		$startPoint = shift;
	}
	
	$self->{alignmentPoint} = $startPoint;
	my $starti = $startPoint->getI();
	my $startj = $startPoint->getJ();
	$self->{iSet}->{$starti} = 1;
	$self->{jSet}->{$startj} = 1;
	$self->{op}->{$startPoint->{key}} = 1;
	$self->{h} = _computeH($startPoint->{key}, $self->{goal});
	$self->{g} = 0;
	my $current = $startPoint->{key};
	_penalizeCriterion($self->{matrix}, $self->{criterion}, $self->{nulli}, $self->{nullj});
	_setPointPath($current, $self->{matrix}, $self->{alignmentPoint}, $self->{hypoPath});
	my @path = ();
	while(my $k = each(%{$self->{op}})){
		my $neightbors = _expandNode($current, $self->{matrix}, $self->{iSet}, $self->{jSet});
		if($self->{op}->{$startPoint->{key}}){
			delete($self->{op}->{$startPoint->{key}});
			$self->{cl}->{$startPoint->{key}};
		}
		
		push(@path, $current);
		my $nqueue = List::Priority->new();
		my $dist = {};
		foreach my $neightbor(keys (%{$neightbors})){
			if($self->{cl}->{$neightbor}){
				last;
			}
			$self->{op}->{$neightbor} = 1;
			my $distance = $self->{g} + _distBetween($current, $neightbor, $self->{matrix});
			$nqueue->insert($distance,$neightbor);
			$dist->{$neightbor} = _distBetween($current, $neightbor, $self->{matrix});
		}
		my $maxNeightbor = $nqueue->pop();
		$current = $maxNeightbor;
		if(!$self->{cl}->{$maxNeightbor}){
			$self->{g} += $dist->{$maxNeightbor};
			$self->{alignmentPoint} =  _setPoint($maxNeightbor, $self->{matrix}, $self->{alignmentPoint});
			$self->{iSet}->{$self->{alignmentPoint}->getI()} = 1 if($self->{alignmentPoint}->getI() != $self->{nulli});
			$self->{jSet}->{$self->{alignmentPoint}->getJ()} = 1 if($self->{alignmentPoint}->getJ() != $self->{nullj});
			_setPointPath($maxNeightbor, $self->{matrix}, $self->{alignmentPoint}, $self->{hypoPath});
			$self->{cl}->{$maxNeightbor} = 1;
			delete($self->{op}->{$maxNeightbor});
		}
		last if(scalar(keys %{$neightbors}) == 0);
	}
}
sub getPath
{
	my $self = shift;
	return $self->{hypoPath};
}
sub _penalizeCriterion
{
	my($matrix, $criterion, $ni, $nj) = @_;
	foreach my $i(0..$#{$matrix}){
		foreach my $j(0.. $#{$matrix->[$i]}){
			if($matrix->[$i][$j] < $criterion){ #penalize if is under criterion
				$matrix->[$i][$j] *= -1;
			}

			if($matrix->[$i][$j] == 0 && $i != $ni && $j != $nj){ #penalize 0's to chose null
				$matrix->[$i][$j] = -1;
			}
		}
	}

}
sub _distBetween
{
	my($key, $n, $matrix) = @_;
	my($ki, $kj) = split(/-/, $key);
	my($ni, $nj) = split(/-/, $n);
	my $sum = $matrix->[$ki][$kj] + $matrix->[$ni][$nj];
	return $sum;
}

sub _setPoint
{
	my ($key, $matrix, $point) = @_;
	my ($i, $j) = split(/-/, $key);
	$point->setKey($key);
	$point->setI($i);
	$point->setJ($j);
	$point->setScore($matrix->[$i][$j]);
	return $point;
}

sub _setPointPath
{
	my ($key, $matrix, $point,$hypopath) = @_;
	my $tempPoint = new AlignmentPoint();
	$tempPoint->setI($point->getI());
	$tempPoint->setJ($point->getJ());
	$tempPoint->setScore($point->getScore());
	$tempPoint->setKey($point->getKey()); 
	$hypopath->setAlignmentPoint($tempPoint);
	$hypopath->addScore($tempPoint->getScore());
}

sub _expandNode
{
	my ($parent, $matrix, $ni, $nj, $nullPos) = @_;
	my $neighbors = {};
	#TODO null not affected
	foreach my $i(0..$#{$matrix}){
		foreach my $j(0.. $#{$matrix->[$i]}){
			if(!$ni->{$i} && !$nj->{$j}){
				my $key = $i.'-'.$j;
				$neighbors->{$key} = $matrix->[$i][$j];
			} 
		}
	}
	return $neighbors;
}

sub _setG
{
	my ($g, $key, $matrix) = @_;
	my $result = 0;
	my ($i, $j) = split(/-/, $key);
	$result = $matrix->[$i][$j];
	return $result;
}

sub _computeH
{
	return 0;
}


1;
