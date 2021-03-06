#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

BAM=$1
EVENTS=$2
OUT=$3

# Detect genome build
GENOME_BUILD=$($SDIR/getGenomeBuild.sh $BAM)
echo BUILD=$GENOME_BUILD

GENOME_SH=$SDIR/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit
fi

echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME

if [[ $EVENTS =~ \.vcf ]]; then
    EVENT_INPUT="--vcf $EVENTS"
    EVENT_TYPE="VCF"
else
    EVENT_INPUT="--maf $EVENTS"
    EVENT_TYPE="MAF"
fi

INPUTS=$(echo $BAM \
	| perl -ne 'chomp; m|_indelRealigned_recal_(\S+).bam|;print "--bam ",$1,":",$_,"\n"')

TMPFILE=_fill_$(uuidgen)
echo $TMPFILE

$SDIR/bin/GetBaseCountsMultiSample \
    --thread 12 \
	--filter_improper_pair 0 --fasta $GENOME \
	$EVENT_INPUT \
	--output $TMPFILE \
	$INPUTS

if [ "$EVENT_TYPE" == "MAF" ]; then
    $SDIR/cvtGBCMS2VCF.py $TMPFILE $OUT
    #rm $TMPFILE
else
    mv $TMPFILE $OUT
fi
