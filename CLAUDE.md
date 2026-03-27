# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Tool Does

FillOut enriches variant call files (VCF or MAF) with read depth counts across multiple BAM files. For each variant position, it uses `GetBaseCountsMultiSample` to count supporting reads per sample, then outputs a multi-sample VCF with FORMAT fields: `DP`, `RD`, `AD`, `VF`, `DPP`, `DPN`, `RDP`, `RDN`, `ADP`, `ADN`.

## Running the Tool

```bash
# Multi-sample fill (directory of BAMs or BAM list file)
./fillOutCBE.sh [-v|-m] [-Q MAPQ] [-B BASEQ] (BAMDIR|BAMLIST) EVENTS OUTPUT_FILE

# Single BAM fill
./fillOutCBE1BAM.sh [-v|-m] BAM_FILE EVENTS OUTPUT_FILE
```

- `-v` / `-m`: force VCF or MAF input (auto-detected from extension if omitted)
- `-Q`: mapping quality threshold (default: 20)
- `-B`: base quality threshold (default: 0)
- `EVENTS`: input VCF or MAF file with variant positions
- Output is always VCF format

## Architecture

### Workflow (`fillOutCBE.sh`)
1. Parse BAM list or glob `BAMDIR/*.bam`
2. Auto-detect genome build from first BAM's header via MD5 checksum (`GenomeData/getGenomeBuildBAM.sh`)
3. Source the matching `GenomeData/genomeInfo_<BUILD>.sh` to get `$GENOME` FASTA path
4. Extract sample names from BAM `@RG SM:` tags; fall back to filenames if SM tags are not unique
5. Run `bin/GetBaseCountsMultiSample` (24 threads) with `--maq`/`--baq` flags
6. If MAF input: convert GBCMS TSV output to VCF via `cvtGBCMS2VCF.py`; if VCF input: move output directly

### Key Components
- `bin/GetBaseCountsMultiSample` — symlink to versioned binary (currently v1.2.5); pre-compiled, not built here
- `GenomeData/` — git submodule (`soccin/GenomeData`); contains genome build detection and per-genome FASTA/annotation paths
- `cvtGBCMS2VCF.py` — converts GBCMS TSV (sample columns start at col 34) to VCFv4.2; de-duplicates variants on (Chrom, Start, Ref, Alt)
- `vcf2MultiMAF.sh` — optional downstream step; converts VCF output to per-sample MAFs using VEP (MSK cluster paths hardcoded)
- `_MAF_HEADER` — 94-column MAF v2.4 header used by `vcf2MultiMAF.sh`

### Genome Support
Supported builds (detected via BAM header sequence MD5): `b37`, `b37_dmp`, `hg19`, `hg19-mainOnly`, `GRCh37-lite`, `mm9Full`, `mm10`, `mm10_hBRAF_V600E`, `GRC_m38`, `b37+mm10` (xenograft).

### Default Counting Parameters
Per `fillOutCounterSpec.md`:
- MAPQ >= 20, BASEQ >= 0
- Improper pairs: counted (filter OFF)
- Duplicates: excluded (filter ON)
- Secondary alignments: counted (filter OFF)

## Test Data

`Test/` contains reference inputs and expected outputs:
- `hotspotList_8Col.vcf` — 8-column genotype-free VCF input
- `mafSimple.maf` — MAF input
- `*___FILL.vcf` — expected filled output files
- `bamsUsedInTests.txt` — BAM paths for NormalCohort SetA

## Dependencies

Runtime: `samtools`, `python3`, `perl`, `awk`, `uuidgen`

The `GenomeData` submodule must be initialized:
```bash
git submodule update --init
```
