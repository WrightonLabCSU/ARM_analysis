#!/usr/bin/env Rscript

main <- function(){
	
	args <- commandArgs(trailingOnly = TRUE)

        if(args[1] == "--help" | args[1] == "-h"){
                help_msg <- c("\n",
		  "Function creats all possible combinations of id's in id column",
		  "\tPositional arguments are:",
                  "\t[1] path to file (tsv)",
                  "\t[2] id column name",
                  "\t[3] number of cores",
                  "\t[4] minimum number of items in set",
                  "\t[5] maximum number of items in set",
		  "\n"
		)
              
		cat(help_msg, sep = "\n")

		stop_quietly <- function() {
  			opt <- options(show.error.messages = FALSE)
  			on.exit(options(opt))
  			stop()
		}

		stop_quietly() 
        }

	library(tidyverse)
	library(furrr)
	library(gtools)	

	filename <- args[1]
	id_col <- args[2]
	cores <- args[3]
	minl <- args[4]
	maxl <- args[5]


	id <- read_tsv(filename) %>%
		as.data.frame() %>%
		pull(id_col)
	
	plan(multisession, workers = cores)

	sets <- future_map(.x = seq(minl,maxl), ~combinations(length(id), .x, id))
	
	
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
