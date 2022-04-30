#!/usr/local/bin/perl 
# outer_join_tabfiles.pl 
# Sheila Podell 
# October 22, 2003

#	takes two text file names as arguments (tab-delimited text -from excel)
# 	note: input files must have unix line endings
#	First file is master file (where additions may occur)
#	Second file is addfile (which may contain additions)
#	If first field of first file occurs in first field of second file, line
#	from second file will be appended to first
#	usage: $0 in_filename1 in_filename2

# 	gotcha: look out for extra spaces in first (join) field
#	since this program uses hash keys instead of regular expressions (for speed)
#	the join will fail unless match is exact.

use strict;
use warnings;

my $master_join_field = 0;
my $slave_join_field = 0;

# get file inputs
	unless (@ARGV == 2)
	{
		print "usage: $0 in_filename1 in_filename2";
		exit (0);
	}
	
	my $in_filename1 = $ARGV[0];
	my $in_filename2 = $ARGV[1];
	open (MASTER, "<$in_filename1") or die "can't open input file 1";
	open (ADDITIONS, "<$in_filename2") or die "can't open input file 2";
	
	my $out_filename = substr($in_filename1, 0, 10);
	$out_filename .= ".more";
	#open (OUT, ">$out_filename") or die "can't open outfile";

	chomp (my @master_lines = <MASTER>);
	chomp (my @add_lines = <ADDITIONS>);
	
	my %keys = ();
	foreach (@add_lines)
	{		
		next if $_ =~ /^\s+$/;
		my @tmp = split "\t", $_;
		$keys{$tmp[$master_join_field]} = $_;
	}
	
	my $counter = 0;
	
	foreach my $masterline (@master_lines)
	{					
		next if $masterline =~ /^\s+$/;
		chomp $masterline;
		my @tmp = split "\t", $masterline;
		
		if (exists $keys{$tmp[$slave_join_field]})
		{
			$masterline .= "\t$keys{$tmp[0]}";
			$counter++;
			print  "$masterline\n";	
		}
		else {print "$masterline\n"};
	}	

# summarize results to screen
	print STDERR "$counter lines appended in $out_filename\n";
	close MASTER;
	close ADDITIONS;
	#close OUT;	
	
__END__
	





