#!/usr/bin/env Rscript


#produce rule set dataframe col1 = antecedents, col2 = consequent, col3 = sets
make_rules <- function(sets, cores){
  plan(multisession, workers = cores)
  out <- sets %>%
    future_map_chr(~str_replace(.x, ";(?!.*;)", "  -->  ")) %>%
    str_split_fixed(., "  -->  ", n = 2) %>%
    as.data.frame() %>%
    select("antecedents" = "V1", "consequent" = "V2") %>%
    cbind(., sets)
  return(out)
}

#support function calculates support support(A-->B) = num samples containing A and B / total number of samples
calc_support <- function(string, ft_pa, id_col){
  rule <- unlist(str_split(string, ";"))
  freq <- ft_pa %>%
    filter(.data[[id_col]] %in% rule) %>%
    select(-all_of(id_col)) %>%
    colSums() %>%
    as.numeric() 
  
  return(sum(freq == length(rule))/(ncol(ft_pa) - 1))
}

#calls support function
#add support column to rule dataframe and filter sets based on support threshold
add_support_filter <- function(ft, rule_df, id_col, cores, threshold){
  
  plan(multisession, workers = cores)
  support <- future_map_dbl(rule_df[,"sets"], ~calc_support(.x, ft, id_col)) 
  
  support_rule_df <- cbind(support, rule_df) %>%
    filter(support >= threshold) 
  
  return(support_rule_df)
}

#confidence function, calculates confidence, confidence(A-->B) = all samples containing A and B / samples contianing A
#takes present absent dataframe with support column added then calculates the confidence of the sets. 
#the last taxa in each set is the consequent while all taxa are taken as antecedents
calc_confidence <- function(rule_support, set_str, ft_pa, id_col){
  #rule_support = vector of antecedent support values
  #ft_pa = original present absent feature table with 1 taxa per row
  #set_str = set string ;
  
  #all samples containing antecedent and consequent
  freq_both_tbl <- ft_pa %>%
    filter(.data[[id_col]] %in% unlist(str_split(set_str, ";"))) %>%
    select(-all_of(id_col)) %>%
    colSums() %>%
    as.numeric() %>%
    table()
  
  freq_both <- freq_both_tbl[as.character(length(unlist(str_split(set_str, ";"))))]
  
  ante_vec <- unlist(str_split(set_str, ";")) 
  ante_vec <- ante_vec[-length(ante_vec)]
  
  #all samples containing only antecedent
  freq_ante_tbl <- ft_pa %>%
    filter(.data[[id_col]] %in% ante_vec) %>%
    select(-all_of(id_col)) %>%
    colSums() %>%
    as.numeric() %>%
    table()
  
  denominator <- freq_ante_tbl[as.character(length(ante_vec))]
  
  return(freq_both/denominator)
}

#add confidence column to rule dataframe
add_confidence <- function(ft, support_rule_df, id_col, cores){
  
  plan(multisession, workers = cores)
  confidence <- future_map2_dbl(support_rule_df[,"support"], 
                                support_rule_df[,"sets"], 
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
add_exp_confidence <- function(ft, confidence_support_rule_df, id_col, cores){
  
  plan(multisession, workers = cores)
  exp_confidence <- future_map_dbl(confidence_support_rule_df[,"consequent"],
                                   ~calc_exp_confidence(ft, id_col, .x)) 
  
  return(cbind(exp_confidence, confidence_support_rule_df))
}

#lift function, ratio of confidence and expected confidence
#add lift column to rule dataframe
add_lift <- function(exp_confidence_support_rule_df){
  
  lift_df <- exp_confidence_support_rule_df %>%
    mutate(lift = confidence/exp_confidence) %>%
    select(lift, everything())
  
  return(lift_df)
}


main <- function(){
  
  args <- commandArgs(trailingOnly = TRUE)
  if(args[1] == "--help" | args[1] == "-h"){
    help_msg <- c("\n",
                  "Function calculates support, confidence, and lift for ruleset",
                  "\tPositional arguments are:",
                  "\t[1] path to file present absent feature table (tsv)",
                  "\t[2] path to sets file single column tsv of feature combinations",
                  "\t[3] id column name in feature table",
                  "\t[4] number of cores",
                  "\t[5] support threshold (0-1)",
                  "\t[6] outfile name",
                  "Output to file in ../data",
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
  sets_file <- args[2]
  id_col <- args[3]
  cores <- args[4] %>% as.numeric()
  sup_thr <- args[5]
  out_name <- args[6]
  
  #read in files
  df <- read_tsv(filename,show_col_types = FALSE) %>%
    imap_dfc(~if(is.numeric(.x)){ifelse(.x > 0, 1, 0)} else(.x))
  
  sets <- read_tsv(sets_file,show_col_types = FALSE,col_names = FALSE) %>%
    pull(X1)
  
  #produce rule set dataframe col1 = antecedents, col2 = consequent, col3 = sets
  ante_conse_df <- make_rules(sets, cores)
  
  #calculate support
  supp_df <- add_support_filter(df, ante_conse_df, id_col, cores, sup_thr)
  #calculate confidence
  conf_supp_df <- add_confidence(df, supp_df, id_col, cores)
  #calculate expected confidence
  exp_conf_supp_df <- add_exp_confidence(df, conf_supp_df, id_col, cores)
  #calculate lift
  lift_exp_conf_supp_df <- add_lift(exp_conf_supp_df)
  
  write_tsv(lift_exp_conf_supp_df, str_glue("../data/{out_name}"))
  
}

main()