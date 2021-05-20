


# packages
require(dplyr)

# currently used changes
s_argus_pedig_path <- "PopReport_BV_20210510.csv"
tbl_argus_ped <- readr::read_delim(file = s_argus_pedig_path, 
                                   delim = ";",
                                   col_types = readr::cols(
                                     `ID Tier` = readr::col_integer(),
                                     `ID Vater` = readr::col_integer(),
                                     `ID Mutter` = readr::col_integer(),
                                     Geburtsdatum = readr::col_date(format = "%d.%m.%Y"),
                                     Geschlecht = readr::col_character(),
                                     `Nr Tier` = readr::col_integer(),
                                     `Nr Vater` = readr::col_integer(),
                                     `Nr Mutter` = readr::col_integer(),
                                     PLZ = readr::col_integer(),
                                     Fremdblut = readr::col_double()
                                   ))

l_ped_col_names <- list(old_cn    = names(tbl_argus_ped), 
                        ignore_cn = c("Nr Tier","Nr Vater","Nr Mutter"), 
                        new_cn    = c("#IDTier", "IDVater", "IDMutter", "Birthdate", "Geschlecht", "PLZ", "introg"),
                        add_cn    = c("inb_gen", "cryo"))

# if any columns are to be ignored
tbl_prp_ped <- tbl_argus_ped
if (!is.null(l_ped_col_names$ignore_cn)){
  # which of the old columns should be kept
  vec_keep_cn <- setdiff(l_ped_col_names$old_cn, l_ped_col_names$ignore_cn)
  
  # remove columns to be ignored and store it in a new tibble
  tbl_prp_ped <- tbl_prp_ped %>% select(vec_keep_cn)
  
}

# rename column names
if (!is.null(l_ped_col_names$new_cn)){
  names(tbl_prp_ped) <- l_ped_col_names$new_cn
}

# add columns to be added
if (!is.null(l_ped_col_names$add_cn)){
  tbl_prp_ped[,c(l_ped_col_names$add_cn)] <- NA
}

# exclude plz
vec_ignore_plz <- c(6300)
sapply(vec_ignore_plz, function(x) tbl_prp_ped$PLZ[tbl_prp_ped$PLZ == x] <<- NA, USE.NAMES = FALSE)


# write to file
readr::write_delim(tbl_prp_ped, path = paste0(s_argus_pedig_path, "_conv.csv"), delim = "|", na = "")


