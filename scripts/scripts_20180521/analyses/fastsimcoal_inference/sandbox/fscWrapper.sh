### fsc wrapper

# need to input sample size in haploids into file (Pooneh can do manually) -- is equal to folded sfs dim -1  *2

# dir structure
# fsc_inference
# 		|-CA
#			|-modelName
#				|- .est, .tpl files
#		|-AK
# 		|-AL
#		|-COM
#		|-KUR
############# program ############
fsc=/u/home/a/ab08028/bin/fsc26
# note that fsc26 has a lot of differences from fsc251!

############# parameters #############
models='1D.2Epoch 1D.1Bottleneck'
pops="CA AK AL COM KUR"
genotypeDate=20180806 # date genotypes were called
sfsDate=20181019 # date sfses were made
header=${model}
cores=3 #num cores
############ file structure ############
gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
scriptDir=$gitDir/scripts/scripts_20180521/analyses
wd=/u/flashscratch/a/ab08028/captures/analyses/ # overall working dir
infDir=$wd/fastsimcoal_inference # specify where inference is happening
genericDir=$scriptDir/genericModelFiles # location of generic FSC models
sampleSizes=$wd/SFS/$genotypeDate/neutralSFS/sampleSizesUsedInSFSes.txt # location of SS file that is in format population diploidSS haploidSS <-- you'll want haploid SS
############## set up your for-loops ############## 
for pop in $pops
do
############ get sample size for the population ############
ss=`grep $pop $sampleSizes | awk '{print $3}'` # get the haploid sample size 

for model in $models
do

########### copy generic files into directory and update #########

outdir=$infDir/$pop/$model/$rundate/run_${SGE_TASK_ID}/ # specify where output will go
cp $genericDir/$model.tpl $genericDir/$model.est $outdir # copy .est and .tpl files to outdir
sed 's/$ss/SAMPLE_SIZE/g' $outdir/$model.tpl # sub in the sample size
mkdir -p $outdir # make your out dir
sfsDir=$wd/SFS/$genotypeDate/neutralSFS/ # specify where your SFS files are


########### get sfs into inference directory and rename to match .est and .tpl files #########
cp $sfsDir/${pop}_sfs_${sfsDate}_MAFpop0.obs $outdir/${header}_MAFpop0.obs # copy your sfs into the directory where you'll be doing the fsc inference 
cd $outdir
$fsc -t ${header}.tpl -n100000 -m -e ${header}.est -M -L 40 �c$cores -q

done
done


######## make a readme  #########
echo "genotype date: " $genotypeDate >> $infDir/$pop/$model/$rundate
echo "sfs date: " $sfsDate > $infDir/$pop/$model/$rundate
echo "population: " $pop > $infDir/$pop/$model/$rundate
echo "model: " $model > $infDir/$pop/$model/$rundate

#from fsc26 manual:
# This command line tells fsc26 that the model is defined in the file 1PopBot20Mb.tpl (-t), that the search range of the parameters to be estimated are in the file 1PopBot20Mb.est (-e), that (-n) 100,000 simulations need to be done to estimate the expected derived (-d) SFS, that (-L) 40 ECM cycles, respectively, will be performed for estimating the parameters (-M), and that a minimum console output (quiet mode -q) is required.
#S ince ver 2.5.2.8, it is possible to write the command line in a file called "fsc_run.txt". If this file is present in the current working directory, and if fsc26 is launched without any argument, the command line found in the file "fsc_run.txt" will be executed.
##� -M option is only need to specify that parameter estimation my Maximum likelihood needs to be performed. It does not need any additional parameter.
##� -l option is now optional. It used to specify a minimum number of cycles to be performed. Now we do a fixed number of cycles specified with option -L. However, it can be specified in connection with the use of the reference keyword in est files, such as to specify the number of ECM cycles for which the likelihood of the model will be evaluated on both monomorphic and polymorphic sites. In absence of this �l option, the likelihood is estimated on both monomorphic and polymorphic sites unless the -0 option is used.
##� -N option has been suppressed. It used to specify a maximum number of coalescent simulations to perform to estimate the expected SFS. Now we use a fixed number of simulations, simply specified by option -n.

# note if you are getting segmentation faults
# first check format of sfs -- does it say "1 observation" at the top? is it tab delimited?
# then check your .est and .tpl files -- is the sample size right? do you specify the correct number of historical events? 