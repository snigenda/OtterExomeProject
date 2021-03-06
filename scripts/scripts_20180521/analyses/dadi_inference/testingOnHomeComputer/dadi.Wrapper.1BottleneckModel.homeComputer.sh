#### wrapper:
# if using on Hoffman, have to use virtual environment:
# you can set up the virtual env by doing:
# module load python/2.7.13_shared
# virtualenv $HOME/env_python2.7.13 # once
# then activate it every future time with  source $HOME/env_python2.7.13/bin/activate
# make sure you pip install numpy scipy matplotlib 
# and then you can deactivate
#### wrapper:

gitdir=/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/
scriptdir=$gitdir/scripts/scripts_20180521/analyses/dadi_inference

script=1D.1Bottleneck.dadi.py
model=${script%.dadi.py}
mu=8.64411385098638e-09
genotypeDate=20180806
sfsDate=20181019
sfsdir=/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/results/datafiles/SFS/${genotypeDate}/neutralSFS/
sfssuffix=unfolded.sfs.dadi.format.${sfsDate}.txttotalNeut=/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/results/analysisResults/TotalCallableNeutralSites/${genotypeDate}/summary.neutralCallableSites.perPop.txt # file with total neutral sites counts for each population 
### want to make a slightly fancier outdir that is the model / date or something like that eventually. 
for pop in CA AK AL COM KUR
do
echo $pop
outdir=/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/results/analysisResults/dadi_inference/$genotypeDate/$pop/$model/
mkdir -p $outdir

L=`grep $pop $totalNeut | awk '{print $2}'` # get the total called neutral sites from the totalNeut table
for i in {1..50}
do
echo $pop $i
python $scriptdir/$script --runNum $i --pop $pop --mu $mu --L $L --sfs ${sfsdir}/${pop}.${sfssuffix} --outdir $outdir
done

# set up header
grep rundate -m1 $outdir/dadi.inference.bottleneck.runNum.1.*.output > $outdir/all.output.concatted.txt
for i in {1..50}
do
grep rundate -A1 $outdir/dadi.inference.bottleneck.runNum.${i}.*.output | tail -n1 >> $outdir/all.output.concatted.txt
done
done