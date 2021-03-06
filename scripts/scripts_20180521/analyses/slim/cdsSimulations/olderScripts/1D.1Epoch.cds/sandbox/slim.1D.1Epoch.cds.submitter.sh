gitdir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
models='1D.2Epoch.1.5Mb.cds'
#populations='AK AL CA COM KUR'
populations="AK"
# loop through models, populations and 25 replicates

for model in $models
do
scriptdir=$gitdir/scripts/scripts_20180521/analyses/slim/cdsSimulations/$model
todaysdate=`date +%Y%m%d` # don't want to use todays date because then different time starting arrays could get messed up
# send error files to wd
wd=$SCRATCH/captures/analyses/slim/cdsSimulations/$model/$todaysdate/
mkdir -p $wd
# want slim reports go to into the output directory 
# starting with 1s
#for pop in AK AL CA COM KUR
for pop in $populations
do
for i in {1..25}
do
# qsub -N name -o outdir -e errordir $script $pop $model $rep $rundate
qsub -N slimRep$i -o $wd -e $wd $scriptdir/slim.${model}.array.sh $pop $model $i $todaysdate
done
done
done
