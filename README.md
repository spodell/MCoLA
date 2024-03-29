# MCoLA
Metagenomic Co-localization Analysis

The scripts in this repository can be used in a unix command line pipeline to identify specific protein annotations occurring within a user-selected distance of each other on the same assembled metagenomic (or genomic) contig. Note that all input files should have unix line endings (LF only), not DOS/WINDOWS (CR and LF) or classic MacIntosh (CR only).

Reference [1] below describes the application of this pipeline to identify co-localized pairs of carbohydrate digestive (CAZy) and arylsulfatase (SulfAtlas) classified enzymes in metagenomic data sets from the digestive systems of herbivorous fish and terrestrial ruminants.

PIPELINE PROCESSING STEPS
1. Create and annotate gene models for all contigs to be compared using PROKKA (https://github.com/tseemann/prokka) or equivalent annotation program, to get output file in gff format.
 
 example: 
 
    prokka --locustag samplename -prefix samplename --outdir prokka_samplename assembled_contigs.fna

2. Convert the gff output to a new tab delimited file containing one row per gene, with the following column    headers:

contig_id <br />
seq_type <br />
start <br />
end <br />
strand <br />
locus_tag (=protein_locus_id) <br />
product <br />
	
  example: 
  
     ./gff_to_tab.pl  prokka_out.gff >  prokka_out.tab

3. Move the locus_tag (protein sequence identifier) values from the fifth column (starting with zero) to the first column:
	
  example: 
  
     ./move_cols.pl  prokka_out.tab 5 > prokka_prot_id.tab
	
4. Create a tab-delimited file containing selected annotation terms to be used in the co-location searach (for example CAZy enzyme classes). Protein locus ids in the first column of this file must match the first column (protein locus ids) in the prokka_prot_id.tab file. This file should be in the following format: 

protein_locus_id&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;enzyme_class_name     

	
5. Append a new column with the co-localization annotaton search terms from the file you've just created to the tab-delimited annotation file.
  
 example: 
 
    ./outer_join_tabfiles.pl prokka_prot_id.tab test_annotation.tab | cut -f 1-7,9 > mcola_input.tab

6. Identify pairs of terms from the co-localization column that occur on the same contig and calculate distances between them. 

  example: 
  
     ./annot_pair_distances.pl -i mcola_input.tab -p mcola_output
	
  Parameter options for annot_pair_distances.pl: <br />
&nbsp;&nbsp;&nbsp; -i&nbsp;&nbsp;input tabfile name <br />
&nbsp;&nbsp;&nbsp; -p&nbsp;&nbsp;outfile name prefix (default = process_id) <br />
&nbsp;&nbsp;&nbsp; -s&nbsp;&nbsp;scaffold column number (0-9, default = 0) <br />
&nbsp;&nbsp;&nbsp; -a&nbsp;&nbsp;annotation column number (0-9, default = 6) <br />
&nbsp;&nbsp;&nbsp; -b&nbsp;&nbsp;begin col number (0-9, default = 3) <br />
&nbsp;&nbsp;&nbsp; -n&nbsp;&nbsp;gene name col num (0-9, default = 0); <br />
&nbsp;&nbsp;&nbsp; -m&nbsp;&nbsp;maxiumum gene separation (optional: off)  <br />
&nbsp;&nbsp;&nbsp; -r&nbsp;&nbsp;maxiumum nt residues separation (optional: off) <br />

7. Output will be in two files, one containing raw pairs and numbers, the other containing frequency tallies for each pair occurring within the maximum separation distance specified on the command line. The frequency tally file (.stats) can be used as input for creating network diagrams with programs such as Cytoscape (https://cytoscape.org)

mcola_output.raw <br />
mcola_output.stats <br />

REFERENCE CITATIONS
1. Podell, S., Oliver, A., Kelly, L.W., Sparagon, W.J., Plominsky, A.M., Nelson, R.S., Laurens, L.M., Augyte, S., Sims, N.A., Nelson, C.E. and Allen, E.E., 2023. Herbivorous fish microbiome adaptations to sulfated dietary polysaccharides. Applied and Environmental Microbiology, 89(5), pp.e02154-22.


