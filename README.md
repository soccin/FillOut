# FillOut

Enriches variant call files (VCF or MAF) with per-sample read depth counts
across one or more BAM files. For each variant position, uses
`GetBaseCountsMultiSample` to tally supporting reads, then outputs a
multi-sample VCF with FORMAT fields: `DP`, `RD`, `AD`, `VF`, `DPP`, `DPN`,
`RDP`, `RDN`, `ADP`, `ADN`.

## Usage

```bash
# Multi-sample fill (directory of BAMs or BAM list file)
./fillOutCBE.sh [-v|-m] [-Q MAPQ] [-B BASEQ] (BAMDIR|BAMLIST) EVENTS OUTPUT.vcf
```

Options:
- `-v` / `-m` — force VCF or MAF input (auto-detected from extension if omitted)
- `-Q MAPQ` — minimum mapping quality (default: 20)
- `-B BASEQ` — minimum base quality (default: 0)

`BAMDIR` is a directory of `*.bam` files; `BAMLIST` is a plain-text file with
one BAM path per line. Sample names are taken from `@RG SM:` tags; if SM tags
are not unique the BAM filename is used instead.

Output is always VCF format regardless of input type.

## Requirements

- `samtools` (loaded via `module load samtools`)
- `python3`
- `bin/GetBaseCountsMultiSample` (pre-compiled binary, currently v1.2.5)
- `GenomeData` submodule initialized: `git submodule update --init`
- `~/bin/getClusterName.sh` returning `IRIS` or `JUNO`

## Supported Genome Builds

Auto-detected from the BAM header MD5 checksum:
`b37`, `b37_dmp`, `hg19`, `hg19-mainOnly`, `GRCh37-lite`,
`mm9Full`, `mm10`, `mm10_hBRAF_V600E`, `GRC_m38`, `b37+mm10`

## Counting Parameters

See `docs/fillOutCounterSpec.md` for the full counting specification.
Defaults: MAPQ >= 20, BASEQ >= 0, duplicates excluded, improper pairs counted.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
