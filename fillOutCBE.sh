#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
SAMTOOLS=/opt/common/CentOS_6-dev/bin/current/samtools

function usage {
    echo
    echo "  usage: fillOutCBE.sh [-v|-m] (BAMDIR|BAMLIST) EVENTS OUTPUT_FILE"
    echo
    echo BAMDIR = Directory with BAM files. Will process all
    echo BAMLIST = File with paths to BAM files, one per line
    echo
}

if [ $# -lt 3 ]; then
    usage
    exit
fi

EVENT_TYPE="UNK"
while getopts "vm" opt; do
    case $opt in
        v)
        EVENT_TYPE="VCF";
        ;;
        m)
        EVENT_TYPE="MAF"
        ;;
        \?)
        usage
        exit
        ;;
    esac
done
shift $((OPTIND-1))

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

echo EVENTS=$EVENTS

if [[ "$EVENT_TYPE" == "UNK" ]]; then
    if [[ $EVENTS =~ \.vcf ]]; then
        EVENT_TYPE="VCF"
    else
        EVENT_TYPE="MAF"
    fi
fi

if [[ "$EVENT_TYPE" == "VCF" ]]; then

    EVENT_INPUT="--vcf $EVENTS"

elif [[ "$EVENT_TYPE" == "MAF" ]]; then

    EVENT_INPUT="--maf $EVENTS"

else

    echo "Unknown EVENT_TYPE =["$EVENT_TYPE"]"
    exit 1

fi

NUM_SAMPLENAMES=$(
    for bam in $(cat $BAMLIST); do
        sample=$($SAMTOOLS view -H $bam | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
        echo ${sample};
    done | sort | uniq | wc -l
)

NUM_BAMS=$(cat $BAMLIST | wc -l)

if [ "$NUM_SAMPLENAMES" == "$NUM_BAMS" ]; then

    INPUTS=$(
        for bam in $(cat $BAMLIST); do
            sample=$($SAMTOOLS view -H $bam | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
            echo "--bam" ${sample}:$bam; done
        )

else

    # For people who do not set the SM: TAG uniquly for all BAMs use the
    # File name for the samplename

    INPUTS=$(
        for bam in $(cat $BAMLIST); do
            echo "--bam" $(basename $bam | sed 's/.bam//'):$bam; done
        )

fi

TMPFILE=_fill_$UUID
echo $TMPFILE

$SDIR/bin/GetBaseCountsMultiSample \
    --thread 8 \
    --suppress_warning 3 \
    --fragment_count 1 \
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
