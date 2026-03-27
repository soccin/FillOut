args=commandArgs(trailing=T)

suppressPackageStartupMessages({
    library(readr)
    library(dplyr)
    })

maf=read_tsv(args[1],comment="#",col_types=c(.default="c"))

if(len(args)!=2) {

    #
    # Take basename of file and strip any
    # extension
    #

    ff=strsplit(basename(args[1]),"\\.")[[1]]
    min.maf=paste0(ff[-len(ff)],"_minMaf.maf")

} else {

    min.maf=args[2]

}

maf %>%
    select(1:29,matches("^[tn]_.*_count$")) %>%
    distinct(Chromosome,Start_Position,End_Position,Reference_Allele,Tumor_Seq_Allele2,.keep_all=T) %>%
    write_tsv(min.maf,na="")

