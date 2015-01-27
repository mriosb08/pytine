#!/usr/bin/perl

use strict;

use vnSQL;
use voDB;
use simsDB;
use lpDB;
use List::Util qw(max);
use rteWORDMATCH;
#

use Getopt::Long "GetOptions";
use ColumnReader;


my ($help,$reference,$system,$verbnet,$verbOcean,$log,$conll_config,$verbose,$blank,$type,$arg_content,$lang_pair,$test_set,$system_id,$alpha,$beta,$final_score_type,$train,$back,$fluency,$gamma);

my (%reference,%system,%conll) = ();
$verbose = 1;
$type = 'thesaurus-cos';	 #arg eval measure thesaurus
$arg_content = 'word'; 	 #conten of args, words
$alpha = 1; #fluency adequacy weights
$beta = 0.25;
$gamma = 0.25;

$train = 0;
$back = 0;
$fluency = 'token-cosine';
my @vo_relations = ('can-result-in',
		'happens-before',
		'low-vol',
		'opposite-of',
		'similar',
		'stronger-than',
		'unk',
		);

$help=1 unless
&GetOptions(
	'reference=s' => \$reference,
	'system=s' => \$system,
	'conll-format=s' => \$conll_config,
	'alpha=s' => \$alpha,
	'beta=s' => \$beta,
	'argument-measure=s' => \$type,
	'argument-content=s' => \$arg_content,
	'final-score=s' => \$final_score_type,
	'lang-pair=s' => \$lang_pair,
	'test-set=s' => \$test_set,
	'system-id=s' => \$system_id,
	'fluency=s' => \$fluency,
	'back'=> \$back,
	'gamma'=> \$gamma,
	'train' => \$train,
	'verbose' => \$verbose,	
	'help' => \$help
);



if ($help || !$reference || !$system || !$conll_config || !$lang_pair || !$test_set || !$system_id){
	print "tine.pl <options>\n\n",
		"\t--reference	<file>                         file with reference sentences (conll format)\n",
		"\t--system	<file>                         file with system sentences (conll format)\n",
		"\t--lang-pair	<string>                       string with the language pair\n",
		"\t--test-set	<string>                       string with the id of the test set\n",
		"\t--system-id	<string>                       string with the id of the system to be tested\n",
		"\t--conll-format	<file>                 file with the information about the conll columns (column-name position)\n",
		"\t--argument-measure	<string>               type of argument similarity measure, types: thesaurus, lp, thesausurs-cos (default:thesaurus+cos)\n",
		"\t--argument-content	<string>	       type of content for eval arguments, types word,lemma (default: word)\n",
		"\t--alpha		<num>		       the fluency parameter implies wa as final_score (default: 1)\n",
		"\t--beta		<num>		       the adequacy parameter implies wa as final_score (default: 0.5)\n",
		"\t--gamma		<num>		       the adequacy parameter implies wa as final_score (default: 0.25)\n",
		"\t--fluency-type	<string>               type of fluency: chunks, token-cosine\n",
		"\t--train				       output for training data, adequacy and fluency intead of final-score\n",
		"\t--back				       use fluency as backoff NEW TODO!!!\n",
		"\t--verbose	<level>                        print log (default: 1)\n",
		"\t--help              	                       print these instructions\n\n",
		"EXAMPLE: perl -Ireader tine.pl --reference example/newssyscombtest2011-ref.en.sgm.srl.tt --system example/newssyscombtest2011.es-en.alacant.sgm.srl.tt --conll-format conll_config.txt --lang-pair es-en --test-set newssyscombtest --system-id alacant\n";

	exit 1;
}

$log = "$system.match.log";
$blank = '-';



my $columnReader_reference = new ColumnReader(file => $reference, trim => 1);
my %columns_reference;

my $columnReader_system = new ColumnReader(file => $system, trim => 1);
my %columns_system;
my $LOG;
if($verbose){
	open($LOG,">",$log) or die "Could not open file: $log\n"; #log
}
open(my $OUT,">","$system.match.$type.segment.out") or die "Could not open file: $system.match.$type.segment.out\n"; #output
open(my $OUT_S,">","$system.match.$type.system.out") or die "Could not open file: $system.match.$type.system.out\n"; #output

&loadConllFormat($conll_config); #load the format of the conll files (column-name position)

my $segment = 0; #counter of segments
my $sum_system = 0;
my $doc_flag = 0;

while ($columnReader_reference->readNext(\%columns_reference) && $columnReader_system->readNext(\%columns_system)){
	
	$segment++;

	my $srl_start;
	my $segment_score = 0;
	my $adequacy_score = 0;
 	my $fluency_score = 0;

	foreach my $key(keys(%conll)){
		if($conll{$key} eq 'srl'){
			$srl_start = $key; # position of the srl structures
		}
	}
	
		
	###fill system hash
	my $i=0;
	foreach my $column_s(sort keys(%columns_system)){
		my $feature = $conll{$column_s}; #change positions to names
		
		if($column_s >= $srl_start){
			
			$system{"srl-$i"} = $columns_system{$column_s};			
			$i++;	
		}else{
			$system{$feature} = $columns_system{$column_s};
			
		}
	}
	
	###fill ref hash
	$i=0;
	foreach my $column_r(sort keys(%columns_reference)){
		my $feature = $conll{$column_r}; #change positions to names
		
		if($column_r >= $srl_start){
			
			$reference{"srl-$i"} = $columns_reference{$column_r};
			$i++;
				
		}else{
			$reference{$feature} = $columns_reference{$column_r};
		}
	}
	#if the system has doc-id
	if(exists($system{'doc_id'})){
		$doc_flag = 1;
	}
	
	###################################	
	if($verbose){
		print $LOG "SEGMENT: $segment\n";		
		print $LOG "\tREFERENCE: $reference{'word'}\n";
		
		print $LOG "\tSYSTEM: $system{'word'}\n";
		
	}
	
	###Processing#####

	###Fluency#######
	if($fluency eq 'chunks'){
		$fluency_score = chunk_matcher($segment,\%system,\%reference);
	}elsif($fluency eq 'token-cosine'){
		$fluency_score = token_cosine($segment,\%system,\%reference);
	}
	print $LOG "SEGMENT: $segment\tfluency = $fluency_score\n" if ($verbose);
	
	#################
	###Adequacy#######
	
	print $LOG "SEGMENT: $segment\tref_targets = $reference{'target'}\n" if ($verbose);
	print $LOG "SEGMENT: $segment\tsys_targets = $system{'target'}\n" if ($verbose);

	my ($frame_recall,$argument_precision) = srl_matcher($segment,\%system,\%reference,$srl_start); #adequacy, if no targets 0

		
	##################
	my $final_score = 0;
	
		
	$final_score = ($alpha*$fluency_score)+($beta*$frame_recall)+($gamma*$argument_precision); 

	print $LOG "SEGMENT: $segment\tfinal_score = $final_score \n" if ($verbose);
	print $LOG "\n" if($verbose);
	
	if($doc_flag == 0){ #id there is no doc_id just consecutive segments
		print $OUT "TINE-srl_match\t$lang_pair\t$test_set\t$system_id\t$segment\t$final_score\n";
	}else{
		my ($doc,@col_d) = split(/\s+/,$system{'doc_id'});
		my ($seg,@col_s) = split(/\s+/,$system{'segment'});
		#print "id: $system{'doc_id'}\n$system{'segment'}\n";
		if($train){ #if the user wants to train the alpha and beta parameters
			print $OUT "TINE-srl_match\t$lang_pair\t$test_set\t$system_id\t$doc\t$seg\t$final_score\t$fluency_score\t$frame_recall\t$argument_precision\n";
		}else{
			print $OUT "TINE-srl_match\t$lang_pair\t$test_set\t$system_id\t$doc\t$seg\t$final_score\n";
		}
		
	}

	$sum_system += $final_score;

	%system = ();
	%reference = ();
	
}

$sum_system = $sum_system/$segment;
print $LOG "SYSTEM_SCORE: $sum_system\n" if($verbose);
print $OUT_S "TINE-srl_match\t$lang_pair\t$test_set\t$system_id\t$sum_system\n";
########
# Input: file whit columns and positions
# Output: hash: key->column-name data-> position

sub loadConllFormat
{
	my($conll_file) = shift;

	open(my $FILE,"<",$conll_file) or die "Could not open file: $conll_file\n";
	while (my $line = <$FILE>){
		chomp($line);		
		if($line !~ m/^#/){
			my($col_name,$position) = split(/\s+/,$line);			
			$conll{$position} = $col_name;
		}
	}
	
}
###########
# Input: segment number, system content, reference content, start of srl
# Output: align matrix ??
#
#
sub srl_matcher
{
	my($segment,$sys,$ref,$srl_start) = @_;
	#first extract targets
	my @targets_sys = split(/\s+/,$sys->{'target'});
	my @targets_ref = split(/\s+/,$ref->{'target'});
	
	my $overall_result = 0;
	my $frame_recall = 0;
	my $argument_precision = 0;
	my $alpha_recall = 0.5;
 
	my @lemma_sys = split(/\s+/,$sys->{'lemma'});
	my @lemma_ref = split(/\s+/,$ref->{'lemma'});

	my %verb_matrix = ();
	my $v_i = 0;
	my $v_j = 0;
	my $num_of_cols_sys = keys(%{$sys});
	my $num_of_cols_ref = keys(%{$ref});	
	my $num_of_verbs = 0;
	my $args_sum = 0;
	my $num_of_args = 0;
	if($srl_start+1 <= $num_of_cols_sys && $srl_start+1 <= $num_of_cols_ref){ #if the system and ref has targets
	#second aling targets using lemmas
		foreach my $i(0..$#targets_sys){ #foreach target of the system compare it to each target of the reference

			next if($targets_sys[$i] eq $blank);
				my $verb_sys = $lemma_sys[$i];
				
			foreach my $j(0..$#targets_ref){

				next if($targets_ref[$j] eq $blank);		
					my $verb_ref = $lemma_ref[$j];
					my $result = 0;
					if($verb_sys eq $verb_ref){ #if the verbs are the same
						$result = 1;
						print $LOG "SEGMENT: $segment\t$verb_sys eq $verb_ref\n" if ($verbose);
					}else	#how related they are using verbnet and verbocean
					{
						print $LOG "SEGMENT: $segment\tverbs: $verb_sys,$verb_ref\n" if ($verbose);
						$result = verbDecision($verb_sys,$verb_ref,$segment);
						
						
					}
					if($result == 1){ #compare srl structures
						
						
						my $num_of_matched_args = get_matched_Args($sys,$ref,$v_i,$v_j,$segment,$verb_sys,$verb_ref);
						$frame_recall += ($alpha_recall*1)+((1-$alpha_recall)*1*$num_of_matched_args);

						my $args_similarity = get_args_similarity($sys,$ref,$v_i,$v_j,$segment,$verb_sys,$verb_ref,\$num_of_args);
						$argument_precision += $args_similarity;						
						
						
					}else{
						$frame_recall += 0;
					}
				
					
					$v_j++; #verb ref number
							
			}
			$v_j = 0;
			$v_i++; #verb system number
		}
		$v_i = 0;
	
	}else{
		print $LOG "SEGMENT: $segment\tSYSTEM or REF has no targets\n" if ($verbose);
		###
		return (0,0);
	}
	#count verbs in reference
	foreach my $j(0..$#targets_ref){
		next if($targets_ref[$j] eq $blank);
		$num_of_verbs++;
	}

	
	if($num_of_verbs != 0){
		$frame_recall = $frame_recall/$num_of_verbs;
	}else{
		$frame_recall = 0;
	}
	print $LOG "SEGMENT: $segment\tFR:$frame_recall NUM_V:$num_of_verbs\n";
	if($num_of_args != 0){
		$argument_precision = $argument_precision/$num_of_args;
	}else{
		$argument_precision = 0;
	}
	print $LOG "SEGMENT: $segment\tAP:$argument_precision NUM_A:$num_of_args\n";
	return ($frame_recall,$argument_precision);	
}
#########
#In: verb a verb b
#Out: 1 if they are related 0 otherwise
####

sub verbDecision
{
	my($verb_sys,$verb_ref,$segment) = @_;	
	$verb_sys =~ s/'/\\'/g;
	$verb_ref =~ s/'/\\'/g;	
	my $vn = new vnSQL(); #verbnet interface
	
	my $vn_result = $vn->getIclass($verb_sys,$verb_ref);
	
	
	if($vn_result == 1){  		#the main decision is from verbnet
		print $LOG "SEGMENT: $segment\tverbs eq decision taken by VerbNet\n" if ($verbose);
		return 1;
		
	}else{ 				#backoff from verbOcean
		my $vo = new voDB();
		$vo->setVerbs($verb_sys,$verb_ref);
		my $vo_relation = $vo->getRelation();
	
		if($vo_relation eq 'opposite-of' || $vo_relation eq 'unk'){
		print $LOG "SEGMENT: $segment\tverbs ne decision taken by VerbOcean\n" if ($verbose);
			return 0;			
		}else{
		print $LOG "SEGMENT: $segment\tverbs eq decision taken by VerbOcean\n" if ($verbose); 
			return 1; # we take all the other relations as similar			
		}
		
	}	
		 
}


sub chunk_matcher
{
	my ($segment,$sys,$ref) = @_;
	#fisrt extract chunks
	
	#my (%chunks_sys, %chunks_ref)= ();
	my (@chunks_sys, @chunks_ref)= ();	
	#tie %chunks_sys, "Tie::IxHash";
	#first extract words
	my @content_sys;
	my @content_ref;
	#TODO later put option to lemmas
	if($arg_content eq 'word'){
		@content_sys = split(/\s+/,$sys->{'word'});
		@content_ref = split(/\s+/,$ref->{'word'});
	}elsif($arg_content eq 'lemma')
	{
		@content_sys = split(/\s+/,$sys->{'lemma'});
		@content_ref = split(/\s+/,$ref->{'lemma'});
		
	}
	
	my @pos_sys = split(/\s+/,$sys->{'pos'});
	my @pos_ref = split(/\s+/,$ref->{'pos'});

	#second extract srl (srl starts at 0)
	
	my @chunk_sys = split(/\s+/,$sys->{'chunk'});
	my @chunk_ref = split(/\s+/,$ref->{'chunk'});
	
	print $LOG "SEGMENT: $segment\t sys: @chunk_sys ref: @chunk_ref\n" if ($verbose);
	#attach words to chunks
	
	#my $w = 0;
 
	foreach my $i(0..$#chunk_sys){
		if($chunk_sys[$i] !~ m/^O/){ 
			$chunk_sys[$i] =~ m/^\w+-(.*)$/;	#extract chunk
			my $phrase = $1;
			
			if($phrase =~ m/^NP/){
				if($pos_sys[$i] =~ m/^N.*/ && ($chunk_sys[$i] =~ m/^(E|S)-.*/)){
					push(@chunks_sys,$content_sys[$i].' '.$phrase);
					#$w++;
				}
				
					
			}else{		
				push(@chunks_sys,$content_sys[$i].' '.$phrase);
				#$w++;
				
			}
		}	
	}
	#$w = 0;
	foreach my $i(0..$#chunk_ref){
		if($chunk_ref[$i] !~ m/^O/){
			$chunk_ref[$i] =~ m/^\w+-(.*)$/;	#extract chunk
			my $phrase = $1;
						
			if($phrase =~ m/^NP/){
				if($pos_ref[$i] =~ m/^N.*/ && ($chunk_ref[$i] =~ m/^(E|S)-.*/)){
					push(@chunks_ref,$content_ref[$i].' '.$phrase);
					
				}
			}else{		
				push(@chunks_ref,$content_ref[$i].' '.$phrase);
				#$w++;
			} 
		}			
	}
	
	##compare same chunks in order
	my $sum = 0;
	#my $i = 0;	
	foreach my $i(0..$#chunks_sys){
		my $chunk_compare = 0;
		my ($cont_sys,$chunk_sys) = split(/\s+/,$chunks_sys[$i]);
		my ($cont_ref,$chunk_ref) = split(/\s+/,$chunks_ref[$i]);
			if($chunk_sys eq $chunk_ref){
				$chunk_compare += 0.5; 	#if the chunk is the same
				if($cont_sys eq $cont_ref){ #if the content is the same
					$chunk_compare += 0.5;				
				}
				print $LOG "SEGMENT: $segment\tCHUNKS sys: $chunk_sys ->$cont_sys ref: $chunk_ref->$cont_ref score:$chunk_compare \n" if ($verbose);
			}
			
		$sum += $chunk_compare;
		#$i++;
	}
	if(scalar(@chunks_sys) != 0){
		$sum = $sum/scalar(@chunks_sys);
	}else{
		$sum = 0;
	}
	
	return $sum;
	
}
sub token_cosine
{
	my ($segment,$sys,$ref) = @_;
	#first extract words
	my @content_sys;
	my @content_ref;
#TODO later put option to lemmas
	if($arg_content eq 'word'){
		@content_sys = split(/\s+/,$sys->{'word'});
		@content_ref = split(/\s+/,$ref->{'word'});
	}elsif($arg_content eq 'lemma')
	{
		@content_sys = split(/\s+/,$sys->{'lemma'});
		@content_ref = split(/\s+/,$ref->{'lemma'});      
	
	}
	
	#print "segment $segment @content_sys### @content_ref\n";	
	my $cos = new rteWORDMATCH();
	
	$cos->setUI(\@content_sys,\@content_ref);
	#print $cos->getCOSINE(),"\n";	
	return($cos->getCOSINE());
}

sub chunk_cos
{
	my ($segment,$sys,$ref) = @_;
	#first extract words
	my @content_sys;
	my @content_ref;
#TODO later put option to lemmas
	
	@content_sys = split(/\s+/,$sys->{'chunk'});
	@content_ref = split(/\s+/,$ref->{'chunk'});
	
	
	#print "segment $segment @content_sys### @content_ref\n";	
	my $cos = new rteWORDMATCH();
	
	$cos->setUI(\@content_sys,\@content_ref);
	#print $cos->getCOSINE(),"\n";	
	return($cos->getCOSINE());
}

sub just_content_words
{
	my($w,$p) = @_;
	my @temp;

	foreach my $i(0..$#{$w}){
		if($p->[$i] =~ m/^N.+/ or $p->[$i] =~ m/^V.+/ or $p->[$i] =~ m/^J.+/ or $p->[$i] =~ m/^RB.+/){
			push(@temp,$w->[$i]);
		}
	}
	return(@temp);
}


sub get_matched_Args
{
	my ($sys,$ref,$position_sys,$position_ref,$segment,$v_sys,$v_ref) =  @_;
	my $result = 0;	
	
	my (%args_sys, %args_ref)= ();
	
	
	#secondget_args_similarity extract srl (srl starts at 0)
	
	my @srl_sys = split(/\s+/,$sys->{"srl-$position_sys"});
	my @srl_ref = split(/\s+/,$ref->{"srl-$position_ref"});
	
	print $LOG "SEGMENT: $segment\t MATCHING_ARGS\n";
	print $LOG "SEGMENT: $segment\t sys: $v_sys($position_sys)->@srl_sys ref: $v_ref($position_ref)->@srl_ref\n" if ($verbose);
	#extract arguments	
	foreach my $i(0..$#srl_sys){
		if($srl_sys[$i] !~ m/^\w+-V$/ && $srl_sys[$i] !~ m/^O$/){ # if is not a verb or empty
			$srl_sys[$i] =~ m/^\w+-(.*)$/;	#extract argument
			my $argument = $1;		
			$args_sys{$argument} = 1;			
		}
	}

	foreach my $i(0..$#srl_ref){
		if($srl_ref[$i] !~ m/^\w+-V$/ && $srl_ref[$i] !~ m/^O$/){ # if is not a verb or empty
			$srl_ref[$i] =~ m/^\w+-(.*)$/;	#extract argument
			my $argument = $1;		
			$args_ref{$argument} = 1;			
		}
	}
	
	my $num_of_matched_args = 0;
	my $num_of_args = keys(%args_ref);

	foreach my $arg_ref(keys(%args_ref)){
		if(exists($args_sys{$arg_ref})){
			print $LOG "SEGMENT: $segment\tVERB: $v_sys sys: $arg_ref -> $args_sys{$arg_ref} ref: $arg_ref->$args_ref{$arg_ref}\n" if ($verbose);
			$num_of_matched_args++;		
		}
		
	}
	
	if($num_of_args != 0){
		$result = $num_of_matched_args/$num_of_args;
	}else{
		$result = 0;
	}
	print $LOG "SEGMENT: $segment\tNUM_OF_M_ARGS: $num_of_matched_args\tNUM_OF_T_ARGS: $num_of_args\tRESULT: $result\n";
	return $result;
}

sub get_args_similarity
{
	my ($sys,$ref,$position_sys,$position_ref,$segment,$v_sys,$v_ref,$num_of_args) =  @_;
	my $result = 0;	
	my (%args_sys, %args_ref)= ();
		
	#first extract words
	my @content_sys;
	my @content_ref;
	
	#TODO later put option to lemmas
	if($arg_content eq 'word'){
		@content_sys = split(/\s+/,$sys->{'word'});
		@content_ref = split(/\s+/,$ref->{'word'});
	}elsif($arg_content eq 'lemma')
	{
		@content_sys = split(/\s+/,$sys->{'lemma'});
		@content_ref = split(/\s+/,$ref->{'lemma'});
		
	}
	
	#second extract srl (srl starts at 0)
	
	my @srl_sys = split(/\s+/,$sys->{"srl-$position_sys"});
	my @srl_ref = split(/\s+/,$ref->{"srl-$position_ref"});
	print $LOG "SEGMENT: $segment\t ARGUMENT PREC\n";
	print $LOG "SEGMENT: $segment\t sys: $v_sys($position_sys)->@srl_sys ref: $v_ref($position_ref)->@srl_ref\n" if ($verbose);
	#attach words to arguments
	foreach my $i(0..$#srl_sys){
		if($srl_sys[$i] !~ m/^\w+-V$/ && $srl_sys[$i] !~ m/^O$/){ # if is not a verb or empty
			$srl_sys[$i] =~ m/^\w+-(.*)$/;	#extract argument
			my $argument = $1;		
			$args_sys{$argument} .= $content_sys[$i].' ';
			
		}
	}
	
	foreach my $i(0..$#srl_ref){
		if($srl_ref[$i] !~ m/^\w+-V$/ && $srl_ref[$i] !~ m/^O$/){ # if is not a verb or empty
			$srl_ref[$i] =~ m/^\w+-(.*)$/;	#extract argument
			my $argument = $1;				
			$args_ref{$argument} .= $content_ref[$i].' '; 
			
		}
	}

	
	my $partial_sum = 0;	
	foreach my $arg_ref(keys(%args_ref)){
		my $compare_args_result = 0;
		if(exists($args_sys{$arg_ref})){
			
			$compare_args_result = compareArgs($args_sys{$arg_ref},$args_ref{$arg_ref});
			print $LOG "SEGMENT: $segment\tVERB: $v_ref sys: $arg_ref -> $args_sys{$arg_ref} ref: $arg_ref->$args_ref{$arg_ref} arg_$type\_score:$compare_args_result \n" if ($verbose);
			${$num_of_args}++;		
		}		
		$partial_sum += $compare_args_result;
		
		
	}
	#my $num_of_args =  keys(%args_ref)*keys(%args_sys);
	
	
	print $LOG "SEGMENT: $segment\tVERB: $v_ref args_score partial_sum:$partial_sum \n" if ($verbose);
	return $partial_sum;
}

#######
#in: words of an argument a and words of argument b
#out: score, average of related words 
sub compareArgs
{
	my($w_sys,$w_ref) = @_;
	
	#if they are eq return 1
	if($w_sys eq $w_ref){
		return 1;
	}else{

		if($type eq 'thesaurus'){
			my @words_arg_sys = split(/\s+/,$w_sys);
			my @words_arg_ref = split(/\s+/,$w_ref);
	
			#compare first with thesaurus (average)
			my $sum = 0;

	
			my $sims = new simsDB();
			foreach my $i(0..$#words_arg_sys){
				foreach my $j(0..$#words_arg_ref){
					
					$sims->setWords($words_arg_sys[$i],$words_arg_ref[$j]);
			
					my $thesaurus_result = $sims->getIntersection(); #if the words are related in the thesaurus 1 otherwise 0
			
					$sum += $thesaurus_result;
												
				}
			}

			my $total = scalar(@words_arg_sys) * scalar(@words_arg_ref);
	
			if($total != 0){
				$sum = $sum/$total;
			}else{
				$sum = 0;
			}	
			
			return $sum;
		}elsif($type eq 'lp'){
			#compare second with co-occurrences
		
			####
			my @words_arg_sys = split(/\s+/,$w_sys);
			my @words_arg_ref = split(/\s+/,$w_ref);

			my $prod = 1;

	
			my $lp = new lpDB();
			my @max_lp = ();
			foreach my $i(0..$#words_arg_sys){
				foreach my $j(0..$#words_arg_ref){
					#$sims->setWords($words_arg_sys[$i],$words_arg_ref[$j]);
			
					my $lp_result = $lp->getLP($words_arg_sys[$i],$words_arg_ref[$j]);
					 
					push(@max_lp,$lp_result);
												
				}
				
				$prod *= max(@max_lp);
				
				@max_lp = ();
			}			
			return $prod;

		}elsif($type eq 'thesaurus-cos'){
			my @words_arg_sys = split(/\s+/,$w_sys);
			my @words_arg_ref = split(/\s+/,$w_ref);
			

			my $cos = new rteWORDMATCH();
			my $sims = new simsDB();

			my (@fin_sys,@fin_ref);
						
			foreach my $word(@words_arg_sys){ #enrich words with the thesaurus +20
				push(@fin_sys,$word);
				push(@fin_sys,$sims->getWords($word));
			}
			foreach my $word(@words_arg_ref){
				push(@fin_ref,$word);
				push(@fin_ref,$sims->getWords($word));
			}
			$cos->setUI(\@fin_sys,\@fin_ref);
			return $cos->getCOSINE();
		}		

	}		
	
}


