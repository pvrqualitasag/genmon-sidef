options(echo=TRUE)
library(qpdt)
s_pedig_path <- args<-commandArgs(trailingOnly = TRUE)
print(s_pedig_path)
check<-qpdt::check_pedig_parent(ps_pedig_path = s_pedig_path)

write.table(check$TblSireBdate$`#IDTier`,"IDsire.txt",col.names=FALSE,row.names=FALSE,quote=FALSE)
write.table(check$TblDamBdate$`#IDTier`,"IDdam.txt",col.names=FALSE,row.names=FALSE,quote=FALSE)
write.table(check$TblSireEqID$`#IDTier`,"Eqsire.txt",col.names=FALSE,row.names=FALSE,quote=FALSE)
write.table(check$TblDamEqID$`#IDTier`,"Eqdam.txt",col.names=FALSE,row.names=FALSE,quote=FALSE)
write.table(check$TblSireWrongSex$IDVater,"WrongSire.txt",col.names=FALSE,row.names=FALSE,quote=FALSE)
write.table(check$TblDamWrongSex$IDMutter,"WrongDam.txt",col.names=FALSE,row.names=FALSE,quote=FALSE)

check_pedig_parent(ps_pedig_path = s_pedig_path)
