#!/usr/bin/env Rscript

#support function
calc_support <- function(string, ft_pa, id_col){
  rule <- unlist(str_split(string, ";"))
  freq_table <- ft_pa %>%
    filter(.data[[id_col]] %in% rule) %>%
    select(-all_of(id_col)) %>%
    colSums() %>%
    as.numeric() %>%
    table()
  
  numerator <- freq_table[as.character(length(rule))]
  
  return(numerator/(ncol(ft_pa) - 1))
}

#add support column to rule dataframe
add_support_filter <- function(ft, rule_df, sets, id_col, cores, threshold){
  
  plan(multisession, workers = cores)
  support <- future_map(sets, ~calc_support(.x, ft, id_col)) 
  
  support_rule_df <- cbind(support, rule_df) %>%
    filter(support >= threshold)
  
  return(support_rule_df)
}

#confidence function
calc_confidence <- function(rule_support, ante_vect, ft_pa, id_col){
  freq_rule <- rule_support*(ncol(ft_pa)-1)
  
  freq_ante_vect <- ft_pa %>%
    filter(.data[[id_col]] %in% unlist(str_split(ante_vect, ";"))) %>%
    select(-all_of(id_col)) %>%
    colSums() %>%
    as.numeric() %>%
    table()
  
  denominator <- freq_ante_vect[as.character(length(unlist(str_split(ante_vect, ";"))))]
  
  return(freq_rule/denominator)
}

#add confidence column to rule dataframe
add_confidence <- function(ft, support_rule_df, id_col, cores){
  
  plan(multisession, workers = cores)
  confidence <- future_map2(support_rule_df[,"support"], 
                            support_rule_df[,"antecedents"], 
                            ~calc_confidence(.x, .y, ft, id_col)) 
  
  return(cbind(confidence, support_rule_df))
}

#expected confidence function
calc_exp_confidence <- function(ft_pa, id_col, consequent_string){
  
  freq_consequent_string <- ft_pa %>%
    filter(.data[[id_col]] == consequent_string) %>%
    select(-all_of(id_col)) %>%
    as.numeric() %>%
    sum()
  
  return(freq_consequent_string/(ncol(ft_pa) -1))
}

#add expected confidence column to rule dataframe
add_confidence <- function(ft, confidence_support_rule_df, id_col, cores){
  
  plan(multisession, workers = cores)
  exp_confidence <- future_map(confidence_support_rule_df[,"consequent"],
                            ~calc_exp_confidence(ft, id_col, .x)) 
  
  return(cbind(exp_confidence, confidence_support_rule_df))
}

#lift function
calc_lift <- function(){
  
  
}

main <- function(){
  
  args <- commandArgs(trailingOnly = TRUE)
  if(args[1] == "--help" | args[1] == "-h"){
    help_msg <- c("\n",
                  "Function calculates support, confidence, and lift for ruleset",
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
  library(tidyverse, quietly = TRUE, warn.conflicts = FALSE)
  library(furrr, quietly = TRUE, warn.conflicts = FALSE)
  library(gtools, quietly = TRUE, warn.conflicts = FALSE)	
  
  #define args
  filename <- args[1]
  id_col <- args[2]
  cores <- args[3]
  minl <- args[4]
  maxl <- args[5]
  sup_thr <- args[6]
  
  #produce rule set dataframe col1 = antecedents, col2 = consequent
  plan(multisession, workers = cores)
  ante_conse_df <- sets %>%
    future_map_chr(~str_replace(.x, ";(?!.*;)", "  -->  ")) %>%
    str_split_fixed(., "  -->  ", n = 2) %>%
    as.data.frame() %>%
    rename("antecedents" = "V1", "consequent" = "V2")
  
}

main()