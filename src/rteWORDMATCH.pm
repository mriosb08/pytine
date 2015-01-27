package rteWORDMATCH;
use strict;
use warnings;
use List::Util 'min';
####
my (@in,@un)=();
my %u=();
my %inte=();
my $result=0.0;
####
sub new {
    my $class=shift;
    my $rteWORDMATCH={@_};
      
    $rteWORDMATCH->{text}||="";
    $rteWORDMATCH->{hypothesis}||="";
    $rteWORDMATCH->{let}||=0;
    $rteWORDMATCH->{leh}||=0;
    $rteWORDMATCH->{lei}||=0;
    $rteWORDMATCH->{leu}||=0;
    bless $rteWORDMATCH,$class;
    return $rteWORDMATCH;
}
###SET###
sub setUI{
    my $rteWORDMATCH=shift;
    
    $rteWORDMATCH->{text}=shift;
    $rteWORDMATCH->{hypothesis}=shift;
	
    my @t=@{$rteWORDMATCH->{text}};
    my @h=@{$rteWORDMATCH->{hypothesis}};

  $rteWORDMATCH->{let}=scalar(@t);
  $rteWORDMATCH->{leh}=scalar(@h);

  		my ($i,$j)=0;

		for($i=0;$i<=$#t;$i++)
		{
			$u{$t[$i]}=1;			
		}

		for($j=0;$j<=$#h;$j++)
		{
			if ($u{$h[$j]})
			{ 
				$inte{$h[$j]} =1; 
			} 			
			$u{$h[$j]}=1;			
		}
@un=keys %u;
@in=keys %inte; 

	%u=();
	%inte=();

$rteWORDMATCH->{lei}=scalar(@in);
$rteWORDMATCH->{leu}=scalar(@un); 
#print "$rteWORDMATCH->{lei} ## $rteWORDMATCH->{leu}\n";
}


###GET###
sub getIntersection
{
	my $rteWORDMATCH=shift;
	return \@in; 
}

sub getUnion
{
	my $rteWORDMATCH=shift;
	return \@un; 
}
sub getWordMatch
{
	my $rteWORDMATCH=shift;
return $rteWORDMATCH->{lei};	
}

####SIMILARITY##########

sub getCOSINE
{
	my $rteWORDMATCH=shift;
	if($rteWORDMATCH->{let} != 0 && $rteWORDMATCH->{leh} != 0)
	{
		$result=$rteWORDMATCH->{lei}/sqrt($rteWORDMATCH->{let}*$rteWORDMATCH->{leh});
		#print "hola\n";
	}else
	{
		$result=0.0;
	}
return $result;	
}

sub getDICE
{
	my $rteWORDMATCH=shift;
	if($rteWORDMATCH->{let}!=($rteWORDMATCH->{leh}*-1)&&$rteWORDMATCH->{leh}!=($rteWORDMATCH->{let}*-1))
	{
		$result=(2*$rteWORDMATCH->{lei})/($rteWORDMATCH->{let}+$rteWORDMATCH->{leh});
	}else
	{
		$result=0.0;
	}
return $result;	
}

sub getJACCARD
{
	my $rteWORDMATCH=shift;
        if($rteWORDMATCH->{leu}!=0)
	{
		$result=$rteWORDMATCH->{lei}/$rteWORDMATCH->{leu};
	}else
	{
		$result=0.0;
	}
	
return $result;	
}

sub getOVERLAP
{
	my $rteWORDMATCH=shift;
	if($rteWORDMATCH->{let}!=0&&$rteWORDMATCH->{leh}!=0)
	{
		$result=$rteWORDMATCH->{lei}/min($rteWORDMATCH->{let},$rteWORDMATCH->{leh});
	}else
	{
		$result=0.0;
	}
return $result;	
}

1;
