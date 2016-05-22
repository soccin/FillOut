#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ $# -lt 3 ]; then
    echo
    echo "  usage: fillOutCBE.sh [BAMDIR|BAMLIST] EVENTS.[MAF|VCF] OUTPUT_FILE"
    echo
    echo BAMDIR = Directory with BAM files. Will process all
    echo BAMLIST = File with paths to BAM files, one per line
    echo
    exit
fi

ARG1=$1
UUID=$(uuidgen)
BAMDIR=""

if [ -d "$ARG1" ]; then
    BAMDIR=$1
    BAMDIR=$(echo $BAMDIR | sed 's/\/$//')
    BAMLIST=_bamlist_$UUID
    echo "TEMP BAMLIST = "$BAMLIST
    ls $BAMDIR/*.bam >$BAMLIST
else
    BAMLIST=$1
fi

EVENTS=$2
OUT=$3

# Detect genome build
BAM1=$(head -1 $BAMLIST)
GENOME_BUILD=$($SDIR/GenomeData/getGenomeBuildBAM.sh $BAM1)
echo BUILD=$GENOME_BUILD

GENOME_SH=$SDIR/GenomeData/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit
fi

echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME

#
# Determine the type of the EVENT file
#

HEAD1=$(head -1 $FILE)
if [[ "$HEAD1" =~ "fileformat=VCF" ]]; then

    EVENT_TYPE="VCF"

elif [[ $EVENTS =~ \.vcf ]]; then

    EVENT_TYPE="VCF"

else

    EVENT_TYPE="MAF"

fi

if [[ "$EVENT_TYPE" == "VCF" ]]; then

    EVENT_INPUT="--vcf $EVENTS"

elif [[ "$EVENT_TYPE" == "MAF" ]]; then

    EVENT_INPUT="--maf $EVENTS"

else

    echo "Unknown EVENT_TYPE =["$EVENT_TYPE"]"
    exit 1

fi

INPUTS=$(
    for bam in $(cat $BAMLIST); do
        sample=$(samtools view -H $bam | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
        echo "--bam" ${sample}:$bam; done
    )

TMPFILE=_fill_$UUID
echo $TMPFILE

$SDIR/bin/GetBaseCountsMultiSample \
    --thread 24 \
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

if [ "$BAMDIR" ]; then
    rm $BAMLIST
fi
