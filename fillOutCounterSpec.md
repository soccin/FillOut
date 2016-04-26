# Specification for FillOut Counters

## INPUT:

The following should be allowable inputs

* Valid VCF. Should accept both a full VCF (9 cols + samples) and a genotype free VCF with just the 8 columns

COL | NAME
-|-
1 | CHROM

aaaa

COL | NAME
--|--
1| #CHROM
2| POS
3| ID
4| REF
5| ALT
6| QUAL
7| FILTER
8| INFO

* TCGA MAF (see TCGA spec)

## Output:

A fully formed valid VCF file with the following FORMAT fields:

FIELD | Description
------|------------
DP	  | Total depth
RD    | Depth matching reference (REF) allele
AD    | Depth matching alternate (ALT) allele
VF    | Variant frequency (AD/DP)
DPP   | Depth on postitive strand
DPN   | Depth on negative strand
RDP   | Reference depth on postitive strand
RDN   | Reference depth on negative strand
ADP   | Alternate depth on postitive strand
ADN   | Alternate depth on negative strand

## Phase I default for counting:

Use the following default filters for the Phase I tests:

* MAPQ >= 20
* BASEQ >= 0
* Count improper pair (proper pair filter OFF)
* Do not count duplicates (duplicate filter ON)
* Count secondary alignments (secondary alignment filter OFF)

Use this VCF for counting:

```bash
/home/socci/Code/FillOut/TestMAF_VCF/hotspotList.vcf
/home/socci/Code/FillOut/TestMAF_VCF/hotspotList_8Col.vcf
```

Programs should work on both and give the same output.

Use these BAMs in:

```bash
/ifs/res/share/pwg/NormalCohort/SetA/CuratedBAMsSetA
```

* Proj_WES_Blacklist_v1_indelRealigned_recal_s_A2_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_ACC18_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_AMB4_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_AMB5_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_ASCM4_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_ASCM6_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_ASCM9_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_BR1_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_DS_bkm_087_N.bam
* Proj_WES_Blacklist_v1_indelRealigned_recal_s_DS_bkm_099_N.bam

The following file has these paths for easy use:

```bash
/home/socci/Code/FillOut/TestMAF_VCF/testBAMs_A1.list
```

