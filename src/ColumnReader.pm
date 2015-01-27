package ColumnReader;

use strict;

use Util;


# Creates a new column reader
# params:
#	$file => string
#	trim => boolean
#	\&report => report routine TODO make it object oriented, somethin like a Listener interface
# returns:
#	ColumnReader
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
	open ($FILE, "<:encoding($encoding)", $file) or die "File not found: $file\n";
	$self->{FILE} = $FILE;
}

sub singleColumn
{
	my ($self, $column) = @_;
	$self->{column} = $column;
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

	my %columns;
	while (my $line = <$FILE>){
		chomp($line);
		my $text = $line;
		$line = Util::trim($line);
		$text = $line if $self->{trim};
		if ($line){
			my @tokens = split(/\s+/,$text);
			foreach my $i (0 .. $#tokens){
				$columns{$i} .= $tokens[$i] . " ";
			}
		}
		if (!$line or eof($FILE)){
			# report
			if (exists $self->{column}){
				$self->report($columns{$self->{column}});
			} else{
				$self->report(%columns);
			}
			%columns = ();
		}
	}
}


# params:
#	reference columns: reference to the hash which will contain the columns
# returns:
#	columns hash
sub readNext
{
	my ($self, $read) = @_;
	$self->{FILE} or die "Before reading operations can be done a file must be assigned.\n";
	my $FILE = $self->{FILE};
	my $columns = {};
	while (my $line = <$FILE>){
		chomp($line);
		my $text = $line;
		$line = Util::trim($line);
		$text = $line if $self->{trim};
		if ($line){
			my @tokens = split(/\s+/,$text);
			foreach my $i (0 .. $#tokens){
				$columns->{$i} .= $tokens[$i] . " ";
			}
		}
		if (!$line or eof($FILE)){
			if (exists $self->{column}){
				$$read = $columns->{$self->{column}};
			} else{
				%{$read} = %{$columns};
			}
			return 1;
		}
	}
	return 0;
}


1;
