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
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Total depth">
##FORMAT=<ID=RD,Number=1,Type=Integer,Description="Depth matching reference (REF) allele">
##FORMAT=<ID=AD,Number=1,Type=Integer,Description="Depth matching alternate (ALT) allele">
##FORMAT=<ID=VF,Number=1,Type=Float,Description="Variant frequence (AD/DP)">
##FORMAT=<ID=DPP,Number=1,Type=Integer,Description="Depth on postitive strand">
##FORMAT=<ID=DPN,Number=1,Type=Integer,Description="Depth on negative strand">
##FORMAT=<ID=RDP,Number=1,Type=Integer,Description="Reference depth on postitive strand">
##FORMAT=<ID=RDN,Number=1,Type=Integer,Description="Reference depth on negative strand">
##FORMAT=<ID=ADP,Number=1,Type=Integer,Description="Alternate depth on postitive strand">
##FORMAT=<ID=ADN,Number=1,Type=Integer,Description="Alternate depth on negative strand">
"""

VCFCOLS="#CHROM  POS ID  REF ALT QUAL    FILTER  INFO    FORMAT".split()

FORMAT="DP:RD:AD:VF:DPP:DPN:RDP:RDN:ADP:ADN"
formatFields=FORMAT.split(":")

eventsSeen=set()

with open(outVcf,"w") as outfp:
    print >>outfp, VCFHEADER.strip()

    with open(gbcmsFile) as fp:
        cin=csv.DictReader(fp,delimiter="\t")
        samples=cin.fieldnames[34:]
        print >>outfp, "\t".join(VCFCOLS+samples)

        for r in cin:

            # DeDup MAF based fillOut output

            key=(r["Chrom"],r["Start"],r["Ref"],r["Alt"])
            if key in eventsSeen:
                continue
            eventsSeen.add(key)

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
                sampleDat["DPN"]=int(sampleDat["DP"])-int(sampleDat["DPP"])
                sampleDat["RDN"]=int(sampleDat["RD"])-int(sampleDat["RDP"])
                sampleDat["ADN"]=int(sampleDat["AD"])-int(sampleDat["ADP"])
                for fi in formatFields:
                    gt.append(sampleDat[fi])
                out.append(":".join(map(str,gt)))

            print >>outfp, "\t".join(out)
