args <- commandArgs(trailingOnly = TRUE)

if (len(args) != 2) {
    cat("\nUsage: Rscript annoteMaf.R INPUT.maf ANNOTATION.maf\n\n")
    cat("  INPUT.maf       MAF to be annotated\n")
    cat("  ANNOTATION.maf  MAF containing HGVS annotation columns\n\n")
    quit(status = 1)
}

suppressPackageStartupMessages(library(tidyverse))

input_maf  <- args[1]
annot_maf  <- args[2]

maf   <- read_tsv(input_maf,  col_types = cols(.default = "c"),
    show_col_types = FALSE, progress = FALSE)
annot <- read_tsv(annot_maf,  col_types = cols(.default = "c"),
    show_col_types = FALSE, progress = FALSE)

# Pull the variant key columns plus any HGVS annotation columns
# from the annotation MAF, then left-join onto the input MAF.
annot_cols <- annot |>
    select(
        Chromosome, Start_Position, End_Position,
        Reference_Allele, Tumor_Seq_Allele1,
        matches("HGVS")
    )

maf_annotated <- left_join(maf, annot_cols)

# Build output filename: replace .maf extension with .annote.maf,
# or append .annote.maf if input doesn't end in .maf
if (str_detect(input_maf, "\\.maf$")) {
    output_maf <- str_replace(basename(input_maf), "\\.maf$", ".annote.maf")
} else {
    output_maf <- str_c(basename(input_maf), ".annote.maf")
}

cat("Input:      ", input_maf,  "\n")
cat("Annotation: ", annot_maf,  "\n")
cat("Output:     ", output_maf, "\n")

write_tsv(maf_annotated, output_maf, na = "")
