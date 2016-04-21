#!/usr/bin/env python2.7

import sys
import csv
import os.path

gbcmsFile=sys.argv[1]
if len(sys.argv)==3:
    outVcf=sys.argv[2]
else:
    outVcf=os.path.splitext(os.path.basename(gbcmsFile))[0]+".vcf"

VCFHEADER="""
##fileformat=VCFv4.2
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read depth">
##FORMAT=<ID=RD,Number=1,Type=Integer,Description="Read depth matching REF">
##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Read depth matching ALT">
##FORMAT=<ID=VF,Number=1,Type=Float,Description="Variant Frequence (RD/DP)">
##FORMAT=<ID=DPP,Number=1,Type=Integer,Description="Read depth positive strand reads">
##FORMAT=<ID=RDP,Number=1,Type=Integer,Description="Read depth matching REF positive reads">
##FORMAT=<ID=ADP,Number=1,Type=Integer,Description="Read depth matching ALT positive reads">
"""

VCFCOLS="#CHROM  POS ID  REF ALT QUAL    FILTER  INFO    FORMAT".split()

FORMAT="DP:RD:AD:VF:DPP:RDP:ADP"
formatFields=FORMAT.split(":")

with open(outVcf,"w") as outfp:
    print >>outfp, VCFHEADER.strip()

    with open(gbcmsFile) as fp:
        cin=csv.DictReader(fp,delimiter="\t")
        samples=cin.fieldnames[34:]
        print >>outfp, "\t".join(VCFCOLS+samples)

        for r in cin:
            out=[
                r["Chrom"],
                r["Start"],
                ".",
                r["Ref"],
                r["Alt"],
                ".",
                ".",
                ".",
                FORMAT
                ]

            for si in samples:
                gt=[]
                sampleDat=dict([x.split("=") for x in r[si].split(";")])
                for fi in formatFields:
                    gt.append(sampleDat[fi])
                out.append(":".join(gt))

            print >>outfp, "\t".join(out)