#!/usr/local/bin/perl
# move_cols.pl
# Sheila Podell 
# June 20, 2005

# changes position of columns in tab-delimited file
# chooses one of columns to make 1st (key) column

# revised 4/1/05 to handle missing values in key column

use strict;
use warnings;

# usage
	unless (scalar @ARGV ==2 && $ARGV[1] =~ /\d/)
	{
		print "Usage: $0 tabfilename new_key_col_num (0-9)\n";
		exit (0);
	}

# get input (select feature_id, seq_id, begin from feature_instance limit 100000)
 	my $filename1 = $ARGV[0];
 	open (INPUT1, "$filename1") or die "can't open $filename1, \n$!\n";

	my $newkey_col = $ARGV[1];
	
	my $filename2 = "$filename1.revised";
	open (OUTPUT, ">$filename2") or die "couldn't open output file, $filename2\n$!\n";
		

while(<INPUT1>)
	{
		next if ($_ =~ /^\s+$/);
		chomp;
		my @row = split /\t/,$_;
		my $newkey_txt = $row[$newkey_col] || "";
		my @revised_row = ();
		foreach (@row)
		{
			unless (defined $newkey_txt && $_ eq $newkey_txt)
			{
				push @revised_row, $_;
			}
		}				
		unshift @revised_row, $newkey_txt;		
		my $line = join "\t", @revised_row;
		print OUTPUT "$line\n";		
	}
	
__END__