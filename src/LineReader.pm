package LineReader;

use strict;

use Util;

sub new
{
	my $class = shift;
	my $self = {@_};
	bless $self, $class;
	if ($self->{file}){
		$self->setFile($self->{file}, $self->{encoding});
	}
	return $self;
}

sub setFile
{
	my ($self, $file, $encoding) = @_;
	$encoding = "UTF-8" unless $encoding;
	$self->{encoding} = $encoding;
	$self->{file} = $file;
	my $FILE;
	open ($FILE,"<:encoding($encoding)", $file) or die "File not found: $file\n";
	$self->{FILE} = $FILE;
}

sub report
{
	my $self = shift;
	return $self->{report}->(@_);
}

# params:
#	$report: function pointer (optional)
#	$file: string (optional)
sub read
{
	my ($self, $report, $file, $encoding) = @_;
	if ($report){
		$self->{report} = $report;
	} else{
		die "A routine should be given in order to get results reported\n";
	}
	if ($file){
		$self->setFile($file, $encoding);
	}

	my $FILE;
	if ($self->{FILE}){
		$FILE = $self->{FILE};
	} else{
		die "Before reading operations can be done a file must be assigned.\n";
	}
	
	while (my $line = <$FILE>){
		chomp($line);
		$line = Util::trim($line);
		$self->report($line);
	}
}


# params:
#	string reference: line read
#	boolean keep: an optional flag to prevent the method from erasing the content of the input string (default: 0)
#		this flag is hardly needed to be set 1
# returns:
#	reading status
sub readNext
{
	my ($self, $tokens, $keep) = @_;
	$self->{FILE} or die "Before reading operations can be done a file must be assigned.\n";
	my $FILE = $self->{FILE};
	$$tokens = "" unless $keep;
	if (my $line = <$FILE>){
		chomp($line);
		$$tokens = Util::trim($line);
		return 1;
	}
	return 0;
}


1;
