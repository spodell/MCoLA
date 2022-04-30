#!/usr/bin/perl 
# gff_to_tab.pl 
# Sheila Podell 
# July 30, 2016

# takes gff format file (multi-scaffold) as input

# outputs tab-delimited table to STDOUT
	# scaffold id
	# sequence type (CDS, rRNA, tRNA)
	# start
	# end
	# strand
	# locus_tag
	# product (annotation)
	
use strict;
use warnings;

# set filenames names, open files
	unless (@ARGV == 1)
	{
		print "usage: $0 gff input_file\n";
		exit (0);
	}
	
	open (INPUT, "<$ARGV[0]") or die "can't open input file 1";
	
# print header
	my @header = (
	"scf_id",
	"seq_type",
	"start",
	"end",
	"strand",
	"locus_tag",
	"product"
	);
	my $header_line = join "\t", @header;
	print "$header_line\n";

# parse lines
	while (<INPUT>)
	{
		my $current;
		last if ($_ =~ /^##FASTA/);
		next if ($_ =~ /^##/);
		chomp;
				

		my @tmp = split '\t', $_;
		my $scf_id = $tmp[0] || "not found";
		my $seq_type = $tmp[2] || "not found";
		my $start = $tmp[3] || "not found";
		my $end = $tmp[4] || "not found";
		my $strand = $tmp[6] || "not found";
		my $combined_txt = $tmp[8] || "not found";

		my @parsed = split ';', $combined_txt;
		my $locus_tag = "not found";
		my $product = "not found";
		
		foreach my $next (@parsed)
		{
			if ($next =~ /locus_tag=(.+)/)
			{
				$locus_tag =$1;
			}
			elsif ($next =~ /product=(.+)/)
			{
				$product = $1;
				last;
			}
		
		}
		my $printline = join "\t", ($scf_id,$seq_type,$start,$end,$strand,$locus_tag,$product);
		print "$printline\n";
					
	}
		

############################
# SUBROUTINES
############################
sub new_desc {
  my ($className, $param) = @_;
  my $self = {};
  bless $self, $className;
  my @properties = @$param;   
	$self->{name} = $properties[0];
	my @category_array = ();
	$self->{category_array} = \@category_array;
	$self->{hit_count} = 0;
 
  return($self)
}

__END__
		