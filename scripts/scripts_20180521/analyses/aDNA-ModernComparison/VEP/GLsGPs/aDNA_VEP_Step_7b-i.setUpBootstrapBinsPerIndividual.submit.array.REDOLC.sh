#! /bin/bash
#$ -cwd
#$ -l h_rt=100:00:00,h_data=30G,highp
#$ -m abe
#$ -M ab08028
#$ -N redoLCbootstrapVEPResults
#$ -e /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -o /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -V
#$ -t 1-9
source /u/local/Modules/default/init/modules.sh
module load R/3.5.1  

### each site should only appear once in the super file but want to make sure 
# zcat angsdOut.mappedTomfur.superfile.GPs.mafs.counts.0based.allCDSSites.AnnotatedWithVEP.bed.gz | grep -v "#" -c   # total sites
# 25971997
# zcat angsdOut.mappedTomfur.superfile.GPs.mafs.counts.0based.allCDSSites.AnnotatedWithVEP.bed.gz | grep -v "#" | awk '{print $4}' | sort | uniq | wc -l
# 25971997 with uniq
# so since --pick was used, each site only appears once
 
gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
scriptDir=$gitDir/scripts/scripts_20180521/analyses/aDNA-ModernComparison/VEP/GLsGPs/
script=aDNA_VEP_Step_7b-i.setUpBootstrapBinsPerIndividual.R

# parameters:
binsize=100000 # 100kb
#numBoots=100 # eventually do more! 
minDepth=2 # I calculated totals with 1, 2 and 4. 2 lowers values of homAlt compared to 1. I think 2 is fitting since 1 read might seem homAlt but not be. 
minGP=0.95
minInd=1
#dates='20190701-lowcov-AFprior-MajorMinor4 20190701-highcov-AFprior-MajorMinor4'
dates="20190701-lowcov-AFprior-MajorMinor4"
SCRATCH=/u/flashscratch/a/ab08028/
avgSitesFile=$SCRATCH/captures/aDNA-ModernComparison/VEP/sumGPsGLsPerVEPCategory/AVERAGECALLEDSITES.allInds.HighCov.LowCov.minDepth.${minDepth}.minInd.${minInd}.minGP.${minGP}.txt
# contains both dates
ref="mfur"
basename=angsdOut.mappedTo${ref}
type="GPs" # for now 
indNum=$(($SGE_TASK_ID-1)) # ind #s are start at 0 but can't do array starting at 0, so need to subtract 1 so 1-9 turns into 0-8.
outPREFIX=${basename}.superfile.${type}

# loop through dates:
for angsdDate in $dates
do
echo $angsdDate
indir=$SCRATCH/captures/aDNA-ModernComparison/angsd-GLs/$angsdDate/cdsPerCategoryFromVEP/
#infile=$indir/testingScript.CDS.bed.gz
infile=$indir/${basename}.superfile.${type}.mafs.counts.0based.allCDSSites.AnnotatedWithVEP.bed.gz # need to fix header issue
chrSizes=$scriptDir/Mustela_putorius_furo.MusPutFur1.0.dna.toplevel.224.ChrLengths.txt # need the chr sizes to be uploaded somewhere
outdir=$SCRATCH/captures/aDNA-ModernComparison/compareMisSynDists_withBootstraps/$angsdDate
mkdir -p $outdir
# file with avg sites to draw (depends on minDepth,minGP, minInd) and is a result of the script: /Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/scripts/scripts_20180521/analyses/aDNA-ModernComparison/VEP/GLsGPs/getAverageCalledCDSSItesAcrossAllInds.R
# get count for this date:
#avgSitesToDraw=`grep $angsdDate $avgSitesFile | awk '{print $3}'` ## need to calculate! ##  can be found in /u/flashscratch/a/ab08028/captures/aDNA-ModernComparison/VEP/sumGPsGLsPerVEPCategory -- calculate average from across individuals (ask Kirk too)
#echo "avg sites to draw: " $avgSitesToDraw

# option_list = list(
#   make_option(c("--infile"), type="character", default=NULL, 
#               help="path to your input file (superfile of cds sites with annotations from vep and GPs from angsd as well as depths", metavar="file"),
#   make_option(c("--chrSizes"), type="character", default=NULL, 
#               help="path to file with mustela chromosome sizes", metavar="character"),
#   make_option(c("--outdir"), type="character", default=NULL, 
#               help="path to outdir", metavar="dir"),
#   make_option(c("--outPREFIX"), type="character", default=NULL, 
#               help="outfilePrefix", metavar="prefix"),
#   make_option(c("--minDepth"), type="numeric", default=NULL, 
#               help="min depth per individual for a site to be 'callalble'", metavar="numeric"),
#   make_option(c("--minGP"), type="numeric", default=NULL, 
#               help="minimum value of the max. GP per site, per individual. Use 0.95.", metavar="numeric"),
#   make_option(c("--binsize"), type="numeric", default=NULL, 
#               help="Size of bin to chunk the genome into (should be > than a recombination block)", metavar="numeric"),
#   make_option(c("--indNum"), type="numeric", default=NULL, 
#               help="Individual number assigned by ANGSD, starts at 0 (for my study it's 0-8))", metavar="numeric")
# ); 

echo "Rscript $scriptDir/$script --infile $infile --chrSizes $chrSizes --outdir $outdir --outPREFIX $outPREFIX --minDepth $minDepth --minGP $minGP --binsize $binsize --indNum $indNum"

Rscript $scriptDir/$script --infile $infile --chrSizes $chrSizes --outdir $outdir --outPREFIX $outPREFIX --minDepth $minDepth --minGP $minGP --binsize $binsize --indNum $indNum
done

sleep 10m