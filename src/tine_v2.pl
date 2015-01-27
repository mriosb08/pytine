#!/usr/bin/perl

use strict;

use SimsDB;
use List::Util qw/max min/;
use Algorithm::Permute;
use GramsFactory;
use Getopt::Long "GetOptions";
use ColumnReader;


my ($help, $textFile, $hypoFile, $headerFile, $verbose, $blank, $argAnnotationLevel, $bagOfTokens, $useBLEU, $wmt, $testid, $systemid, @additional, $xml, $mln);
$bagOfTokens = 0;
$argAnnotationLevel = 'wordform'; # the annotation level used to compute argument similarity
my $fluencyAnnotationLevel = 'wordform';
my $verbMatchingTh = 0.2;
my $fallbackLowerBLEU = 0;
my $ngram = 4;
my $nbest = 200;

my ($wF, $wA) = (0.5, 0.5);
my ($wlex, $wsrl) = (0.4, 0.6);
$blank = '-';

my $BLEU = "/home/tools/moses/scripts/scripts-20110310-1536/generic/multi-bleu.perl";

$help=1 unless
&GetOptions(
	'T|R=s' => \$textFile,
	'H|MT=s' => \$hypoFile,
	'header=s' => \$headerFile,
	'verbose=i' => \$verbose,
	'v2v=f' => \$verbMatchingTh,
	'bag' => \$bagOfTokens,
	'bleu' => \$useBLEU,
	'fallback' => \$fallbackLowerBLEU,
	'multibleu=s' => \$BLEU,
	'wmt=s' => \$wmt,
	'testid=s' => \$testid,
	'systemid=s' => \$systemid,
	'extra=s' => \@additional,
	'ngram=i' => \$ngram,
	'wa=s' => \$wA,
	'wf=s' => \$wF,
	'xml=s' => \$xml,
	'mln=s' => \$mln,
	'help' => \$help
);

if ($help || not ($textFile and $hypoFile and $headerFile and $xml)){
	print "tine.pl <options>
	--T|R  <file>                   * File containing the Texts or References (conll format)
	--H|MT <file>                   * File containing the Hypotheses or MTs (conll format)
	--header <file>                 * Header of the CONLL files: <column-name> <position> (one pair per line)
	                                Necessary header information: wordform, lemma, target, srl
	--xml <file>                    * Output XML file
	--mln <file>                    * Output pair verb-args file to transform into DB for MLN
	--bag                           Diregards lexical distributional similarity scores in cosine computation
	--v2v <float>                   Verb matching threshold (default: 0.2)
	--ngram <int>                   Maximum n-gram for the fluency component (default: 4)
	--bleu                          Uses BLEU as the fluency component instead of the simple cosine similarity
	--fallback                      Fallback to lower order BLEU in case of zeros
	--multibleu <path>              Path to multibleu (default: $BLEU)

	V2V                             Parameteres controlling the predicate alignment
	--wlex                          Weight of the lexical similarity between verbs (default: 0.4)
	--wsrl                          Weight of the SRL similarity between verbs (default: 0.6)

	TINE
	--wf <float>                    Weight of the fluency component
	--wa <float>                    Weight of the adequacy component

	WMT Stuff
	--wmt <path>                    WMT-formatted output
	--testid <name>                 Name of the test set
	--systemid <name>               Name of the system
	--extra <field>                 Additional columns in the output (must be present in the input file)

	--verbose <level>               Prints log (default: 0)
	--help                          Prints these instructions

	EXAMPLE(RTE): perl -Ireader/ -I/ tine.pl  --bleu --fallback --header rte.header --T RTE_datasets/MLN-PARC/parc_examples.text --H RTE_datasets/MLN-PARC/parc_examples.hypo  --ver 3 --wmt RTE_datasets/MLN-PARC/parc_examples.wmt --testid parc --systemid TINE --xml RTE_datasets/MLN-PARC/parc_examples.ap.xml 2> RTE_datasets/MLN-PARC/parc_examples.log 
	\n";

	exit 1;
}

my $dekangLin = new SimsDB();

my $textReader = new ColumnReader(file => $textFile, trim => 1);
my $hypoReader = new ColumnReader(file => $hypoFile, trim => 1);
my ($tColumns, $hColumns) = ({}, {});
my $header = loadConllFormat($headerFile); #load the format of the conll files (column-name position)

my $pair = 0; #counter of segments
my $LOG;

my $firstSRLColumn;
foreach my $position (keys %$header){
	if($header->{$position} eq 'srl'){
		$firstSRLColumn = $position; # position of the srl structures
		last;
	}
}

my $sumFluency = 0;
my $sumAdequacy = 0;
my $sumTINE = 0;

open (my $WMT, ">:utf8", $wmt) if $wmt;
open (my $XML, ">:utf8", $xml) or die "Could not write output file: $xml\n";
open (my $MLN, ">:utf8", $mln) if $mln;
print $XML "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<pairs>\n" if($xml);
while ($textReader->readNext($tColumns) && $hypoReader->readNext($hColumns)){
	$pair++;
	my $system = adjustColumnNames($hColumns, $header, $firstSRLColumn);
	my $reference = adjustColumnNames($tColumns, $header, $firstSRLColumn);
	print STDERR "$pair: (T) " . $reference->{wordform} . "\n" if $verbose;
	print STDERR "$pair: (H) " . $system->{wordform} . "\n" if $verbose;
	my $fluencySummary = computeFluency($pair, $system, $reference);
	$sumFluency += $fluencySummary->{F};
	printf STDERR "$pair: F(H,R): %.6f\n", $fluencySummary->{F} if $verbose;
	my $adequacySummary = computeAdequacy($pair, $system, $reference, $firstSRLColumn);
	printf STDERR "$pair: A(H,R): %.6f\n", $adequacySummary->{A} if $verbose;
	my $tine = $wF*$fluencySummary->{F} + $wA*$adequacySummary->{A};
	printf STDERR "$pair: TINE(H,R): %.6f\n", $tine if $verbose;
	$sumAdequacy += $adequacySummary->{A};
	$sumTINE += $tine;
	my @id = split(/\s+/, $system->{id});
	my @entailment = split(/\s+/, $system->{entailment});
	my @task = split(/\s+/, $system->{task});
	my $id = $pair;
	if ($id[0]){
		$id = $id[0];
	}
	my $task = $testid;
	if($task[0]){
		$task = $task[0];
	}
	printSummary($id, $system, $reference, $fluencySummary, $adequacySummary, $XML, $entailment[0], $task);
	#printMLN($id, $system, $reference, $fluencySummary, $adequacySummary, $MLN, $entailment[0], $task) if($mln);
	printWMT($WMT, $fluencySummary->{F}, $adequacySummary->{A}, $tine, $id[0], $entailment[0], $adequacySummary->{precision}) if $wmt;
}
print $XML "</pairs>\n" if($xml);

my $fluency = ($pair)?$sumFluency/$pair:0;
my $adequacy = ($pair)?$sumAdequacy/$pair:0;
my $tine = ($pair)?$sumTINE/$pair:0;
print "Total of segments: $pair\n";
printf "Fluency: %.6f (w=$wF)\n", $fluency;
printf "Adequacy: %.6f (w=$wA)\n", $adequacy;
printf "TINE: %.6f\n", $tine;

sub getExtra
{
	my $sys = shift;
	my $extra = [];
	foreach my $field (@additional){
		my ($value) = split(/\s+/, $sys->{$field});
		push(@$extra, $value);
	}
	return $extra;
}

sub printWMT
{
	my ($O, $f, $a, $tine, $pair, $entailment, $precision) = @_;
	print $WMT "$testid $systemid $pair $entailment $tine $f $a $precision\n";
}

sub printSummary
{
	my ($pair, $hyp, $text, $fluency, $adequacy, $O, $entailment, $task) = @_;
	my $hstr = $hyp->{wordform};
	my $tstr = $text->{wordform};
	$hstr = reserved_xml($hstr);
	$tstr = reserved_xml($tstr);
	#TODO to XML for special characters
	#TODO add entailment value and task
	
	printf $O "<pair id=\"$pair\" entailment=\"$entailment\" task=\"$task\" >\n";
	print $O " <T>$tstr</T>\n";
	print $O " <H>$hstr</H>\n";
	printf $O " <F type=\"%s\">%.6f</F>\n", $fluency->{type}, $fluency->{F};
	printf $O " <A precision=\"%.6f\" recall=\"%.6f\">%.6f</A>\n", $adequacy->{precision}, $adequacy->{recall}, $adequacy->{A};
	printf $O " <TINE>%.6f</TINE>\n", $wF*$fluency->{F}+$wA*$adequacy->{A};
	if (@{$adequacy->{tpredicates}} or @{$adequacy->{hpredicates}}){
		my $ntpred = scalar(@{$adequacy->{tpredicates}});
		my $nhpred = scalar(@{$adequacy->{hpredicates}});
		printf $O " <predicates t=\"%d\" h=\"%d\">\n", $ntpred, $nhpred;
		foreach my $v (@{$adequacy->{tpredicates}}){
			$v->[1] = reserved_xml($v->[1]);
			printf $O "  <t at=\"%d\">%s</t>\n", $v->[0], $v->[1];
		}
		foreach my $v (@{$adequacy->{hpredicates}}){
			$v->[1] = reserved_xml($v->[1]);
			printf $O "  <h at=\"%d\">%s</h>\n", $v->[0], $v->[1];
		}
		printf $O " </predicates>\n";
	
		my $predicates = $adequacy->{alignment}->{predicates};
		if (@$predicates){
			printf $O " <alignment score=\"%.6f\">\n", $adequacy->{alignment}->{score};
			my $i = 0;
			foreach my $predicate (@$predicates){
				printf $O "  <v2v id=\"%d\" lex=\"%.6f\" srl=\"%.6f\" combo=\"%.6f\">\n", $i, $predicate->{scoring}->{lex}, $predicate->{scoring}->{srl}, $predicate->{scoring}->{combination};
				printf $O "   <T>\n";
				$predicate->{tv} = reserved_xml($predicate->{tv});
				$predicate->{hv} = reserved_xml($predicate->{hv});
				printf $O "    <vt at=\"%d\">%s</vt>\n", $predicate->{vj}, $predicate->{tv};
				printf $O "    <vh at=\"%d\">%s</vh>\n", $predicate->{vi}, $predicate->{hv};
				printf $O "   </T>\n";
				my $comparisons = $predicate->{comparisons};
				foreach my $type (sort keys %$comparisons){
					#my $pair = $comparisons->{$type};
					my $match = $comparisons->{$type}->{s};
					printf $O "   <ARG type=\"$type\" score=\"%.6f\">\n", $match;
					#printComp($O, $pair)
					#while (my ($harg, $hash) = each %$pair){
					#	while (my ($targ, $match) = each %$hash){
					#		$targ = reserved_xml($targ);
					#		$harg = reserved_xml($harg);
					#		if($type ne ""){
					#			printf $O "   <$type score=\"%.6f\">\n", $match;
					#			printf $O "    <t>%s</t>\n", $targ;
					#			printf $O "    <h>%s</h>\n", $harg;
					#			printf $O "   </$type>\n";
					#		}
							
					#	}
					#}
				#$i++;
					my $h = $comparisons->{$type}->{h};
					my $r = $comparisons->{$type}->{r};
					
					my $pos_h = [];
					push(@$pos_h, $_->{'pos'}) foreach (@$h);
					my $pos_r = [];
					push(@$pos_r, $_->{'pos'}) foreach (@$r);

					my $lemma_h = [];
					push(@$lemma_h, $_->{'lemma'}) foreach (@$h);
					my $lemma_r = [];
					push(@$lemma_r, $_->{'lemma'}) foreach (@$r);

					my $chunk_h = [];
					push(@$chunk_h, $_->{'chunk'}) foreach (@$h);
					my $chunk_r = [];
					push(@$chunk_r, $_->{'chunk'}) foreach (@$r);

					my $ne_h = [];
					push(@$ne_h, $_->{'ne'}) foreach (@$h);
					my $ne_r = [];
					push(@$ne_r, $_->{'ne'}) foreach (@$r);

					my $wf_h = [];
					push(@$wf_h, $_->{'wordform'}) foreach (@$h);
					my $wf_r = [];
					push(@$wf_r, $_->{'wordform'}) foreach (@$r);

					if($type ne ""){
						#printf $O "   <$type score=\"%.6f\">\n", $match;
						printf $O "    <wordform-t>%s</wordform-t>\n", reserved_xml(join(' ', @$wf_r));
						printf $O "    <wordform-h>%s</wordform-h>\n", reserved_xml(join(' ', @$wf_h));
						printf $O "    <lemma-t>%s</lemma-t>\n", reserved_xml(join(' ', @$lemma_r));
						printf $O "    <lemma-h>%s</lemma-h>\n", reserved_xml(join(' ', @$lemma_h));
						printf $O "    <pos-t>%s</pos-t>\n", reserved_xml(join(' ', @$pos_r));
						printf $O "    <pos-h>%s</pos-h>\n", reserved_xml(join(' ', @$pos_h));
						printf $O "    <chunk-t>%s</chunk-t>\n", reserved_xml(join(' ', @$chunk_r));
						printf $O "    <chunk-h>%s</chunk-h>\n", reserved_xml(join(' ', @$chunk_h));
						printf $O "    <ne-t>%s</ne-t>\n", reserved_xml(join(' ', @$ne_r));
						printf $O "    <ne-h>%s</ne-h>\n", reserved_xml(join(' ', @$ne_h));
						printf $O "   </ARG>\n";
					}
									
				}
				printf $O "  </v2v>\n";
			}
			printf $O " </alignment>\n" ;
		}
	}
	printf $O "</pair>\n";
	
}

sub printMLN
{
	my ($id, $hyp, $text, $fluency, $adequacy, $O, $entailment, $task) = @_;
	my $hstr = $hyp->{wordform};
	my $tstr = $text->{wordform};
	#$hstr = reserved_xml($hstr);
	#$tstr = reserved_xml($tstr);
	my $sep = '|||';
	
	my $predicates = $adequacy->{alignment}->{predicates};
	if (@$predicates){
		my $line = "";
		foreach my $predicate (@$predicates){
			$predicate->{tv};
			$predicate->{hv};
			my $comparisons = $predicate->{comparisons};
				foreach my $type (sort keys %$comparisons){
					my $pair = $comparisons->{$type};
					while (my ($harg, $hash) = each %$pair){
						while (my ($targ, $match) = each %$hash){							
							if($type ne ""){
								$line = $id.$sep.$entailment.$sep.$task.$sep.$predicate->{tv}.$sep.$predicate->{hv}.$sep.$predicate->{scoring}->{combination}.$sep.$type.$sep.$match.$sep.$targ.$sep.$harg;
								print $O $line,"\n"; 
							}
							
						}
					}
					
				}
		
		}
	
		
	}
	
	
}



sub reserved_xml
{
	my $string = shift;
	$string =~ s/>/&gt;/g;
	$string =~ s/</&lt;/g;
	$string =~ s/&/&amp;/g;
	$string =~ s/\'/&apos;/g;
	$string =~ s/\"/&quot;/g;
	return $string	
}


sub computeFluency
{
	my ($segment, $sys, $ref) = @_;
	my $hstr = $sys->{$fluencyAnnotationLevel};
	my $tstr = $ref->{$fluencyAnnotationLevel};
	if (not $useBLEU){
		my $hbag = {};
		my $tbag = {};
		my $hgrams = GramsFactory::listGrams($hstr, $ngram);
		my $tgrams = GramsFactory::listGrams($tstr, $ngram);
		$hbag->{$_}++ foreach (@$hgrams);
		$tbag->{$_}++ foreach (@$tgrams);
		my $cosine = cosine($hbag, $tbag);
		return {F => $cosine, type => "cos$ngram"};
	} else{
		#my $htmp = "$hypoFile.seg$segment";
		#my $ttmp = "$textFile.seg$segment";
		#open (my $H, ">:utf8", $htmp) or die "Could not write the file: $htmp\n";
		#print $H "$hstr\n";
		#close $H;
		#open (my $T, ">:utf8", $ttmp) or die "Could not write the file: $ttmp\n";
		#print $T "$tstr\n";
		#close $T;
		#open (my $B,  "$BLEU $ttmp < $htmp 2> /dev/null |") or die "Could not run: $BLEU $ttmp < $htmp\n";
		#my ($bleu, $b1, $b2, $b3, $b4, $bp) = (0,0,0,0,0,0);
		#while (my $line = <$B>){
		#	chomp $line;
		#	print STDERR "$segment: $line (multibleu)\n" if $verbose > 2;
		#	if ($line =~ m/BLEU = ([0-9.]+), ([0-9.]+)\/([0-9.]+)\/([0-9.]+)\/([0-9.]+) \(BP=([0-9.]+)/){
		#		($bleu, $b1, $b2, $b3, $b4, $bp) = ($1, $2, $3, $4, $5, $6);
		#		last;
		#	}
		#}
		my ($score, $type) = BLEU($hstr, $tstr);
		return {F => $score, type => $type};
	}
}

sub BLEU
{
	my ($hstr, $tstr) = @_;
	my ($hGrams, $H) = GramsFactory::groupGrams($hstr, $ngram);
	my ($tGrams, $T) = GramsFactory::groupGrams($tstr, $ngram);
	my @counts = ();
	push(@counts, {total => 0, correct => 0, ratio => 0}) foreach (0 .. $ngram);
	foreach my $n (sort {$a <=> $b} keys %$hGrams){
		my $hg = GramsFactory::count($hGrams->{$n});
		my $tg = GramsFactory::count($tGrams->{$n});
		foreach my $gram (keys %$hg){
			$counts[$n]->{total} += $hg->{$gram};
			if (exists $tg->{$gram}){
				$counts[$n]->{correct} += min($hg->{$gram}, $tg->{$gram});
			}
		}
		printf STDERR "b$n: %d/%d\n", $counts[$n]->{correct}, $counts[$n]->{total};
		$counts[$n]->{ratio} = $counts[$n]->{correct} / $counts[$n]->{total} if $counts[$n]->{total};
	}
	my $hlen = scalar(@$H);
	my $brevityPenalty = ($hlen)?exp(1-scalar(@$T)/$hlen):0;
	
	if ($counts[1]->{ratio} == 0){
		return (0, 'bleu');
	}
	my $max = $ngram;
	if ($fallbackLowerBLEU){
		foreach my $n (2 .. $#counts){
			if ($counts[$n]->{ratio} == 0){
				$max = $n-1;
				print STDERR "b$n is zero, falling back to b$max\n";
				last;
			}
		}
	}
	my $sum = 0;
	foreach my $n (1 .. $max){
		$sum += my_log($counts[$n]->{ratio});
	}
	return ($brevityPenalty*exp($sum/$max), "bleu$max");
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

# Computes the match of predicate arguments (in terms of SRL)
# Input: segment number, system content, reference content, first column containing SRL annotation
# Output: hash {A, matrix, alignment}
# 	A - adequacy score
# 	matrix - verb vs verb similarities
# 	alignment - hash containing the best alignment: score => float, predicates => [{vi => index, vj => index, hv => H predicate, tv => T predicate, comparisons => H arg => T arg => score}]
sub computeAdequacy
{
	my ($segment, $sys, $ref, $srlStart) = @_;
	
	my @sWordforms = split(/\s+/, $sys->{'wordform'});
	my @rWordforms = split(/\s+/, $ref->{'wordform'});
	my @sTargets = split(/\s+/, $sys->{'target'});
	my @rTargets = split(/\s+/, $ref->{'target'});
	my @sLemmas = split(/\s+/, $sys->{'lemma'});
	my @rLemmas = split(/\s+/, $ref->{'lemma'});
	#my @sPos = split(/\s+/, $sys->{'pos'});
	#my @rPos = split(/\s+/, $ref->{'pos'});
	#my @sCh = split(/\s+/, $sys->{'chunk'});
	#my @rCh = split(/\s+/, $ref->{'chunk'});
	#my @sNe = split(/\s+/, $sys->{'ne'});
	#my @rNe = split(/\s+/, $ref->{'ne'});
	

	# finds the predicates
	my ($hverbs, $hverbs_lemma) = findPredicates(\@sTargets, \@sLemmas);
	my ($rverbs, $rverbs_lemma) = findPredicates(\@rTargets, \@rLemmas);
	my $rNOfVerbs = scalar(@$rverbs);
	my $hNOfVerbs = scalar(@$hverbs);
	my $matrix = {};
	my $alignments = {score => 0, predicates => []};
	my $sumPredicateScore = 0;
	
	

	if ($hNOfVerbs > 0 and $rNOfVerbs > 0){ # if both the system and the references have targets
		my $vis = {};
		my $vjs = {};
		foreach my $i (0 .. $#{$hverbs}){
			my $iAbsolut = $hverbs->[$i]->[0];
			my ($hi, $hiLemma) = (lc($sWordforms[$iAbsolut]), lc($sLemmas[$iAbsolut]));
			$matrix->{$i} = {};
			foreach my $j (0 .. $#{$rverbs}){
				my $jAbsolut = $rverbs->[$j]->[0];
				my ($rj, $rjLemma) = (lc($rWordforms[$jAbsolut]), lc($rLemmas[$jAbsolut]));
				my $lexScore = lexicalSimilarity({wordform => $hi, lemma => $hiLemma}, {wordform => $rj, lemma => $rjLemma}, $bagOfTokens);
				my ($srlRecall, $srlPrecision, $srlComparisons) = srlSimilarity($sys, $ref, $i, $j, $bagOfTokens);
				my $srlScore = $srlRecall;
				my $combination = $wlex*$lexScore+$wsrl*$srlScore;
				my $discarded = 1;
				$combination = sprintf("%.6f", $combination);
				if ($combination > 0 and ((not defined $verbMatchingTh) or ($combination >= $verbMatchingTh))){
					$discarded = 0;
					$vis->{$i} = 1;
					$vjs->{$j} = 1;
					$matrix->{$i}->{$j} = {lex => $lexScore, srl => $srlScore, srlRecall => $srlRecall, srlPrecision => $srlPrecision, combination => $combination, comparisons => $srlComparisons}; 
				}
				print STDERR "$segment: $hi - $rj: lex=$lexScore srlRecall=$srlRecall srlPrecision=$srlPrecision srl=$srlScore score=$combination discarded=$discarded\n" if $verbose > 2;
			}
		}
		my $best = enumerateAllHypothesizedAlignments($vis, $vjs, $matrix, 'combination');
		if (defined $best){
			my $score = $best->{score};
			my $points = $best->{alignment};
			$alignments->{score} = $score;
			print STDERR "$segment: verb-alignment ($score)\n" if $verbose > 1;
			foreach my $point (@$points){
				my ($i, $j) = ($point->{i}, $point->{j});
				my $hv = $sLemmas[$hverbs->[$i]->[0]];
				my $rv = $rLemmas[$rverbs->[$j]->[0]];
				
				printf STDERR "\t$hv -- $rv (lex=%.4f/srl=%.4f/%.6f)\n", $matrix->{$i}->{$j}->{lex}, $matrix->{$i}->{$j}->{srl}, $matrix->{$i}->{$j}->{combination} if $verbose > 1;
				$sumPredicateScore += $matrix->{$i}->{$j}->{srl};
				my $comparisons = $matrix->{$i}->{$j}->{comparisons};
				push(@{$alignments->{predicates}}, {vi => $hverbs->[$i]->[0], vj => $rverbs->[$j]->[0], hv => $hv, tv => $rv, comparisons => $comparisons, scoring => $matrix->{$i}->{$j}});
			}
			#if ($verbose > 1){
			#	foreach my $point (@{$best->{iunaligned}}){
			#		my $i = $point->{i};
			#		my $hv = $sTargets[$hverbs->[$i]->[0]];
			#		printf STDERR "\t$hv [h-unaligned]\n";
			#	}
			#	foreach my $point (@{$best->{junaligned}}){
			#		my $j = $point->{j};
			#		my $rv = $rTargets[$rverbs->[$j]->[0]];
			#		printf STDERR "\t$rv [t-unaligned]\n";
			#	}
			#}
		}
	}else{
		print STDERR "$segment: hypo($hNOfVerbs) vs ref($hNOfVerbs) - not enough targets\n" if $verbose;
	}
	
	my $recall = ($rNOfVerbs != 0)?$sumPredicateScore/$rNOfVerbs:0;
	my $precision = ($hNOfVerbs != 0)?$sumPredicateScore/$hNOfVerbs:0;
	my $adequacy = $recall;
	return {A => $adequacy, recall => $recall, precision => $precision, alignment => $alignments, hpredicates => $hverbs_lemma, tpredicates => $rverbs_lemma};
}

# Finds the similarity in terms of the SRL structure
# Input: system, reference, position of argument in system, position of argument in reference
# Output: score, history of comparisons  
sub srlSimilarity
{
	my ($sys, $ref, $position_sys, $position_ref, $bag) =  @_;

	my $H = transpose({
		wordform => $sys->{'wordform'}, lemma => $sys->{'lemma'}, pos => $sys->{'pos'}, chunk => $sys->{'chunk'}, ne => $sys->{'ne'}, srl => $sys->{"srl-$position_sys"} 
	});
	my $R = transpose({
		wordform => $ref->{'wordform'}, lemma => $ref->{'lemma'}, pos => $ref->{'pos'}, chunk => $ref->{'chunk'}, ne => $ref->{'ne'}, srl => $ref->{"srl-$position_ref"} 
	});

	my $hArgs = {};
	my $rArgs = {};

	# Attaches words to arguments 
	# a) in hyp
	foreach my $hi (@$H){
		if($hi->{srl} !~ m/^\w+\-V$/ && $hi->{srl} !~ m/^O$/){ # if is not a verb or empty
			$hi->{srl} =~ m/^\w+\-(.*)$/; #extract argument
			my $argument = $1;
			$hArgs->{$argument} = [] unless $hArgs->{$argument};
			push(@{$hArgs->{$argument}}, $hi); 
		}
	}
	# b) in ref
	foreach my $ri (@$R){
		if($ri->{srl} !~ m/^\w+\-V$/ && $ri->{srl} !~ m/^O$/){ # if is not a verb or empty
			$ri->{srl} =~ m/^\w+\-(.*)$/; #extract argument
			my $argument = $1;
			$rArgs->{$argument} = [] unless $rArgs->{$argument};
			push(@{$rArgs->{$argument}}, $ri); 
		}
	}

	

	# Compares all arguments 
	my $comparison = {};
	
	my $sumArgumentScore = 0;
	foreach my $harg (keys %$hArgs){
		if(exists $rArgs->{$harg}){ # if the two structures contain the same argument type (eg A0, A1, etc)
			my ($argScore, $hstr, $rstr) = compareArguments($hArgs->{$harg}, $rArgs->{$harg}, $bag);
			$sumArgumentScore += $argScore;
			$comparison->{$harg} = {};
			$comparison->{$harg}->{h} = $hArgs->{$harg};
			$comparison->{$harg}->{r} = $rArgs->{$harg};
			$comparison->{$harg}->{s} = $argScore;
			#$comparison->{$harg}->{$hstr} = {} unless $comparison->{$harg}->{$hstr};
			#$comparison->{$harg}->{$hstr}->{$rstr} = $argScore;			
		}
	}
	my $nOfRefArgs = scalar(keys %$rArgs);
	my $nOfHypArgs = scalar(keys %$hArgs);
	my $precision = ($nOfHypArgs)?$sumArgumentScore/$nOfHypArgs:0;
	my $recall = ($nOfRefArgs)?$sumArgumentScore/$nOfRefArgs:0;
	return ($recall, $precision, $comparison);
}

# Computes the lexical similarity
#	if 'bag' is on then the cosine will use just bag of words
#	if 'bag' is off then the cosine will take the Dekank Lin's similarity into consideration
# Input: hyp, ref, bag
# Output: similarity score
sub lexicalSimilarity
{
	my ($h, $r, $bag) = @_;
	my $sim = 0;
	if ($h->{wordform} eq $r->{wordform} or $h->{lemma} eq $r->{lemma}){
		$sim = 1;
	} else{
		my $hmatches = $dekangLin->findMatches($h->{wordform});
		my $rmatches = $dekangLin->findMatches($r->{wordform});
		$sim = cosine($hmatches, $rmatches, $bag);
	}
	return $sim;
}

# Computes the cosine of two bags if 'bag' is on or of two vectors if 'bag' is off
# Input: two hashes (hyp and ref) and the flag
# Output: cosine score
sub cosine
{
	my ($h, $r, $bag) = @_;
	my $inter = intersectionOfHashes($h, $r);
	my ($num, $denh, $denr) = (0,0,0);
	if ($bag){
		$num = scalar(keys %$inter);
		$denh = scalar(keys %$h);
		$denr = scalar(keys %$r);
	} else{
		foreach my $k (keys %$inter){
			$num += $h->{$k}*$r->{$k};
		}
		while (my ($k, $v) = each %$h){
			$denh += $v*$v;
		}
		while (my ($k, $v) = each %$r){
			$denr += $v*$v;
		}
	}
	if ($denh and $denr){
		return $num/(sqrt($denh*$denr));
	} else{
		return 0;
	}
}

# Finds the intersection of two hashes
# Input: two hashes
# Output: a hash containing the elements in the intersection of the input hashes
sub intersectionOfHashes
{
	my ($a, $b) = @_;
	($a, $b) = ($b, $a) if (scalar(keys %$b) < scalar(keys %$a));
	my $inter = {};
	foreach my $k (keys %$a){
		$inter->{$k} = 1 if exists $b->{$k}
	}
	return $inter;
}

# Transpose the data in the CONLL table
# Input: a CONLL-like table
# Output: its transposed version
sub transpose
{
	my $table = shift;
	my $data = {};
	my $n = 0;
	my @features = keys %$table;
	foreach my $feature (@features) {
		my @v = split(/\s+/,$table->{$feature});
		$n = max($n, scalar(@v));
		$data->{$feature} = [@v];
	}
	my $transposed = [];
	foreach my $i (0 .. $n-1){
		my $line = {};
		push(@$transposed, $line);
		foreach my $feature (@features){
			$line->{$feature} = $data->{$feature}->[$i];
		}
	}
	return $transposed;
}

# Computes arg_score (Rios et al, 2011) by finding the average pointwise lexical similarity
# Input: hypo's arg, ref's arg, bag (if bag is on similarity scores will be disregarded)
# Output: similarity score, the hyp span and the ref span
sub compareArguments
{
	my ($hArg, $rArg, $bag) = @_;
	my $level = $argAnnotationLevel; 
	# Retrieves the annotation for the chosen level
	my $h = [];
	push(@$h, $_->{$level}) foreach (@$hArg);
	my $r = [];
	push(@$r, $_->{$level}) foreach (@$rArg);
	# Stringfies the annotation
	my $strh = join(' ', @$h);
	my $strr = join(' ', @$r);
	
	# Compares
	my $sim = 0;
	if ($strh eq $strr){
		$sim = 1;
	} else{
		my $hnorm = [];
		foreach my $hi (@$h){
			my $dist = $dekangLin->findMatches($hi, 1);
			push(@$hnorm, $dist);
		}
		my $rnorm = [];
		foreach my $ri (@$r){
			my $dist = $dekangLin->findMatches($ri, 1);
			push(@$rnorm, $dist);
		}
		my $n = 0;
		foreach my $hi (@$hnorm){
			my $partial = 0;
			foreach my $rj (@$rnorm){
				$partial = max($partial, cosine($hi, $rj, $bag));
			}
			$sim += $partial;
			$n++;
		}
		$sim /= $n if $n;
	}
	return ($sim, $strh, $strr);
}


# TODO: optimize this procedure
# Enumerates the n-best possible predicate alignments
# Input: verbs in the hypo, verbs in the ref, the verb-to-verb similarity matrix and the similarity criterion
# Output: a list of n-best alignments (each entry is a pair: a list of points and a score)
sub enumerateAllHypothesizedAlignments
{
	my ($is, $js, $matrix, $criterion) = @_;
	my @ivalues = keys %$is;
	my @jvalues = keys %$js;
	my ($n, $m) = (scalar(@ivalues), scalar(@jvalues));
	if ($n > 10 or $m > 10){
		warn "Skipping enumeration: $n vs $m\n";
		return {alignment => [], score => 0, sum => 0, n => 0};
	}
	my $shift = 0;
	if ($m < $n){
		($n, $m) = ($m, $n);
		$shift = 1;
	}
	my @candidates;
	print STDERR "\tCombinatorics: $n samples from $m points\n" if $verbose > 3;
	return undef unless $n and $m;
	my $result = {alignment => [], score => 0, sum => 0, n => 0};
	my $permutator = new Algorithm::Permute([0 .. $m-1], $n);
	while(my @combo = $permutator->next()){
		print STDERR "\t\tpermutation: " . join(', ', @combo) . "\n" if $verbose > 4;
		my $score = 0;
		my $alignment = [];
		foreach my $imap (0 .. $#combo){
			my $jmap = $combo[$imap];
			my ($i, $j);
			if (not $shift){
				$i = $ivalues[$imap];
				$j = $jvalues[$jmap];
				$score += $matrix->{$i}->{$j}->{$criterion};
			} else{
				$i = $ivalues[$jmap];
				$j = $jvalues[$imap];
				$score += $matrix->{$i}->{$j}->{$criterion};
			}
			push(@$alignment, [$i, $j]);
		}
		push(@candidates, [$alignment, $score]); # TODO: normalize score, maybe score/$n?
	}
	my ($best) = sort {$b->[1] <=> $a->[1]} @candidates;
	$result->{n} = 0;
	foreach my $point (@{$best->[0]}){
		$result->{n}++;
		my ($i, $j) = @$point;
		push(@{$result->{alignment}}, {key => "$i-$j", i => $i, j => $j, score => $matrix->{$i}->{$j}->{$criterion}});
	}
	$result->{sum} = $best->[1];
	$result->{score} = ($result->{n})?$result->{sum}/$result->{n}:0;
	return $result;
}

sub enumerateNBestHypothesizedAlignments
{
	my ($matrix, $criterion, $nbest) = @_;
	my $inverted = {};
	my $jtodo = {};
	my $iunaligned = [];
	my $junaligned = [];
	my $solution = [];
	my $points = [];
	foreach my $i (keys %$matrix){
		foreach my $j (keys %{$matrix->{$i}}){
			if ($matrix->{$i}->{$j}->{$criterion} >= $verbMatchingTh){
				$inverted->{$j} ||= {};
				$inverted->{$j}->{$i} = $matrix->{$i}->{$j};
			}
		}
	}
	foreach my $i (sort {$a <=> $b} keys %$matrix){
		my $js = $matrix->{$i};
		my $jopts = [];
		foreach my $j (keys %$js){
			$jtodo->{$j} = 1;
			if ($js->{$j}->{$criterion} >= $verbMatchingTh){
				print STDERR "i=$i may align to j=$j\n";
				push(@$jopts, $j);
			}
		}
		my $ncandidates = scalar(@$jopts);
		if ($ncandidates == 0){
			print STDERR "i=$i has no candidates\n";
			push(@$iunaligned, {key => "$i-", i => $i, j => undef, score => 0});
		} else{
			my $done = 0;
			if ($ncandidates == 1){
				my $j = $jopts->[0];
				print STDERR "i=$i can only align to j=$j\n";
				if (scalar(keys %{$inverted->{$j}}) == 1){
					print STDERR "j=$j can only align to i=$i\n";
					push(@$solution, {key => "$i-$j", i => $i, j => $j, score => $js->{$j}->{$criterion}});
					$done = 1;
				}
			}
			if (not $done){
				foreach my $j (@$jopts){
					push(@$points, {key => "$i-$j", i => $i, j => $j, score => $js->{$j}->{$criterion} });
				}
			}
		}
	}

	my $hypotheses = [];
	my $skip = {};
	foreach my $n (1 .. $nbest){
		my $first = pickBest($points, $skip);
		print STDERR "first=" . $first->{key} . " (" . $first->{score} . ")\n";
		if (defined $first){
			my $alignment = [$first];
			my $iused = {$first->{i} => 1};
			my $jused = {$first->{j} => 1};
			my $sum = 0;
			while (my $point = pickNextBest($points, $iused, $jused)){
				print STDERR "+" . $point->{key} . " (" . $point->{score} . ")\n";
				push(@$alignment, $point);
				$sum += $point->{score};
			}
			my $npoints = scalar(@$alignment);
			my $score = 0;
			$score = $sum/$npoints if $npoints;
			print STDERR "total=$sum/$npoints=$score\n";
			push(@$hypotheses, {alignment => $alignment, score => $score, sum => $sum, n => $npoints});
		} else{
			last;
		}
	}
	my ($best) = sort {$b->{score} <=> $a->{score}} @$hypotheses;
	$best ||= {alignment => [], score => 0, sum => 0, n => 0};
	foreach my $p (@$solution){
		push(@{$best->{alignment}}, $p);
		$best->{sum} += $p->{score};
		$best->{n}++;
	}
	$best->{score} = $best->{sum}/$best->{n} if $best->{n};
#	foreach my $p (@{$best->{alignemnt}}){
#		delete $jtodo->{$p->{j}};
#	}
#	foreach my $j (keys %$jtodo){
#		print STDERR "j=$j has is unaligned\n";
#		push(@$junaligned, {key => "-$j", i => undef, j => $j, score => 0});
#	}
#	$best->{iunaligned} = $iunaligned;
#	$best->{junaligned} = $junaligned;
	return $best;
}

sub pickBest
{
	my ($points, $skip) = @_;
	foreach my $p (sort {$b->{score} <=> $a->{score}} @$points){
		if (not $skip->{$p->{key}}){
			$skip->{$p->{key}} = $p; #splice(@a, offset, length)
			return $p;
		}
	}
	return undef;
}

sub pickNextBest
{
	my ($points, $iused, $jused) = @_;
	foreach my $p (sort {$b->{score} <=> $a->{score}} @$points){
		if (not($iused->{$p->{i}} or $jused->{$p->{j}})){
			$iused->{$p->{i}} = $p;
			$jused->{$p->{j}} = $p;
			return $p;
		}
	}
	return undef;
}

# Normalizes a distribution
# Input: hash
# Output: normalized hash
sub normalize
{
	my $dist = shift;
	my $acc = 0;
	my @points = keys %$dist;
	my $normalized = {};
	foreach my $point (@points){
		my $value = $dist->{$point};
		$acc += $value;
		$normalized->{$point} = $value;
	}
	foreach my $point (keys %$normalized){
		$normalized->{$point} /= $acc;
	}
	return $normalized;
}

# Changes positions to identifiers in columns
# 	SRL columns are indexed as srl-i where 'i' is a zero-based index
# Input: CONLL table, CONLL header, position of the first SRL column
# Output: CONLL table (renamed)
sub adjustColumnNames
{
	my ($indata, $header, $srlStart) = @_;
	my $outdata = {};
	my $i=0;
	foreach my $column (sort { $a <=> $b } keys %$indata){
		my $feature = $header->{$column}; #change positions to names
		if($column >= $srlStart){
			$outdata->{"srl-$i"} = $indata->{$column};
			$i++;
		}else{
			$outdata->{$feature} = $indata->{$column};
		}
	}
	return $outdata;
}

# Loads the CONLL header
# Input: file whit columns and positions
# Output: hash: position -> column_name
sub loadConllFormat
{
	my $file = shift;
	open(my $IN, "<:utf8", $file) or die "Could not open file: $file\n";
	my $map = {};
	while (my $line = <$IN>){
		chomp($line);
		if($line !~ m/^#/){
			my ($id, $position) = split(/\s+/,$line);
			$map->{$position} = $id;
		}
	}
	close $IN;
	return $map;
}

# Finds the verb predicates
# Input: target column (from CONLL table)
# Output: predicate positions
sub findPredicates
{
	my ($targets, $lemmas) = @_;
	my $predicates = [];
	my $plemmas = [];
	my $verbs = [];
	foreach my $i (0 .. $#{$targets}){
		next if ($targets->[$i] eq $blank);
		push(@$predicates, [$i, $targets->[$i]]);
		push(@$plemmas, [$i, $lemmas->[$i]]);
	}
	return $predicates, $plemmas;
}
