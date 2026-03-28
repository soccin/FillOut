#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
module load samtools

function usage {
    echo
    echo "  usage: fillOutMaf2Maf.sh [-Q MAPQ] [-B BASEQ] (BAMDIR|BAMLIST) EVENTS OUTPUT.maf"
    echo
    echo "  Fill out variant positions in EVENTS with read-depth counts from"
    echo "  one or more BAM files.  Output is always a multi-sample MAF"
    echo
    echo "  Arguments:"
    echo "    BAMDIR    Directory of BAM files; all *.bam files are used"
    echo "    BAMLIST   Plain-text file listing BAM paths, one per line"
    echo "    EVENTS    Input variant file (VCF or MAF)"
    echo "    OUTPUT    Output MAF path"
    echo
    echo "  Options:"
    echo "    -Q MAPQ   Minimum mapping quality to count a read (default: 20)"
    echo "    -B BASEQ  Minimum base quality to count a read  (default: 0)"
    echo
    echo "  Sample names are taken from BAM @RG SM: tags.  If SM tags are"
    echo "  not unique across all BAMs, the BAM filename (minus .bam) is"
    echo "  used as the sample name instead."
    echo
    echo "  The genome build is auto-detected from the first BAM header."
    echo
}

if [ $# -lt 3 ]; then
    usage
    exit
fi

EVENT_TYPE="MAF"
MAPQ=20
BASEQ=0

while getopts "Q:B:" opt; do
    case $opt in
        Q)
        MAPQ=$OPTARG
        ;;
        B)
        BASEQ=$OPTARG
        ;;
        \?)
        usage
        exit
        ;;
    esac
done
shift $((OPTIND-1))


echo MAPQ=$MAPQ
echo BASEQ=$BASEQ

ARG1=$1
UUID=$(uuidgen)
BAMDIR=""

TMPMIN=_minMaf_${UUID}.maf
TMPFILL=_fill_${UUID}.maf
TMPANNO=_fill_${UUID}.annote.maf

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

if [ ! -f $EVENTS ]; then
    echo "ERROR: input MAF not found: $EVENTS"
    exit 1
fi

if [ -e $OUT ]; then
    echo "ERROR: output file already exists: $OUT"
    exit 1
fi

# Detect genome build
BAM1=$(head -1 $BAMLIST)
GENOME_BUILD=$($SDIR/GenomeData/getGenomeBuildBAM.sh $BAM1)
echo BUILD=$GENOME_BUILD

GENOME_SH=$SDIR/GenomeData/genomeInfo_${GENOME_BUILD}.sh
if [ ! -e "$GENOME_SH" ]; then
    echo "Unknown genome build ["${GENOME_BUILD}"]"
    exit 1
fi

echo "Loading genome [${GENOME_BUILD}]" $GENOME_SH
source $GENOME_SH
echo GENOME=$GENOME

#
# Determine the type of the EVENT file
#

echo EVENTS=$EVENTS

# Pre-step: trim input MAF to minimal columns for GBCMS
echo "Pre-processing: minimizing input MAF"
Rscript $SDIR/R/makeMinimalMaf.R $EVENTS $TMPMIN

EVENT_INPUT="--maf $TMPMIN"

NUM_SAMPLENAMES=$(
    for bam in $(cat $BAMLIST); do
        sample=$(samtools view -H $bam | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
        echo ${sample};
    done | sort | uniq | wc -l
)

NUM_BAMS=$(cat $BAMLIST | wc -l)

#echo NUM_BAMS=$NUM_BAMS

if [ "$NUM_SAMPLENAMES" == "$NUM_BAMS" ]; then

    INPUTS=$(
        for bam in $(cat $BAMLIST); do
            sample=$(samtools view -H $bam | fgrep "@RG" | head -1 | perl -ne 'm/SM:(\S+)/;print $1');
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

GBMC_VERSION=$($SDIR/bin/GetBaseCountsMultiSample | fgrep GetBaseCounts | awk '{print $2}')

echo "GetBaseCountsMultiSample version ${GBMC_VERSION}"

$SDIR/bin/GetBaseCountsMultiSample \
    --thread 24 \
    --maq $MAPQ \
    --baq $BASEQ \
    --suppress_warning 3 \
    --fragment_count 1 \
    --filter_improper_pair 0 --fasta $GENOME \
    $EVENT_INPUT \
    --omaf \
    --output $TMPFILL \
    $INPUTS

# Post-step: annotate filled MAF with columns from the minimal MAF
echo "Post-processing: annotating filled MAF"
Rscript $SDIR/R/annoteMaf.R $TMPFILL $TMPMIN
mv $TMPANNO $OUT

rm -f $TMPMIN $TMPFILL $TMPANNO

Rscript $SDIR/R/fillOutReport.R $OUT

if [ "$BAMDIR" ]; then
    rm $BAMLIST
fi
