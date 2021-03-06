#! /bin/bash
#$ -cwd
#$ -l h_rt=200:00:00,h_data=4G,highp
#$ -m abe
#$ -M ab08028
#$ -N parseBeagleHets
#$ -e /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -o /u/flashscratch/a/ab08028/captures/reports/angsd

####### calculate heterozygosity from posterior probabilities, exclude sites below a depth threshold on a per individual basis #######
# requires that you used -doCounts 1 -dumpCounts 2 when running ANGSD
source /u/local/Modules/default/init/modules.sh
module load python/2.7
# 20180528, trying with higher maxprobcutoff to see how that changes things
maxProbCutoff=0.95 # this is the cutoff for the max posterior probability. If the max of one of the three GTs posteriors isn't >=
# than this cutoff, then it won't be counted for that individual. Note that it doesn't have to be the het GT that is >0.5, just one of the three
# this is to avoid cases where each of the three GTs is very close in probability, indicating low overal confidence or possibly no data
minDepthCutoff=1 # sites that are < this threshold will not be counted toward an individuals heterozygosity

# directories: 
gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
scriptDir=$gitDir/scripts/scripts_20180521/
script=$scriptDir/analyses/aDNA-ModernComparison/Heterozygosity/parseBeaglePosteriors.CheckForMissingData.py # 20190523, this is a new script that discards sites that don't have read counts at a certain threshold per individual

SCRATCH=/u/flashscratch/a/ab08028
wd=$SCRATCH/captures/aDNA-ModernComparison
GLdir=$wd/angsd-GLs

############# all samples #######################
# angsdDate=20190511 # date you ran angsd that you're interested in 
# postDir=$GLdir/$angsdDate # location of your posterior probs
# outdir=$wd/heterozygosityFromPosteriors/$angsdDate
# mkdir -p $outdir
# #### CAUTION CAUTION CAUTION ####
# sampleIDs=$scriptDir/data_processing/variant_calling_aDNA/bamLists/SampleIDsInOrder.BeCarefulOfOrder.txt ## BE VERY CAREFUL OF THE ORDER HERE
# # make sure it's IDENTICAL ORDER to the bam list you used in ANGSD, otherwise you will use the wrong individuals
# # beagle files are completely order-dependent 
# # can use same sample ID file for mfur and elut (bamLists were in same order )
# #### CAUTION CAUTION CAUTION ####
# 
# ######### mfur:
# ref=mfur
# input=angsdOut.mappedTo${ref}.OrlandoSettings.beagle.gprobs.gz # input file 
# output=$outdir/${input%.beagle.gprobs.gz}.hetFromPost.ProbCutoff.${maxProbCutoff}.${angsdDate}.txt
# ## submit parsing of beagle file:
# python $script $postDir/$input $sampleIDs $output $maxProbCutoff
# 
# 
# ######### elut: 
# ref=elut
# input=angsdOut.mappedTo${ref}.OrlandoSettings.beagle.gprobs.gz # input file 
# output=$outdir/${input%.beagle.gprobs.gz}.hetFromPost.ProbCutoff.${maxProbCutoff}.${angsdDate}.txt
# ## submit parsing of beagle file:
# python $script $postDir/$input $sampleIDs $output $maxProbCutoff


############# high coverage +aDNA only (with and wihtout minind 5) #######################
sampleIDs=$scriptDir/data_processing/variant_calling_aDNA/bamLists/SampleIDsInOrder.HighCoverageAndADNAOnly.BeCarefulOfOrder.txt

for angsdDate in 20190524-highcov-AFprior 20190524-highcov-UNIFprior # fill in high cov dates
do
postDir=$GLdir/$angsdDate # location of your posterior probs
outdir=$wd/heterozygosityFromPosteriors/$angsdDate
mkdir -p $outdir

ref=mfur
input=angsdOut.mappedTo${ref}.beagle.gprobs.gz # input file 
counts=angsdOut.mappedTo${ref}.counts.gz
output=$outdir/${input%.beagle.gprobs.gz}.hetFromPost.ProbCutoff.${maxProbCutoff}.DepthCutoff.${minDepthCutoff}.${angsdDate}.txt

# new usage: 
# usage: python script.py inputFilepath countsFile sampleIDFile outputFile MaxProbCutoff PerIndividualDepthMinimum
python $script $postDir/$input $postDir/$counts $sampleIDs $output $maxProbCutoff $minDepthCutoff

ref=elut
input=angsdOut.mappedTo${ref}.beagle.gprobs.gz # input file 
counts=angsdOut.mappedTo${ref}.counts.gz
output=$outdir/${input%.beagle.gprobs.gz}.hetFromPost.ProbCutoff.${maxProbCutoff}.DepthCutoff.${minDepthCutoff}.${angsdDate}.txt
python $script $postDir/$input $postDir/$counts $sampleIDs $output $maxProbCutoff $minDepthCutoff
done


########## low coverage only ###########
sampleIDs=$scriptDir/data_processing/variant_calling_aDNA/bamLists/SampleIDsInOrder.LowCoverageOnly.BeCarefulOfOrder.txt

# 20190521-lowcov-neutOnly: low coverage neutral sites only (but doesn't have counts file so won't work -- have to use old heterozygosity scripts unfortunately )
# or wait for the redo to finish. did it finish?
for angsdDate in 20190524-lowcov-AFprior 20190524-lowcov-UNIFprior # fill in high cov dates
do
postDir=$GLdir/$angsdDate # location of your posterior probs
outdir=$wd/heterozygosityFromPosteriors/$angsdDate
mkdir -p $outdir

ref=mfur
input=angsdOut.mappedTo${ref}.beagle.gprobs.gz # input file 
counts=angsdOut.mappedTo${ref}.counts.gz
output=$outdir/${input%.beagle.gprobs.gz}.hetFromPost.ProbCutoff.${maxProbCutoff}.DepthCutoff.${minDepthCutoff}.${angsdDate}.txt

# new usage: 
# usage: python script.py inputFilepath countsFile sampleIDFile outputFile MaxProbCutoff PerIndividualDepthMinimum
python $script $postDir/$input $postDir/$counts $sampleIDs $output $maxProbCutoff $minDepthCutoff

ref=elut
input=angsdOut.mappedTo${ref}.beagle.gprobs.gz # input file 
counts=angsdOut.mappedTo${ref}.counts.gz
output=$outdir/${input%.beagle.gprobs.gz}.hetFromPost.ProbCutoff.${maxProbCutoff}.DepthCutoff.${minDepthCutoff}.${angsdDate}.txt
python $script $postDir/$input $postDir/$counts $sampleIDs $output $maxProbCutoff $minDepthCutoff
done
