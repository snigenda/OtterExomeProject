#!/bin/bash
#$ -l h_rt=24:00:00,h_data=3G
#$ -N VEP2BED
#$ -cwd
#$ -m bea
#$ -o /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -e /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -M ab08028

# Filter VEP output to separate missense, synonymous and LOF mutations that are in CANONICAL transcripts
# Then want to turn into coordinates 
source /u/local/Modules/default/init/modules.sh
module load bedtools
# directories: 
gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
scriptDir=$gitDir/scripts/scripts_20180521/

SCRATCH=/u/flashscratch/a/ab08028
wd=$SCRATCH/captures/aDNA-ModernComparison

ref=mfur # only work with MFUR when going into VEP!
#dates="20190524-highcov-AFprior 20190524-lowcov-AFprior"
dates="20190612-highcov-pseudoHaps 20190612-lowcov-pseudoHaps"
categories="synonymous missense stopgained"

#  20190524-highcov-UNIFprior 20190524-lowcov-UNIFprior" # set of angsdDates you want to process 
basename=angsdOut.mappedTo${ref}
for angsdDate in $dates
do
indir=$wd/VEP/pseudoHaps/$angsdDate 
hapdir=$wd/angsd-pseudoHaps/$angsdDate 
mkdir -p $hapdir/cdsPerCategoryFromVEP
### convert vep output back to bed coords
# note vep is 1based, bed is 0based
for category in $categories
do
# doesn't matter whether this came from GPs or GLs, it's all about coordinates
input=$indir/${basename}.pseudoHaps.superfile.cdsOnly.1based.VEPInput.VEP.output.pick.${category}.tbl
grep -v "#" $input | awk '{OFS="\t";split($2,pos,":");print pos[1],pos[2]-1,pos[2],$1}' > ${input%.tbl}.0based.coordsOnly.bed

#### then intersect with my superfiles #########
# redo this with the -header flag so I get headers
bedtools intersect -a $wd/angsd-pseudoHaps/$angsdDate/${basename}.pseudoHaps.superfile.cdsOnly.0based.bed.gz -b ${input%.tbl}.0based.coordsOnly.bed -wa -header > $hapdir/cdsPerCategoryFromVEP/${basename}.superfile.0based.fromVEP.pick.${category}.bed
done
done




