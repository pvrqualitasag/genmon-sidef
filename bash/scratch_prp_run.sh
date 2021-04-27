
sudo singularity shell --shell /bin/bash instance://gnmsicnt

# test
/home/gnmzws/simg/genmon-sidef/bash/run_poprep.sh \
-p /home/gnmzws/simg/genmon-sidef/par/gnm_config.par \
-d /home/gnmzws/gnm/prpinput/test_pedigree.dat.txt -Z &> /home/gnmzws/gnm/prplog/`date +"%Y%m%d%H%M%S"`_prp.log

# BV
/home/gnmzws/simg/genmon-sidef/bash/run_poprep.sh \
-p /home/gnmzws/simg/genmon-sidef/par/gnm_config.par \
-d /home/gnmzws/gnm/prpinput/PopReport_Braunvieh_20210325.csv_adaptfin7.csv -Z &> /home/gnmzws/gnm/prplog/`date +"%Y%m%d%H%M%S"`_prp.log


