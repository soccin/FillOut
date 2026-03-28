suppressPackageStartupMessages({
  library(tidyverse)
})

usage <- "
Usage: Rscript fillOutReport.R <input.maf> [output.xlsx]

  input.maf   : MAF file (tab-separated, any column types)
  output.xlsx : Output Excel report (default: <input.maf>.rpt.xlsx)

Produces a wide-format Excel report from a MAF file. Each row is a unique
variant (Gene + Alteration + Genomic coordinate). Per-sample metrics
(VF, AD, DP) are pivoted into separate columns named <Sample>::VF etc.

Variant filtering:
  - Synonymous variants (HGVSp_Short ending in '=') are excluded
  - Exception: TERT 5'Flank variants are always retained (promoter mutations)
"

argv <- commandArgs(trailingOnly = TRUE)

if (len(argv) < 1 || len(argv) > 2) {
  cat(usage)
  quit(status = 1)
}

input_maf <- argv[1]

if (!file.exists(input_maf)) {
  cat("\nERROR: MAF file not found:", input_maf, "\n\n")
  quit(status = 1)
}

output_rpt <- if (len(argv) == 2) argv[2] else str_c(basename(input_maf), ".rpt.xlsx")
output_rpt <- str_replace(output_rpt,".maf","")

cat("Input MAF :", input_maf, "\n")
cat("Output    :", output_rpt, "\n")

# Read all columns as character so mixed-type columns don't get mangled;
# type_convert at the end will infer proper types.
maf <- read_tsv(input_maf, col_types = cols(.default = "c"), progress = FALSE)

cat("Variants  :", nrow(maf), "\n")
cat("Samples   :", n_distinct(maf$Tumor_Sample_Barcode), "\n")

# Build the report table:
#
# 1. Construct a short genomic coordinate string (chr:pos:ref>alt)
# 2. Select/rename the columns we care about; convert VF to numeric up front
# 3. Pivot DP/AD/VF long so we can create per-sample column names like
#    "SAMPLE_ID::VF", then spread back wide — one row per variant
# 4. Reorder columns: annotation cols first, then all ::VF, ::AD, ::DP
# 5. Drop synonymous variants (HGVSp ends with '=' means silent/synonymous),
#    but keep TERT 5'Flank regardless (these are promoter mutations with no
#    protein change annotation)
tbl <- maf |>
  mutate(
    Genomic = str_c(
      Chromosome, ":", Start_Position, ":",
      Reference_Allele, ">", Tumor_Seq_Allele2
    )
  ) |>
  transmute(
    Sample = Tumor_Sample_Barcode,
    Gene = Hugo_Symbol,
    Alteration = HGVSp_Short,
    Genomic,
    DP = t_total_count,
    VF = round(as.numeric(t_variant_frequency), 3),
    AD = t_alt_count,
    Type = Variant_Classification
  ) |>
  # Pivot DP/AD/VF long, then unite sample+metric into a single key
  gather(K, V, DP, AD, VF) |>
  unite(SK, Sample, K, sep = "::") |>
  # Pivot back wide: one column per sample-metric combination
  spread(SK, V) |>
  select(1:4, matches("::VF"), matches("::AD"), matches("::DP")) |>
  filter(
    # Keep non-synonymous variants (synonymous have '=' at end of HGVSp)
    (!str_detect(Alteration, "=$") & !is.na(Alteration)) |
      # Always keep TERT promoter mutations (no HGVSp annotation)
      (str_detect(Gene, "TERT") & Type == "5'Flank")
  ) %>%
  # Re-infer column types (DP/AD should be integer, VF numeric)
  suppressMessages(type_convert(.))

cat("Variants (filtered):", nrow(tbl), "\n")

write_xlsx(tbl, output_rpt)
cat("Done.\n")
