
##### adding admixture to PC angsd #####
# tutorial http://www.popgen.dk/software/index.php/PCAngsdTutorial


## sandbox
module load anaconda # load anaconda
source activate angsd-conda-env # activate conda env
pcangsddir=/u/home/a/ab08028/klohmueldata/annabel_data/bin/pcangsd
wd=$SCRATCH/captures/aDNA-ModernComparison
todaysdate=`date +%Y%m%d`

################ high coverage ################
#dates="20190701-highcov-AFprior-MajorMinor4 20190701-lowcov-AFprior-MajorMinor4" # for now
dates="20191205-highcov-AFprior-MajorMinor4-IncludesMoreInds-notAllIndelRealignedYet-noA7" # with more individuals 
refs="elut mfur" # for now
minMafs="0.05 0.12 0.2"

state=1e-06.snpsOnly.TransvOnly
alpha=50 # soft uppper limit on alpha, a small penalty on admixture proportions (? not entirely sure what this does -- test it)

for date in $dates
do
echo $date
GLdir=/u/flashscratch/a/ab08028/captures/aDNA-ModernComparison/angsd-GLs/$date
outdir=/u/flashscratch/a/ab08028/captures/aDNA-ModernComparison/admixture/$date
mkdir -p $outdir

for ref in $refs
do
echo $ref
input=angsdOut.mappedTo${ref}.${state}.beagle.gz
for minMaf in $minMafs
do
echo $minMaf
python $pcangsddir/pcangsd.py \
-beagle $GLdir/$input \
-o $outdir/pcAngsd.${ref}.${state}.minMaf.${minMaf} \
-minMaf $minMaf -threads 10  \
-admix -admix_auto $alpha 1> $outdir/pcAngsd.${ref}.${state}.minMaf.${minMaf}.autoAlpha.${todaysdate}.log
# 1> saves the output so you can see that things converge, etc. useful! 
done
done
done


source deactivate