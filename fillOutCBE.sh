#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"
module load samtools

function usage {
    echo
    echo "  usage: fillOutCBE.sh [-v|-m] [-Q MAPQ] [-B BASEQ] (BAMDIR|BAMLIST) EVENTS OUTPUT_FILE"
    echo
    echo "  Fill out variant positions in EVENTS with read-depth counts from"
    echo "  one or more BAM files.  Output is always a multi-sample VCF with"
    echo "  FORMAT fields: DP, RD, AD, VF, DPP, DPN, RDP, RDN, ADP, ADN."
    echo
    echo "  Arguments:"
    echo "    BAMDIR    Directory of BAM files; all *.bam files are used"
    echo "    BAMLIST   Plain-text file listing BAM paths, one per line"
    echo "    EVENTS    Input variant file (VCF or MAF)"
    echo "    OUTPUT    Output VCF file path"
    echo
    echo "  Options:"
    echo "    -v        Force VCF input (default: auto-detect from extension)"
    echo "    -m        Force MAF input (default: auto-detect from extension)"
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

EVENT_TYPE="UNK"
MAPQ=20
BASEQ=0

while getopts "vmQ:B:" opt; do
    case $opt in
        v)
        EVENT_TYPE="VCF";
        ;;
        m)
        EVENT_TYPE="MAF"
        ;;
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
    exit 1
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

#echo $INPUTS | tee inputs_fillout

TMPFILE=_fill_$UUID
echo $TMPFILE

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
