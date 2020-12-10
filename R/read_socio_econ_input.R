#' ---
#' title: Reading BFS Socio Economic Data
#' date:  2020-12-03
#' ---
#' 
#' 
#' ## Input
#' The input consist of an xlsx file. From prior inspection of the xlsx-file, we can 
#' see that the data starts on row 6 and it ends on row 2204. These numbers are defined 
#' as variables `n_start_row` and `n_end_row`.
#+ input-xlsx
s_in_dir <- here::here('input/socio_econ_bfs')
list.files(s_in_dir, full.names = TRUE)
s_xlsx_input <- file.path(s_in_dir, 'je-d-21.03.01.xlsx')
n_start_row <- 6
n_end_row <- 2204

#' The xlsx-inputfile is read and stored as a data.frame.
#+ read-xlsx
wb_se_in <- openxlsx::read.xlsx(xlsxFile = s_xlsx_input,
                                startRow = n_start_row)

#' Check GemeindeCode 292
head(wb_se_in)
any(wb_se_in$Gemeindecode == 292)

#' The first three rows correspond to data that are associated with the complete 
#' country. Hence these are ignored here.
#+ itnore-country-data
wb_se_in <- wb_se_in[3:n_end_row, ]
dim(wb_se_in)
str(wb_se_in)

#' Replace duplicated columnnames
cn_com_data <- colnames(wb_se_in)
dup_cn <- which(duplicated(cn_com_data))
cn_com_data[dup_cn]
cn_com_data[which(cn_com_data == cn_com_data[dup_cn][1])] <- c("Veränderung.in.ha.Siedlungsfläche","Veränderung.in.ha.Landwirtschaft")
cn_com_data[which(cn_com_data == cn_com_data[dup_cn][2])] <- c("Beschäftigte.im.1..Sektor", "Arbeitsstätten.im.1..Sektor")
cn_com_data[which(cn_com_data == cn_com_data[dup_cn][3])] <- c("Beschäftigte.im.2..Sektor","Arbeitsstätten.im.2..Sektor")
cn_com_data[which(cn_com_data == cn_com_data[dup_cn][4])] <- c("Beschäftigte.im.3..Sektor","Arbeitsstätten.im.3..Sektor")
cn_com_data
stopifnot(length(which(duplicated(cn_com_data))) == 0) 
colnames(wb_se_in) <- cn_com_data

#' The following statements should check the validity of the first column.
#+ check-first-col
which(is.na(wb_se_in$Gemeindecode))
gc_non_na <- wb_se_in$Gemeindecode[!is.na(wb_se_in$Gemeindecode)]
num_ofs <- as.numeric(gc_non_na)
min(num_ofs)
max(num_ofs)
wb_se_in[1:3,]

#' The length of num_ofs must be the same as nrow of wb_se_in
stopifnot(length(num_ofs) == nrow(wb_se_in))


#' ## Prepare socio-economic Data for GenMon
#' The single columns according to the tutorial are collected into a tibble. 
#' 
#' ### Unemployment Rate
#' According to the tutorial the unemployment_rate can be replaced by the social 
#' assistance rate. A search on the BFS-websites showed that the unemployment rates 
#' are only available for regions (Bezirke) but not for communities. The numbers 
#' for the regions can be downloaded from https://www.amstat.ch/v2/index.jsp?lang=de 
#' under 'Details'. 
#' 
#' ### Median Income
#' The values for median income are based on the average income used for taxes 
#' (https://www.atlas.bfs.admin.ch/maps/13/de/15131_9164_8282_8281/23873.html).
#+ income-data
s_income_xlsx <- file.path(s_in_dir, '23873_131.xlsx')
n_income_start_row <- 4
n_income_end_row <- 2295
wb_income <- openxlsx::read.xlsx(xlsxFile = s_income_xlsx,
                                 startRow = n_income_start_row)

#' Cut the legend at the end, and ignore the first row which corresponds to 
#' the country-wide values
#+ ignore-legend-rm-country
wb_income <- wb_income[2:n_income_end_row,]
colnames(wb_income) <- c("Regions-ID", "Regionsname","Totales Steuerbares Einkommen","Mittleres Steuerbares Einkommen")
dim(wb_income)
head(wb_income)
tail(wb_income)
any(wb_income$`Regions-ID` == 292)

#' The income data are joined to the community data and the average income is converted into 
#' a numeric variable.
#+ join-income-to-community
library(dplyr)
wb_mean_income <- wb_income %>% select("Regions-ID", "Mittleres Steuerbares Einkommen")
wb_mean_income$`Mittleres Steuerbares Einkommen` <- as.numeric(wb_mean_income$`Mittleres Steuerbares Einkommen`)
head(wb_mean_income)
wb_se_in <- wb_se_in %>% left_join(wb_mean_income, by = c('Gemeindecode' = 'Regions-ID'))
head(wb_se_in)
dim(wb_se_in)
which(is.na(wb_se_in$`Mittleres Steuerbares Einkommen`))
any(wb_se_in$Gemeindecode == 292)

#' The values for the columns 'grazing surface ha' and for the change in primary sector is obtained from
#' the STAT-Tab link (https://www.pxweb.bfs.admin.ch/pxweb/de/px-x-0702000000_104/px-x-0702000000_104/px-x-0702000000_104.px)  
#' reached from https://www.bfs.admin.ch/bfs/de/home/statistiken/kataloge-datenbanken/daten.assetdetail.12727132.html 
#' From the STAT-Tab link, the data can be selected and downloaded as .csv-files. The encoding of the downloaded files 
#' is Wester-ISO 8859. The change in the number of jobs in the primary sector is extracted from the file 'change_job_primary_sector_px-x-0702000000_104.csv'.
#' The grazing surface is taken from 'grazing_surface_px-x-0702000000_104.csv'. The first step is to read the data from the 
#' downloaded files.
#+ read-job-prim-sect
s_jb_prim_in <- file.path(s_in_dir, 'change_job_primary_sector_px-x-0702000000_104.csv')
tbl_jb_prim <- readr::read_delim(file = s_jb_prim_in, delim = ';', skip = 2)

#' In tbl_jb_prim, we are only interested in the community data, hence, we have to delete all 
#' records that have a `Kanton (-) / Bezirk (>>) / Gemeinde (......)` entry starting with '>> Bezirk '
colnames(tbl_jb_prim)
# sapply(tbl_jb_prim[,2], function(x) substr(x, 4, 9), USE.NAMES = FALSE)
tbl_jb_prim[34,2]

dim(tbl_jb_prim)
head(tbl_jb_prim)

#' Extract community numbers from column `Kanton (-) / Bezirk (>>) / Gemeinde (......)`
raw_com_id_col <- tbl_jb_prim$`Kanton (-) / Bezirk (>>) / Gemeinde (......)`
vec_comm_id <- sapply(raw_com_id_col, function(x) gsub('\\.', '', unlist(strsplit(x, split = ' '))[1]), USE.NAMES = FALSE)
vec_comm_id_L <- as.integer(vec_comm_id)

#' Add them to tbl_jb_prim
tbl_jb_prim <- bind_cols(tbl_jb_prim, tibble::tibble(GemeindeID = vec_comm_id_L))
vec_gem_id_not_na <- which(!is.na(tbl_jb_prim$GemeindeID))
tbl_jb_prim <- tbl_jb_prim[vec_gem_id_not_na, c('GemeindeID', '2014')]
colnames(tbl_jb_prim) <- c('GemeindeID', 'JobsPrimSec2014')
head(tbl_jb_prim)
tail(tbl_jb_prim)
dim(tbl_jb_prim)

#' Check content of GemeindeID
#+ check-gemeindeid
which(is.na(tbl_jb_prim$GemeindeID))
max(tbl_jb_prim$GemeindeID)
nrow(tbl_jb_prim)
nrow(wb_se_in)
stopifnot(length(setdiff(tbl_jb_prim$GemeindeID, wb_se_in$Gemeindecode)) == 0)

any(wb_se_in$Gemeindecode == 292)
any(tbl_jb_prim$GemeindeID == 292)

which(is.na(wb_se_in$Gemeindecode))
which(is.na(tbl_jb_prim$GemeindeID))

#' Join the number of jobs five years ago
tbl_jb_prim$GemeindeID <- as.character(tbl_jb_prim$GemeindeID)
wb_se_in <- wb_se_in %>% inner_join(tbl_jb_prim, by = c('Gemeindecode' = 'GemeindeID'))
dim(wb_se_in)
head(wb_se_in)

#' Grazing surface are obtained from 'grazing_surface_px-x-0702000000_104.csv'
#+ read-gs
s_gs_input <- file.path(s_in_dir, 'grazing_surface_px-x-0702000000_104.csv')
tbl_gs <- readr::read_delim(file = s_gs_input, delim = ';', skip = 2)
head(tbl_gs)
dim(tbl_gs)

raw_com_id_col <- tbl_gs$`Kanton (-) / Bezirk (>>) / Gemeinde (......)`
vec_comm_id <- sapply(raw_com_id_col, function(x) gsub('\\.', '', unlist(strsplit(x, split = ' '))[1]), USE.NAMES = FALSE)
vec_comm_id_L <- as.integer(vec_comm_id)

#' Add them to tbl_gs
tbl_gs <- bind_cols(tbl_gs, tibble::tibble(GemeindeID = vec_comm_id_L))
vec_gem_id_not_na <- which(!is.na(tbl_gs$GemeindeID))
tbl_gs <- tbl_gs[vec_gem_id_not_na, c('GemeindeID', '2018')]
colnames(tbl_gs) <- c('GemeindeID', 'GracingSurface2018')
tbl_gs$GemeindeID <- as.character(tbl_gs$GemeindeID)
head(tbl_gs)
tail(tbl_gs)
dim(tbl_gs)

wb_se_in <- wb_se_in %>% inner_join(tbl_gs, by = c('Gemeindecode' = 'GemeindeID'))
dim(wb_se_in)
head(wb_se_in)

#' The single columns are collected into `tbl_se_gnm`.
#+ prepare-se-data
tbl_se_gnm <- tibble::tibble(num_ofs                 = wb_se_in$Gemeindecode,
                             demog_balance           = round(as.numeric(wb_se_in$`Veränderung.in.%`), digits = 2),
                             median_income           = round(wb_se_in$`Mittleres Steuerbares Einkommen`, digits = 0),
                             unemployment_rate       = round(as.numeric(wb_se_in$`Sozialhilfequote.3)`), digits = 2),
                             job_primary_sector      = wb_se_in$`Beschäftigte.im.1..Sektor`,
                             job_total               = wb_se_in$Beschäftigte.total,
                             grazing_surface_ha      = wb_se_in$GracingSurface2018,
                             total_suface_km2        = wb_se_in$`Gesamtfläche.in.km²`,
                             job_primary_sector_past = wb_se_in$JobsPrimSec2014,
                             percent_less_19         = wb_se_in$`0-19.Jahre`,
                             percent_more_65         = wb_se_in$`65.Jahre.und.mehr`)
head(tbl_se_gnm)

#' Check NAs introduced
#' demog_balance
which(is.na(tbl_se_gnm$demog_balance)) # integer(0) ==> ok

#' unemployment rate
vec_uer_na_idx <- which(is.na(tbl_se_gnm$unemployment_rate))
length(vec_uer_na_idx)
tbl_se_gnm[vec_uer_na_idx[2],]

wb_se_in[wb_se_in$Gemeindecode == '21',]
wb_se_in[wb_se_in$Gemeindecode == '21',"Sozialhilfequote.3)"]
wb_se_in[wb_se_in$Gemeindecode == '23',"Sozialhilfequote.3)"]

#' ## Replace Missing Values
#' Missing values are replaced by medians or means of the other communities in the same county (Bezirk)
#' Read the county to community association data.
#+ read-county-data
s_cnty_input <- file.path(s_in_dir, 'be-b-00.04-agv-01.xlsx')
df_cnty <- openxlsx::read.xlsx(xlsxFile = s_cnty_input, sheet = 'GDE')
head(df_cnty)
tail(df_cnty)
dim(df_cnty)
df_cnty$GDENR <- as.character(df_cnty$GDENR)
setdiff(wb_se_in$Gemeindecode, df_cnty$GDENR)

#' communities present in wb_se_in and missing in df_cnty
wb_se_in[wb_se_in$Gemeindecode == '5095',"Gemeindename"]
wb_se_in[wb_se_in$Gemeindecode == "5102","Gemeindename"]
wb_se_in[wb_se_in$Gemeindecode == "5105","Gemeindename"]
wb_se_in[wb_se_in$Gemeindecode == "5129","Gemeindename"]
wb_se_in[wb_se_in$Gemeindecode == "5135","Gemeindename"]

#' according to info-sheet in 'be-b-00.04-agv-01.xlsx', they are all combined to the community of 'Verzasca'
#' which is present in df_cnty
df_cnty[df_cnty$GDENAME == 'Verzasca', ]
df_cnty_joined <- df_cnty %>% select(GDENR, GDEBZNR)
head(df_cnty_joined)

#' join df_cnty to wb_se_in via a left_join
#+ join-df-cnty
wb_se_in <- wb_se_in %>% left_join(df_cnty_joined, by = c('Gemeindecode' = 'GDENR'))
head(wb_se_in)
dim(wb_se_in)

#' fill in missing GDEBZNR values. According to 'be-b-00.04-agv-01.xlsx', these communities are joined into
#' the community of 'Verzasca', hence bznr for the missing GDEBZNR is set to the same value as for 
#' 'Verzasca'
#+ fill-missing-gdebznr
vec_bznr_na <- which(is.na(wb_se_in$GDEBZNR))
wb_se_in[vec_bznr_na,] 

#' Verzasca
df_cnty[df_cnty$GDENAME == 'Verzasca', ]
df_cnty[df_cnty$GDENAME == 'Verzasca', 'GDEBZNR']
wb_se_in[vec_bznr_na,'GDEBZNR'] <- df_cnty[df_cnty$GDENAME == 'Verzasca', 'GDEBZNR']
which(is.na(wb_se_in$GDEBZNR))
stopifnot(length(which(is.na(wb_se_in$GDEBZNR))) == 0)


#' ## Imputation of Missing Values
#' Input data contain missing values which are mostly characterised with 'X'. Those 
#' values are to be replaced with the median of the county. The following function 
#' is used to do this imputation
#+ impute-mv-fun
impute_missing_values <- function(pdf_se, ps_impute_col){
  # copy argument to result data.frame
  df_result_se <- pdf_se
  # check class of column ps_impute_col in df_result_se and convert to numeric
  #  if necessary
  if (!is.element('numeric', class(df_result_se[, ps_impute_col])) && 
      !is.element('integer', class(df_result_se[, ps_impute_col]))){
    df_result_se[, ps_impute_col] <- as.numeric(df_result_se[, ps_impute_col])
  }
  # get the vector of introduced NA from above conversion
  vec_cur_na <- which(is.na(df_result_se[, ps_impute_col]))
  # stop here, if vec_cur_na is empty
  if (length(vec_cur_na) == 0) return(df_result_se)
  # get the variable to compute the median 
  var_symbol <- sym(ps_impute_col)
  med_var <- paste0('med_', ps_impute_col)
  # get tibble with medians grouped by county
  tbl_med_cnty <- df_result_se %>%
    group_by(GDEBZNR) %>%
    summarise(!!med_var := median((!!var_symbol), na.rm = TRUE))
  # loop over vec cur_na
  for (idx in seq_along(vec_cur_na)){
    # get bznr for current na-record
    cur_bznr <- df_result_se[vec_cur_na[idx], 'GDEBZNR']
    cur_med_value <- tbl_med_cnty[tbl_med_cnty$GDEBZNR == cur_bznr, med_var][[1]]
    df_result_se[vec_cur_na[idx], ps_impute_col] <- cur_med_value
  }
  return(df_result_se)
  
}
#' Testing the above function
#+ test-imp-fun
wb_se_in <- wb_se_in %>% mutate(SHQ3 = `Sozialhilfequote.3)`)
head(wb_se_in)
class(wb_se_in$SHQ3)
class(wb_se_in$`Sozialhilfequote.3)`)

# NA-Values in SHQ3
shq3_na <- which(wb_se_in$SHQ3 == 'X')
head(wb_se_in[shq3_na,"SHQ3"])

wb_se_in2 <- impute_missing_values(pdf_se = wb_se_in, ps_impute_col = 'SHQ3')
class(wb_se_in2$SHQ3)
which(is.na(wb_se_in2$SHQ3))

# debug
pdf_se = wb_se_in;ps_impute_col = 'SHQ3'

#' 
#' unemployment rate based on social assistence
vec_sa_na <- which(wb_se_in$`Sozialhilfequote.3)` == 'X')
length(vec_sa_na)
head(wb_se_in[vec_sa_na,])

#' Make a numeric version of SA
wb_se_in <- wb_se_in %>% mutate(SoHiQuo = as.numeric(wb_se_in$`Sozialhilfequote.3)`))
head(wb_se_in)
dim(wb_se_in)

tbl_med_sa <- wb_se_in %>% 
  group_by(GDEBZNR) %>%
  summarise(MedSoHiQuo = median(SoHiQuo, na.rm = 'TRUE'))
head(tbl_med_sa)
dim(tbl_med_sa)

#' Impute missing values
for (i in seq_along(vec_sa_na)){
  cur_bznr <- wb_se_in[vec_sa_na[i],'GDEBZNR']
  cur_medshq <- tbl_med_sa[tbl_med_sa$GDEBZNR == cur_bznr,]$MedSoHiQuo
  wb_se_in[vec_sa_na[i],'SoHiQuo'] <- cur_medshq
}
vec_sa_na <- which(is.na(wb_se_in$SoHiQuo))
length(vec_sa_na)

#' Beschäftigte 1. Sektor
wb_se_in <- wb_se_in %>% mutate(Bs1Sek = as.numeric(wb_se_in$`Beschäftigte.im.1..Sektor`))
vec_bs1s_na <- which(is.na(wb_se_in$Bs1Sek))
length(vec_bs1s_na)
#' median summary
tbl_med_bs1s <- wb_se_in %>%
  group_by(GDEBZNR) %>%
  summarise(MedBs1s = median(Bs1Sek, na.rm = TRUE))
head(tbl_med_bs1s)
#' impute


#' Put together
tbl_se_gnm <- tibble::tibble(num_ofs                 = wb_se_in$Gemeindecode,
                             demog_balance           = round(as.numeric(wb_se_in$`Veränderung.in.%`), digits = 2),
                             median_income           = round(wb_se_in$`Mittleres Steuerbares Einkommen`, digits = 0),
                             unemployment_rate       = round(wb_se_in$SoHiQuo, digits = 2),
                             job_primary_sector      = wb_se_in$`Beschäftigte.im.1..Sektor`,
                             job_total               = wb_se_in$Beschäftigte.total,
                             grazing_surface_ha      = wb_se_in$GracingSurface2018,
                             total_suface_km2        = wb_se_in$`Gesamtfläche.in.km²`,
                             job_primary_sector_past = wb_se_in$JobsPrimSec2014,
                             percent_less_19         = wb_se_in$`0-19.Jahre`,
                             percent_more_65         = wb_se_in$`65.Jahre.und.mehr`)
head(tbl_se_gnm)
#' unemployment rate
vec_uer_na_idx <- which(is.na(tbl_se_gnm$unemployment_rate))
length(vec_uer_na_idx)

#' job primary
vec_jp_na <- which(is.na(tbl_se_gnm$job_primary_sector))
vec_jp_na
class(tbl_se_gnm$job_primary_sector)
as.numeric(tbl_se_gnm$job_primary_sector)

#' Write to file
readr::write_delim(tbl_se_gnm, path = file.path(s_in_dir, paste0(format(Sys.time(), '%Y%m%d%H%M%S'), '_gnm_socio_econ_data.csv')), delim = ';', na = '')
























