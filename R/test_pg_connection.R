# Install the latest RPostgres release from CRAN:
# install.packages("RPostgres")


# Or the the development version from GitHub:
# install.packages("remotes")
# remotes::install_github("r-dbi/RPostgres")




# Install Deb-Pkg
# sudo apt install libpq-dev libssl-dev -y

# Installation of RPostgres
# sudo su - -c "R -e 'install.packages(\"RPostgres\", repo=\"https://cran.rstudio.com\", dependencies = TRUE)'"

# Check
is.element("RPostgres", installed.packages())


# Check connection
library(DBI)
# Connect to a specific postgres database i.e. Heroku
con <- dbConnect(RPostgres::Postgres(),dbname = 'PPP_xmKDvyg6exqF2', 
                 host = 'localhost', # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'
                 port = 5434, # or any other port specified by your DBA
                 user = 'apiis_admin',
                 password = 'pass')
str(con)

res <- dbSendQuery(con, "SELECT * FROM pg_catalog.pg_tables")
# show top of results
head(dbFetch(res))
# clear results
dbClearResult(res)
# disconnect
dbDisconnect(con)
