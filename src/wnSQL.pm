package wnSQL;
use DBI;
use strict;
use warnings;

####
my $conection_database;
####
sub new {
	my $class=shift;
	my $wnSQL={@_};

	$wnSQL->{database}||="wordnet30";
	$wnSQL->{host}||="localhost";
	$wnSQL->{user}||="root";
	$wnSQL->{psw}||="root";
	$wnSQL->{w}||=undef;
	$wnSQL->{p}||=undef;
	$wnSQL->{s}||=undef;
	$wnSQL->{sep}||="\t";
	$conection_database = DBI->connect("DBI:mysql:database=$wnSQL->{database};host=$wnSQL->{host}",
						"$wnSQL->{user}",
						"$wnSQL->{psw}",
						{'RaiseError' => 1});

    bless $wnSQL,$class;
    return $wnSQL;
}
###SET###
sub setWord{
	my $wnSQL=shift;
	my ($w,$p,$s) = @_;
	$wnSQL->{w} = $w;
	$wnSQL->{p} = $p;
	$wnSQL->{s} = $s;
	$wnSQL->{w} =~ s/'/\\'/g;
	$wnSQL->{p} =~ s/'/\\'/g;
	$wnSQL->{s} =~ s/'/\\'/g;
}
###GET###
sub getGloss{
	my $wnSQL=shift;
	my %senseHash = ();
	
	if($wnSQL->{s}){
		my $query = "SELECT sensenum,definition,sampleset FROM dict WHERE lemma = '$wnSQL->{w}' AND pos = '$wnSQL->{p}' AND sensenum=$wnSQL->{s}";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			my $temp = "";			
			if($feched_row->{sampleset}){
				$temp = $feched_row->{sampleset};	
			}
			$senseHash{$feched_row->{sensenum}} .= $feched_row->{definition}." <example>".$temp."</example> "."$wnSQL->{sep}";
					
		}
					
	}else{
		my $query = "SELECT sensenum,definition,sampleset FROM dict WHERE lemma = '$wnSQL->{w}' AND pos = '$wnSQL->{p}'";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		

		while (my $feched_row = $command_database->fetchrow_hashref()) {
			my $temp = "";			
			if($feched_row->{sampleset}){
				$temp = $feched_row->{sampleset};	
			}
			$senseHash{$feched_row->{sensenum}} .= $feched_row->{definition}." <example>$temp</example> "."$wnSQL->{sep}";		
		}		
	}
	return (%senseHash);
}

sub getHypernym{
	my $wnSQL=shift;
	my %senseHash = ();
	
	if($wnSQL->{s}){
		my $query = "SELECT ssensenum,sw.lemma,dw.lemma AS hypernym,SUBSTRING(sdefinition FROM 1 FOR 60) FROM sensesXsemlinksXsenses AS l LEFT JOIN words AS sw ON l.swordid = sw.wordid LEFT JOIN words AS dw ON l.dwordid = dw.wordid WHERE sw.lemma = '$wnSQL->{w}' AND linkid=1 AND spos='$wnSQL->{p}' AND ssensenum=$wnSQL->{s}";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{ssensenum}} .= $feched_row->{hypernym}."$wnSQL->{sep}";
					
		}
					
	}else{
		my $query = "SELECT ssensenum,sw.lemma,dw.lemma AS hypernym,SUBSTRING(sdefinition FROM 1 FOR 60) FROM sensesXsemlinksXsenses AS l LEFT JOIN words AS sw ON l.swordid = sw.wordid LEFT JOIN words AS dw ON l.dwordid = dw.wordid WHERE sw.lemma = '$wnSQL->{w}' AND linkid=1 AND spos='$wnSQL->{p}'";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		

		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{ssensenum}} .= $feched_row->{hypernym}."$wnSQL->{sep}";		
		}		
	}
	return (%senseHash);
}

sub getHyponym{
	my $wnSQL=shift;
	my %senseHash = ();
	
	if($wnSQL->{s}){
		my $query = "SELECT ssensenum,sw.lemma,dw.lemma AS hyponym,SUBSTRING(sdefinition FROM 1 FOR 60) FROM sensesXsemlinksXsenses AS l LEFT JOIN words AS sw ON l.swordid = sw.wordid LEFT JOIN words AS dw ON l.dwordid = dw.wordid WHERE sw.lemma = '$wnSQL->{w}' AND linkid=2 AND spos='$wnSQL->{p}' AND ssensenum=$wnSQL->{s}";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{ssensenum}} .= $feched_row->{hyponym}."$wnSQL->{sep}";
				
		}
					
	}else{
		my $query = "SELECT ssensenum,sw.lemma,dw.lemma AS hyponym,SUBSTRING(sdefinition FROM 1 FOR 60) FROM sensesXsemlinksXsenses AS l LEFT JOIN words AS sw ON l.swordid = sw.wordid LEFT JOIN words AS dw ON l.dwordid = dw.wordid WHERE sw.lemma = '$wnSQL->{w}' AND linkid=2 AND spos='$wnSQL->{p}'";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		

		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{ssensenum}} .= $feched_row->{hyponym}."$wnSQL->{sep}";		
		}		
	}
	return (%senseHash);
}

sub getSynonym{
	my $wnSQL=shift;
	my %senseHash = ();
	$wnSQL->{w} = shift;
	$wnSQL->{w} =~ s/'/\\'/g;
		my $query = "SELECT synsetid,dest.lemma FROM wordsXsensesXsynsets AS src INNER JOIN wordsXsensesXsynsets AS dest USING(synsetid) WHERE src.lemma = '$wnSQL->{w}' AND dest.lemma <> '$wnSQL->{w}'";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{synsetid}} .= $feched_row->{lemma}."$wnSQL->{sep}";
				
		}
					
	
	return (%senseHash);
}

sub getAntonym{
	my $wnSQL=shift;
	my %senseHash = ();
	
	if($wnSQL->{s}){
		my $query = "SELECT ssensenum,sw.lemma,dw.lemma AS antonym,SUBSTRING(sdefinition FROM 1 FOR 60) FROM sensesXlexlinksXsenses AS l LEFT JOIN words AS sw ON l.swordid = sw.wordid LEFT JOIN words AS dw ON l.dwordid = dw.wordid WHERE sw.lemma = '$wnSQL->{w}' AND linkid=30 AND spos='$wnSQL->{p}' AND ssensenum=$wnSQL->{s}";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{ssensenum}} .= $feched_row->{antonym}."$wnSQL->{sep}";
				
		}
					
	}else{
		my $query = "SELECT ssensenum,sw.lemma,dw.lemma AS antonym,SUBSTRING(sdefinition FROM 1 FOR 60) FROM sensesXlexlinksXsenses AS l LEFT JOIN words AS sw ON l.swordid = sw.wordid LEFT JOIN words AS dw ON l.dwordid = dw.wordid WHERE sw.lemma = '$wnSQL->{w}' AND linkid=30 AND spos='$wnSQL->{p}'";
		
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		

		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{ssensenum}} .= $feched_row->{hypernym}."$wnSQL->{sep}";		
		}		
	}
	return (%senseHash);
}


sub getLft{
	my $wnSQL=shift;
	my %senseHash = ();
	
	if($wnSQL->{s}){
		my $query = "SELECT sensenum,lft FROM words LEFT JOIN senses USING (wordid) INNER JOIN synsets USING (synsetid) INNER JOIN xwnparselfts USING (synsetid) WHERE pos='$wnSQL->{p}' AND lemma='$wnSQL->{w}' AND sensenum=$wnSQL->{s}";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{sensenum}} .= $feched_row->{lft}."$wnSQL->{sep}";
			
		}
					
	}else{
		my $query = "SELECT sensenum,lft FROM words LEFT JOIN senses USING (wordid) INNER JOIN synsets USING (synsetid) INNER JOIN xwnparselfts USING (synsetid) WHERE pos='$wnSQL->{p}' AND lemma='$wnSQL->{w}'";
		
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		

		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{sensenum}} .= $feched_row->{lft}."$wnSQL->{sep}";		
		}		
	}
	return (%senseHash);
}

sub getGlossWSD{
	my $wnSQL=shift;
	my %senseHash = ();
	
	if($wnSQL->{s}){
		my $query = "SELECT sensenum,wsd FROM words LEFT JOIN senses USING (wordid) INNER JOIN synsets USING (synsetid) INNER JOIN xwnwsds USING (synsetid) WHERE pos='$wnSQL->{p}' AND lemma='$wnSQL->{w}' AND sensenum=$wnSQL->{s}";
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{sensenum}} .= $feched_row->{wsd}."$wnSQL->{sep}";
					
		}
					
	}else{
		my $query = "SELECT sensenum,wsd FROM words LEFT JOIN senses USING (wordid) INNER JOIN synsets USING (synsetid) INNER JOIN xwnwsds USING (synsetid) WHERE pos='$wnSQL->{p}' AND lemma='$wnSQL->{w}'";
		
		my $command_database = $conection_database->prepare($query);

		$command_database->execute();
		
		

		while (my $feched_row = $command_database->fetchrow_hashref()) {
			
			$senseHash{$feched_row->{sensenum}} .= $feched_row->{wsd}."$wnSQL->{sep}";		
		}		
	}
	return (%senseHash);
}




1;
