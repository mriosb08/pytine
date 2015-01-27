package readDB;
use strict;
use BerkeleyDB;


sub new {
	my $class=shift;
	my $readDB={@_};
	
	$readDB->{dbname}||="";
	$readDB->{key}||="";
	$readDB->{data}||="";
	$readDB->{type}||="tree";
	if($readDB->{dbname} =~ m/\.db$/)
	{
		$readDB->{dbname}=$readDB->{dbname}
	}else{
		$readDB->{dbname}=$readDB->{dbname}."\.db";
	}
	
	
	#my $env = new BerkeleyDB::Env(-Home=> "/home/DB");
	if($readDB->{type} eq "tree")	#if type tree create a Btree object
	{
		$readDB->{db}||=new BerkeleyDB::Btree(-Filename => "$readDB->{dbname}",-Flags =>DB_RDONLY)or die "Error db: $readDB->{dbname} not found\n";
	}else				#otherwise create a Hash
	{
		$readDB->{db}||=new BerkeleyDB::Hash(-Filename => "$readDB->{dbname}",-Flags =>DB_RDONLY)or die "Error db: $readDB->{dbname} not found\n";
	}
	bless $readDB,$class;
	return $readDB;
}
#params:
#	key:query word to search in a db
#	returns:string with the data otherwise empty string 
sub getData{
	my($readDB,$key)=@_;
	$readDB->{key}= $key if defined($key);
	my $tempdata="";
	
	
	if($readDB->{db}->db_get($readDB->{key},$tempdata) != 0)
	{	
		
		
		$readDB->{data}="";	
	}else
	{
		$readDB->{data}=$tempdata;
		
		
	}

return $readDB->{data};   
}
1;
