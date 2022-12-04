#!/usr/bin/env Rscript


## ---------------------------
##
## Script: make_test_data
##
## Purpose: produce a dataframe for function testing purposes
##
## Author: Ikaia Leleiwi
##
## Date Created: December 3rd, 2022
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

library(tidyverse)

test_df <- data.frame(id = letters[1:26])
for(i in 1:17){
  add_col <- rep(0,26)
  number_1s <- floor(runif(1, 1, 26))
  
  if(number_1s%%2 == 0){
    if(number_1s < 17/2){
      number_1s <- number_1s+8
    }
  }
  
  index <- floor(runif(number_1s, 1, 26))
  add_col[index] <- 1
  test_df <- cbind(test_df, add_col)
}
colnames(test_df) <- c("id", paste0(rep("s", 17), seq(1,17)))

write_tsv(test_df, "../data/test.tsv")
