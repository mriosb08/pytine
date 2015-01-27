package Meteor;


use strict;
use warnings;
use Encode qw(encode decode);

sub new 
{
	my $class = shift;
	my $Meteor = {@_};

	$Meteor->{path}||= '/media/raid-vapnik/tools/meteor-1.3';
	$Meteor->{text} ||= undef;
	$Meteor->{hypo} ||= undef;
	$Meteor->{command} ||= "java -Xmx2G -jar $Meteor->{path}/meteor-1.3.jar hypo.tmp text.tmp > output.tmp";

    bless $Meteor, $class;
    return $Meteor;
}

sub get_meteor
{
	my ($self, $text, $hypo) = @_;
	
	if($text){
		$self->{text} = $text;
	}

	if($hypo){
		$self->{hypo} = $hypo;
	}
	
	open(my $TEXT, '>text.tmp')or die "file text not found\n";
	open(my $HYPO, '>hypo.tmp')or die "file hypo not found\n";

	print $TEXT "$self->{text}\n";
	print $HYPO "$self->{hypo}\n";

	system($self->{command});
	open(my $OUTPUT, '<output.tmp') or die "file output not found\n";
	my $final_score = 0;
	while(my $line = <$OUTPUT>){
		chomp($line);
		if($line =~ m/Final score:/){
			my($tag_a, $tag_b, $score) = split(/\s+/,$line);
			$final_score = $score;
		}
	}	
	close($TEXT);
	close($HYPO);
	close($OUTPUT);
	unlink("text.tmp");
	unlink("hypo.tmp");
	unlink("output.tmp");
	return $final_score;
}

sub get_meteor_list
{
	my ($self, $text, $hypo) = @_;
	
	if($text){
		$self->{text} = $text;
	}

	if($hypo){
		$self->{hypo} = $hypo;
	}
	
	open(my $TEXT, '>text.tmp')or die "file text not found\n";
	open(my $HYPO, '>hypo.tmp')or die "file hypo not found\n";

	#my @ids = ();
	foreach my $t(keys $self->{text}){
		print $TEXT "$self->{text}->{$t}\n";
		#push(@ids, $t);
	}
	
	foreach my $h(keys $self->{hypo}){
		print $HYPO "$self->{hypo}->{$h}\n";
	}

	system($self->{command});
	open(my $OUTPUT, '<output.tmp') or die "file output not found\n";
	my $final_score = {};
	while(my $line = <$OUTPUT>){
		chomp($line);
		if($line =~ m/Segment/){
			my($tag_a, $line_id, $tag_b, $score) = split(/\s+/,$line);
			#my $id = shift(@ids);
			$final_score->{$line_id} = $score;
		}
	}	
	close($TEXT);
	close($HYPO);
	close($OUTPUT);
	unlink("text.tmp");
	unlink("hypo.tmp");
	unlink("output.tmp");
	return $final_score;
}
1;
