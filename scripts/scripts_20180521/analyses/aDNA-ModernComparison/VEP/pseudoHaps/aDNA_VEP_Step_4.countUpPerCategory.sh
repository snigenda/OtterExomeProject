#!/bin/bash
#$ -l h_rt=20:00:00,h_data=3G
#$ -N countDerivedPerCategoryFromPseudos
#$ -cwd
#$ -m bea
#$ -o /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -e /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -M ab08028
source /u/local/Modules/default/init/modules.sh
module load python/2.7

# directories: 
wd=$SCRATCH/captures/aDNA-ModernComparison/

gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
scriptDir=$gitDir/scripts/scripts_20180521/
# script for high cov inds
script=$scriptDir/analyses/aDNA-ModernComparison/parseSuperfiles/parsePseudoHapSuperfile.ManyFilters.py
minIndsPerSite=1
perIndDepthMin=1
ref=mfur
basename=angsdOut.mappedTo${ref}


######################## high coverage ###################################
hcIDs=$scriptDir/data_processing/variant_calling_aDNA/bamLists/SampleIDsInOrder.HighCoverageAndADNAOnly.BeCarefulOfOrder.txt
dates="20190612-highcov-pseudoHaps"
categories="synonymous missense stopgained"
for date in $dates
do
outdir=$wd/VEP/pseudoHaps/$date/countsPerCategory/
mkdir -p $outdir
indir=$wd/angsd-pseudoHaps/$date/cdsPerCategoryFromVEP

for category in $categories
do
output=countsPerCategory.${category}.minDepth.${perIndDepthMin}.minInds.${minIndsPerSite}.txt
input=${basename}.superfile.0based.fromVEP.pick.${category}.bed.gz
python $script $indir/$input $hcIDs $outdir/$output $perIndDepthMin $minIndsPerSite

done
done

######################## low coverage ###################################
lcIDs=$scriptDir/data_processing/variant_calling_aDNA/bamLists/SampleIDsInOrder.LowCoverageOnly.BeCarefulOfOrder.txt
dates="20190612-lowcov-pseudoHaps"
categories="synonymous missense stopgained"
for date in $dates
do
outdir=$wd/VEP/pseudoHaps/$date/countsPerCategory/
mkdir -p $outdir
indir=$wd/angsd-pseudoHaps/$date/cdsPerCategoryFromVEP

for category in $categories
do
output=countsPerCategory.${category}.minDepth.${perIndDepthMin}.minInds.${minIndsPerSite}.txt
input=${basename}.superfile.0based.fromVEP.pick.${category}.bed.gz
python $script $indir/$input $lcIDs $outdir/$output $perIndDepthMin $minIndsPerSite

done
done