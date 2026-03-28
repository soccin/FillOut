# Changelog

All notable changes to FillOut are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.0.0] - 2026-03-28

### Added
- `R/makeMinimalMaf.R` — utility script to trim a full MAF to the 29
  standard columns plus tumor/normal read-count columns, with
  deduplication on variant position
- `docs/INFO.md` — source repository link for GetBaseCountsMultiSample
- `CLAUDE.md` — architecture guide for the repository

### Changed
- Upgraded `GetBaseCountsMultiSample` v1.1.8 -> v1.2.5
- Ported to IRIS cluster (RHEL 8.7 / Lmod):
  - `fillOutCBE.sh`: replaced `SAMTOOLS=$(which samtools)` guard with
    `module load samtools`; replaced `$SAMTOOLS view` with bare
    `samtools view` (IRIS module does not export `$SAMTOOLS`)
  - `cvtGBCMS2VCF.py`: ported Python 2.7 -> Python 3 (shebang
    changed to `#!/usr/bin/env python3`; three `print >>fp` statements
    converted to `print(..., file=fp)`)
- `GenomeData` submodule updated with cluster-aware genome paths:
  all `genomeInfo_*.sh` files now use `getClusterName.sh` to switch
  between IRIS and Juno FASTA paths
- Expanded `usage()` in `fillOutCBE.sh` to document all options
  (`-v`, `-m`, `-Q`, `-B`), positional arguments, sample-name fallback
  behavior, and genome auto-detection

### Reorganized
- `fillOutCBE1BAM.sh` moved to `attic/` (retired single-BAM script)
- `fillOutCounterSpec.md` moved to `docs/`

## [1.0.0] - 2016-05-11

Initial release. Post-release patches through 2022 were never separately
tagged and are rolled into this entry.

### Added
- `fillOutCBE.sh` — main multi-sample fill-out pipeline wrapping
  `GetBaseCountsMultiSample`
- `cvtGBCMS2VCF.py` — converts GBCMS TSV output to VCFv4.2 with
  FORMAT fields: `DP:RD:AD:VF:DPP:DPN:RDP:RDN:ADP:ADN`
- `GenomeData` submodule for genome build detection and FASTA paths;
  initial builds: b37, hg19, mm9, mm10, GRCh37-lite
- DMP b37 genome support (`genomeInfo_b37_dmp.sh`)
- Dual input mode: accepts a BAM directory or a BAM list file
- `-v` / `-m` flags to force VCF or MAF input format
- Test data in `Test/` with reference inputs and expected outputs
- Counting specification in `fillOutCounterSpec.md`

### Changed (post-release patches)
- Upgraded `GetBaseCountsMultiSample` 1.1.6 -> 1.1.7 -> 1.1.8
- Fragment counting enabled; thread count set to 24
- Suppress harmless warnings with `--suppress_warning 3`
- Fixes for Illumina/Grail BAMs that do not set SM: tag in `@RG`
- MAF deduplication on VCF conversion (Chrom + Start + Ref + Alt)
