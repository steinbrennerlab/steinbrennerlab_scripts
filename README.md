# steinbrennerlab_scripts
 Useful scripts

## cdhit_parser.sh
Takes CD-HIT output and outputs 2 text files: 
1) each gene on a separate line followed by each gene's cluster
2) a summary of how many genes from each "species" are in each cluster. The current script uses a simple shorthand to infer species -- it reads the first two letters of each gene name as species identifiers