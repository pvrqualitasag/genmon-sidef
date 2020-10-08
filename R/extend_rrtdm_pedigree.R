#' ---
#' title: Extend RRTDM-Pedigree 
#' date: 2020-10-07
#' ---
#' 
#' @title Extend RRTDM-Pedigree
#' 
#' @description 
#' RRTDM-Pedigree are the pedigrees used by Qualitas AG ZWS. The format for 
#' this pedigree is given by the export procedure.
#' 
#' @details 
#' The input pedigree can have different column separator formats.
#' 
#' @param 
#' 
extend_rrtdm_pedigree <- function(ps_input_pedigree,
                                  ps_column_sep = '|',
                                  pb_column_header = TRUE){
  ### # read pedigree
  tbl_ped <- readr::read_delim(file = ps_input_pedigree, 
                               delim = ps_column_sep, 
                               col_names = pb_column_header)
  
  
}