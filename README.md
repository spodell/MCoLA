# MCoLA
Metagenomic Co-Localization Analysis

The scripts in this repository can be used in a unix command line pipeline to identify specific protein annotations occurring within a user-selected distance of each other on the same assembled metagenomic (or genomic) contig. 

Reference [1] below describes the application of this pipeline to identify co-localized pairs of carbohydrate digestive enzyme (CAZy) and arylsulfatase (SulfAtlas) classified enzymes in metagenomic data sets from the digestive systems of herbivorous fish and terrestrial ruminants.

PIPELINE PROCESSING STEPS
1. Create and annotate gene models for all contigs to be compared using PROKKA [2] or equivalent annotation program, to get output file in gff format.
 
 example: prokka --locustag samplename -prefix samplename --outdir prokka_samplename assembled_contigs.fna;

2. Convert the gff output to a new tab delimited file containing one row per gene, with the following column headers: 
contig_id	seq_type	start	end	strand	locus_tag	product
	
  example: ./gff_to_tab.pl  prokka_out.gff >  prokka_out.tab

3. Move the locus_tag (protein sequence identifier) values from the fifth column (starting with zero) to the first column:
	
  example: ./move_cols.pl  prokka_out.tab 5 > prokka_prot_id.tab

	
4. Create a tab-delimited file containing selected annotation terns to be compared (for example CAZy enzyme classes) Protein locus ids in the first column of this file must match the first column (protein locus ids) in the prokka_prot_id.tab file. This file should be in the following format: 

protein_locus_id	comparison_term
	
4. Append a new column with the co-localization annotaton search terms from the file you've just created to the tab-delimited annotation file

 example:  ./outer_join.pl prokka_prot_id.tab test_annotation | cut -f 1-5,7 > mcola_input.tab

5. Identify pairs of terms from the co-localization column that occur on the same contig and calculate distances between them. Output will be in two files, one containing raw pairs and numbers, the other containing tallies for each pair occurring within the selected distance.

	 example: ./annot_pair_distances.pl -i mcola_input.tab -p mcola_output
	
	Parameter options:
	  -i	input tabfile name
	  -p	outfile name prefix (default = process_id)
	  -s	scaffold column number (0-9, default = 0)
	  -a	annotation column number (0-9, default = 6)
	  -b 	begin col number (0-9, default = 3)
	  -n	gene name col num (0-9, default = 0);
	  -m	maxiumum gene separation (optional: off) 
	  -r	maxiumum nt residues separation (optional: off)

REFERENCE CITATIONS
1. Podell S, Oliver A, Kelly LW, Sparagon W, Nelson CE, Allen EA. Kyphosid fish microbiome adaptations to sulfated dietary polysaccharides. Manuscript submitted (2022).

2. Seemann T. Prokka: rapid prokaryotic genome annotation. Bioinformatics. 2014;30(14):2068-9; doi: 10.1093/bioinformatics/btu153.
