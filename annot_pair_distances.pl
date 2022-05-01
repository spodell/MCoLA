#!/usr/bin/perl
# annot_pair_distances.pl
# Sheila Podell
# February 11, 2022

# input 
	# prokka annotation type tabfile
		# optional prefix for output filenames
	# enable over-ride for default id_num, contig, start, stop, strand, annotation cols 
	# optional separation distance (default is infinity)
	# choice of gene number versus nt coordinates?
		# by gene number
		# by coordinates
	# target annot keywords? (so don't have to pre-filter the prokka file)
		# wild card filtering?		
# output (to STDOUT)
	# 1) raw tab-delimited file of all pairs 
		# annot1, annot2 gene_separation	nt_separation
	# 2) tab-delimited stats on pairs (suitable for cytoscape input
		# annot1
		# annot2
		# total num pairs
		# separation mean, min, max, stdev 
	
use warnings; 
use strict;
use Getopt::Long;

# set global variables
	my $tabfile = "";
	my $outfile_prefix = "$$";
	my $scf_col = 1;
	my $annot_col = 7;
	my $begin_col = 3;
	my $gene_name_col = 0;
	my $max_gene_separation;
	my $max_nt_separation;
	my @all_pairs_array = (); #for raw output file
	
# Default values
	my($USAGE);
	
	my $message = qq(\tUsage: $0 <options> 
	Parameters:
	  -i	input tabfile name
	  -p	outfile name prefix (default = process_id)
	  -s	scaffold column number (0-9, default = 0)
	  -a	annotation column number (0-9, default = 6)
	  -b 	begin col number (0-9, default = 3)
	  -n	gene name col num (0-9, default = 0);
	  -m	maxiumum gene separation (optional: off) 
	  -r	maxiumum nt residues separation (optional: off)

)."\n";

# get input parameters from command line
	GetOptions(
				"i=s" => \$tabfile,
				"p=s" => \$outfile_prefix,
				"s=i" => \$scf_col,
				"a=i" => \$annot_col,
				"b=i" => \$begin_col,
				"n=i" => \$gene_name_col,
				"m=i" => \$max_gene_separation,
				"r=i" => \$max_nt_separation,
 );

	&validate_input;
	my $strand_col = $begin_col + 2;
	
# open files to accept results
	my $raw_filename = "$outfile_prefix".".raw";
	my $stats_filename = "$outfile_prefix".".stats";
	open (RAWFILE, ">$raw_filename") or die "couldn't open raw filename $raw_filename for writing, $!\n";
	open (STATSFILE, ">$stats_filename") or die "couldn't open stats filename $stats_filename for writing, $!\n";		
			
# make sure input tabfile is sorted by scf_id, then begin coordinate
	my $sortkey = $scf_col + 1;  # unix cmd line sort starts with 1
	my $newname = "$tabfile"."_sorted";
	my $sorted_tabfile = `sort -k $scf_col,$begin_col $tabfile > $newname`;
	 $newname = $tabfile;

# go through input tabfile (once)
	open (INFILE, "<$newname") or die "couldn't open file $newname, $!\n";	
	my ($current_scf_id, $prev_scf_id, $annot, $output_txt);

# temporary data structures for making scaffold (or congig) tallies
	my @annot_array = ();
	my @lines_array = ();
	my $total_num_pairs_found = 0;
	my @pairs_array = (); # each entry is a temporary tab-separated pair, overwriten for each contig
	
# saved data structure for getting overall statistics
	my %pair_objects =();  # key = $annot1_$annot2  value = object reference
	
	while (<INFILE>)
	{
		chomp ($_);
		next if ($_ =~ /^\s*$/);
		my @tmp =split "\t", $_;
		next unless (defined $tmp[$annot_col] && length $tmp[$annot_col] > 1);
		$current_scf_id = $tmp[$scf_col];
		
		$annot = $tmp[$annot_col];
		if ($. == 1)
		{
			$prev_scf_id = $current_scf_id;
		}
		
		if (defined $prev_scf_id && $current_scf_id eq $prev_scf_id)
		{
			push @annot_array, $annot;
			push @lines_array, $_; 
		}	
		else # save old array, then reset temporary arrays and $prev_scf_id
		{			
			if (scalar @annot_array >1)
			{
				my @stats_array = &collate_pairs(\@lines_array);
				$output_txt = join "\n", @stats_array;
				push @all_pairs_array, @stats_array;			
				# debug
					#$output_txt = join "\n", @stats_array;
					#print "$output_txt\n";
			}
			@annot_array = ();
			@lines_array = ();
			$prev_scf_id = $current_scf_id;
		}		
		if (eof)
		{
			if (scalar @annot_array >1)
			{
				my @stats_array = &collate_pairs(\@lines_array);								
				push @all_pairs_array, @stats_array;
				#$output_txt = join "\n", @stats_array;	
			}		
		}
	}

	my @sorted_all_pairs_array = sort @all_pairs_array;
	my $total_scaffolds = scalar @all_pairs_array;
	
	my @raw_output_cols = ("term1", "term2", "gene_distance", "nucleotide_distance");
	my $raw_output_header = join "\t", @raw_output_cols;
    print RAWFILE "$raw_output_header\n";

# create an object for each unique set of pair names
# put into object hash defined earlier
	#my %pair_objects =();  # key = $annot1_$annot2  value = object reference 
		
	my $current_pair_object = "";
			
	foreach my $next (@sorted_all_pairs_array)
	{
		chomp ($next);
	# print raw output
		print RAWFILE "$next\n";
		
	# put pair info into pair object
		my @tmp = split "\t", $next;
		my $pairname = join "_", ("$tmp[0]", "$tmp[1]");
		
		unless (exists $pair_objects{$pairname})
		{
			$current_pair_object = &new_pair("pair", \@tmp);
			$pair_objects{$pairname} = $current_pair_object; 
		}
		
		my $gene_dist = $tmp[2];
		my $nucleotide_dist = $tmp[3];
	
	# update attributes for the pairname object
		$current_pair_object->{pair_tally}++;
		push @{$current_pair_object->{gene_distance_values}}, $gene_dist;
		push @{$current_pair_object->{$nucleotide_dist}}, $nucleotide_dist;
	}
	
# printout stats for each pair
 	my @statscols = ("term1", "term2", "num_instances", "min", "max", "mean", "stdev" );
 	my $stats_header = join "\t", @statscols;
 	print STATSFILE "$stats_header\n";
 	
	foreach my $pairname (sort keys %pair_objects)
	{
		my $objects_tally = $pair_objects{$pairname}->{pair_tally};
		my $term1 = $pair_objects{$pairname}->{term1};
		my $term2 = $pair_objects{$pairname}->{term2};
		my @gene_distance_values = @{$pair_objects{$pairname}->{gene_distance_values}};
		my $tally = scalar @gene_distance_values;
		
		my @gene_distance_stats = &getstats(\@gene_distance_values);
		
		my @nucleotide_distance_values = @{$pair_objects{$pairname}->{nucleotide_distance_values}};
			
	# print out summary statistics 
		my $printline = join "\t", ($term1,$term2, $tally,@gene_distance_stats);
			print STATSFILE "$printline\n";
	}
	 
close INFILE;
close RAWFILE;
close STATSFILE;

unlink "$tabfile"."_sorted";

# user output
		my $num_uniq_pairnames = scalar (keys %pair_objects);
		if (defined $max_gene_separation)
		{
			print STDERR "\npairs separated by > $max_gene_separation genes have been excluded";
		}
		print STDERR "\nfound $num_uniq_pairnames unique combinations for $total_num_pairs_found total annotation pairs.\n\n";
		
	#print STDERR "found $num_uniq_pairnames unique pairnames\n";
	
##################
# SUBROUTINES
#################

sub validate_input
{
	if($USAGE) 
	{
		print STDERR $message;
		exit(0);
	} 
	unless (defined $tabfile && -s "$tabfile")
	{		
		print STDERR "\tERROR: Couldn't open input file $tabfile\n";
		print STDERR "$message\n";
		exit(0);
	}
	unless (defined $gene_name_col && ($gene_name_col =~ /\d/))
	{
		print STDERR "\tERROR: Couldn't find gene name column number $gene_name_col\n";	
	}
	unless (defined $annot_col && ($annot_col =~ /\d/))
	{
		print STDERR "\tERROR: Couldn't find annotation column number $annot_col\n";	
	}
	unless (defined $begin_col && ($begin_col =~ /\d/))
	{
		print STDERR "\tERROR: Couldn't find begin column number $begin_col\n";	
	}
	if (defined $max_gene_separation) 
	{
		unless ($max_gene_separation =~ /\d+/)
		{
			print STDERR "\tERROR: Illegal definition for maximum gene separation $max_gene_separation\n";
		}	
	}
	if (defined $max_nt_separation) 
	{
		unless ($max_nt_separation =~ /\d+/)
		{
			print STDERR "\tERROR: Illegal definition for maximum nucleotide separation $max_nt_separation\n";
		}	
	}			
}

sub new_pair
{
  my ($className, $param) = @_;
  my $self = {};
  bless $self, $className;
  my @properties = @$param;  
  $self->{term1}= $properties[0];
  $self->{term2} = $properties[1];
  $self->{pairname} = join "_", ($properties[0], $properties[1]);

$self->{pair_tally} =0;

my @gene_distance_values = ();
$self->{gene_distance_values} = \@gene_distance_values;

my @nucleotide_distance_values = ();
$self->{nucleotide_distance_values} = \@nucleotide_distance_values;
	   
  return($self)

}

sub collate_pairs
{
	# input is an array of lines associated with a single scaffold (or contig)
	# output is all possible combinations of annotation pair keywords in the array, e.g
		# 1+2, 1+3, 1+4, 2+3, 2+4, 3+4
	
	my ($arrayref) = @_;
	my @array = @$arrayref;
	my $test_txt = join "\t", @array;
	
	my $array_len = scalar @array;
	my @pairs_array = ();
	my @next_pair = ();
	my $current_pair;
	my ($term1, $term2, $distance);
	my ($line1, $line2);
	my ($term1_annot, $term2_annot);
	my ($term1_id, $term2_id);
	my ($term1_begin, $term2_begin);
	my ($gene_separation, $nt_separation);	
	
	for (my $i = 0; $i < $array_len; $i++)
	{
		$line1 = $array[$i];
		my @line1_tmp = split "\t", $line1;
		$term1_begin =  0 + $line1_tmp[$begin_col];
		$term1_id =  $line1_tmp[$gene_name_col];
		$term1_annot =  $line1_tmp[$annot_col];
		
		for (my $j=$i+1; $j < $array_len; $j++)
		{
			$line2 = $array[$j];
			my @line2_tmp = split "\t", $line2;
			$term2_begin = 0 + $line2_tmp[$begin_col];
			$term2_id =  $line2_tmp[$gene_name_col];
			$term2_annot =  $line2_tmp[$annot_col];
			
		# get gene number separation (remove leading zeros by numerical addition of zero )
			my @name_tmp1 = split "_", $term1_id;
			my @name_tmp2 = split "_", $term2_id;
			my $gene_num1 = 0 + $name_tmp1[1];
			my $gene_num2 = 0 + $name_tmp2[1];					
			my $gene_separation = abs($gene_num2-$gene_num1);
			my $nt_separation = abs($term1_begin - $term2_begin);		
				
		# filter for max nucleotide separation
			next if (defined $max_nt_separation && ($nt_separation > $max_nt_separation));
			next if (defined $max_gene_separation && $gene_separation > $max_gene_separation);

			 		
		# sort set of pair names alphabetically before saving to make output order consistent		
			@next_pair = sort ($term1_annot, $term2_annot);
			$current_pair = join "\t", (@next_pair,$gene_separation, $nt_separation);			
			push @pairs_array, $current_pair;
			$total_num_pairs_found++;
		}
	} 
	
	return (@pairs_array);
}

sub getstats
{
	my ($data) = @_;
	my @array = @$data;
	my ($mean, $sumdiff, $stdev);
	my $min = $array[0];
	my $max = $array[0];
	my $sum = 0;
	my $n = (scalar @array);	
	my $count = 0;				
	
	foreach (@array)
	{
		chomp $_;
		next if ($_ =~ /^\s*$/);	#skip blank values
		chomp $min;
		chomp $max;
		unless ($_ =~ /^[-\de.\.]+$/)
		{
			$min = "-";
			$mean = "-";
			$stdev = "-";
			$max = "-";
			return "$min\t$max\t$mean\t$stdev";
		}
		
		$count++;
		$sum += $_;
		if ($_ < $min)
		{
			$min = $_;
		}
		if ($_ > $max)
		{
			$max = $_;
		}		
	}	
	
# avoid div/0 errors
	$n = $count;
	unless ($count >0)
	 {
		$min = "-";
		$mean = "div_zero";
		$stdev = "-";
		$max = "-";
		return "$min\t$max\t$mean\t$stdev";
	}
	
	$mean = $sum/$n;	

	$sumdiff=0;
	foreach (@array)
	{
		next if ($_ =~ /^\s*$/);	#skip blank values
		$sumdiff += (($_ - $mean)*($_ - $mean));	
	}
	
	$stdev = 0;
	if ($n > 1)
	{
		$stdev = sqrt(($sumdiff)/($n-1));
	}

# format results
	my $formatted_mean = sprintf ("%.2f", $mean);
	my $formatted_stdev = sprintf ("%.2f", $stdev);

	return "$min\t$max\t$formatted_mean\t$formatted_stdev";	
}
__END__	
