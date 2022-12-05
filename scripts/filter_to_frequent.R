#!/usr/bin/env Rscript

## ---------------------------
##
## Script: filter_to_frequent
##
## Purpose: filter feature table to frequent features based on defined threshold
##
## Author: Ikaia Leleiwi
##
## Date Created: December 4th, 2022
##
## Copyright (c) Ikaia Leleiwi, 2022
## Email: ileleiwi@gmail.com
##
## ---------------------------
##
## Notes:
##   
##
## ---------------------------


main <- function(){
  
  args <- commandArgs(trailingOnly = TRUE)
  if(args[1] == "--help" | args[1] == "-h"){
    help_msg <- c("\n",
                  "Function filters feature table to frequent taxa",
                  "\tPositional arguments are:",
                  "\t[1] path to file (tsv)",
                  "\t[2] threshold (0-1)",
                  "Output to file in ../data dir",
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
  })

  #define args
  filename <- args[1]
  threshold <- args[2]
  
  #read in data
  df_out <- read_tsv(filename)

  #set threshold number
  numeric_col_num <- ncol(df_out) -1
  num <- round(as.numeric(threshold) * numeric_col_num)
  
  df_out <- df_out %>%
    imap_dfc(~if(is.numeric(.x)){ifelse(.x > 0, 1, 0)} else(.x)) %>%
    mutate(total = rowSums(across(where(is.numeric)))) %>%
    arrange(desc(total)) %>%
    filter(total >= num) %>%
    select(-total)
  
  write_tsv(df_out, str_glue("../data/ft_pa_thrshld{threshold}.tsv"))
}

main()

