#!/usr/bin/env Rscript

#support function
#calculates the frequency of each individual taxa in the feature table and filters by the support threshold
calc_support <- function(featuretable, id_col, support_threshold){
  ft <- as.data.frame(featuretable) %>%
    select(-all_of(id_col))
  
  support <- apply(ft, 1, function(x) sum(x)/ncol(ft))
  
  out_ft <- cbind(support, featuretable) %>%
    filter(support >= (support_threshold))
  
  return(out_ft)
}

main <- function(){
	
	args <- commandArgs(trailingOnly = TRUE)
  if(args[1] == "--help" | args[1] == "-h"){
    help_msg <- c("\n",
                  "Function creates all possible combinations of id's in id column",
                  "\tPositional arguments are:",
                  "\t[1] path to file (tsv)",
                  "\t[2] id column name",
                  "\t[3] number of cores",
                  "\t[4] minimum number of items in set",
                  "\t[5] maximum number of items in set",
                  "\t[6] support threshold (0-1)",
                  "Output to stdout",
                  "\n")
              
		cat(help_msg, sep = "\n")

		stop_quietly <- function() {
  			opt <- options(show.error.messages = FALSE)
  			on.exit(options(opt))
  			stop()
		}
		stop_quietly() 
  }

	#prep environment
	suppressPackageStartupMessages({
	  library(tidyverse, quietly = TRUE, warn.conflicts = FALSE)
	  library(furrr, quietly = TRUE, warn.conflicts = FALSE)
	  library(gtools, quietly = TRUE, warn.conflicts = FALSE)	
	})
	
	#define args
	filename <- args[1]
	id_col <- args[2]
	cores <- args[3]
	minl <- args[4]
	maxl <- args[5]
	sup_thr <- args[6]

  #convert to presence absence
	df <- read_tsv(filename,show_col_types = FALSE) %>%
	  imap_dfc(~if(is.numeric(.x)){ifelse(.x > 0, 1, 0)} else(.x))
	
	#calculate single support and filter to threshold
	df_filtered <- calc_support(df, id_col = id_col, support_threshold = sup_thr)
	
	#pull id column
	id <- df_filtered %>% pull(id_col)
	
	#set up multicore processing
	plan(multisession, workers = cores)

	sets <- future_map(.x = seq(minl,maxl), 
	                   ~permutations(length(id), .x, id),
	                   repeats.allowed = FALSE)
	
	#combining each element of the set into one string
	sets_vect <- c()
  	for(i in seq_along(sets)){
    		add <- sets[[i]] %>%
      		as.data.frame() %>%
      		unite("col", 1:ncol(sets[[i]]), remove = TRUE, sep = ";") %>%
      		pull(col)
    
    		sets_vect <- c(sets_vect, add)
  	}

	cat(sets_vect, sep = "\n")			

}

main()
