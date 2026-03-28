# makeMinimalMaf.R
#
# Trim a full MAF file down to a compact "minimal" MAF that is
# easier to work with: keep the standard MAF columns (cols 1-29)
# plus the tumor/normal read-count columns, and remove any
# duplicate variant rows.
#
# Why bother?  Full MAFs from pipelines like Mutect/Strelka can
# have 100+ columns and thousands of duplicated rows.  Downstream
# tools (R, IGV, cBioPortal) are much happier with a lean file
# that only has what you actually need.
#
# Usage:
#   Rscript makeMinimalMaf.R INPUT.maf [OUTPUT.maf]
#
#   INPUT.maf   - Full MAF file (required)
#   OUTPUT.maf  - Where to write the trimmed MAF (optional).
#                 If omitted, output is written next to the input
#                 file with "_minMaf.maf" appended to the stem,
#                 e.g.  sample_calls.maf -> sample_calls_minMaf.maf
#
# Columns kept:
#   - Cols 1-29  : Standard MAF v2.4 fields (Hugo_Symbol through
#                  Tumor_Sample_Barcode, etc.)
#   - t_*_count  : Tumor  read-count columns (ref/alt depth, etc.)
#   - n_*_count  : Normal read-count columns
#
# Deduplication key: Chromosome + Start_Position + End_Position
#                    + Reference_Allele + Tumor_Seq_Allele2
# All columns are read as character to avoid type-guessing
# mangling alleles that look like numbers (e.g. "1/2", "10").

args <- commandArgs(trailingOnly = TRUE)

if (len(args) < 1) {
    cat("\nUsage: Rscript makeMinimalMaf.R INPUT.maf [OUTPUT.maf]\n\n")
    quit(status = 1)
}

suppressPackageStartupMessages({
    library(readr)
    library(dplyr)
    library(stringr)
})

# Read everything as character -- MAF allele fields can look like
# numbers and will be silently mangled if you let readr guess types.
maf <- read_tsv(args[1], comment = "#", col_types = c(.default = "c"),
    show_col_types = FALSE)

# Build output path if the caller did not supply one.
if (len(args) < 2) {
    # Remove the last extension (e.g. ".maf") and append suffix.
    # str_split_1 handles dotted stems like "sample.v2.maf" correctly.
    ff <- str_split_1(basename(args[1]), "\\.")
    min_maf <- str_c(str_c(ff[-len(ff)], collapse = "."), "_minMaf.maf")
} else {
    min_maf <- args[2]
}

cat("Input : ", args[1], "\n")
cat("Output: ", min_maf, "\n")

maf |>
    # Keep the 29 standard MAF columns plus any tumor/normal count
    # columns added by the fill-out step (t_ref_count, t_alt_count,
    # n_ref_count, n_alt_count, etc.).
    select(1:29, matches("^[tn]_.*_count$"),matches("^HGVS")) |>
    # Drop duplicate variants -- same position & alleles get one row.
    # .keep_all = TRUE means we keep every selected column, not just
    # the key columns used for deduplication.
    distinct(
        Chromosome, Start_Position, End_Position,
        Reference_Allele, Tumor_Seq_Allele2,
        .keep_all = TRUE
    ) |>
    # na = "" writes missing values as empty fields, which is the
    # MAF convention (not "NA").
    write_tsv(min_maf, na = "")

cat("Done.\n")
