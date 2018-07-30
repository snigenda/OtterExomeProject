############ Run faststructure for multiple values of K
# how many?
# kuril, commander, aleutian, alaska, california = 5
# kuril, bering, medny, aleutian, alaska, california = 6
# kuril, bering, medny, attu, adak, amchitka, alaska, california = 8
# kuril+commander, aleutian, alaska, california = 4
# kuril + commander, aleut+alaska, cali = 3
# so for at least 3,4,5,6,7,8
################# installing fastStructure: #############

# git clone https://github.com/rajanil/fastStructure
#cd fastStructure/vars
#python setup.py build_ext --inplace
#cd ..
#python setup.py build_ext --inplace
#test:
#python structure.py # works!
# !!!! you need to add the following two lines to the distruct.py script so that it works without X11 forwarding (https://github.com/rajanil/fastStructure/issues/36)
# import matplotlib as mpl
# mpl.use('svg')
# !!!! these must be added PRIOR to setting: import matplotlib.pyplot as plot

################# running fastStructure: #############

# program dir: (downloaded 20180726)
fastDir=/u/home/a/ab08028/klohmueldata/annabel_data/bin/fastStructure
#kvals="1 2 3 4 5 6 7 8 9 10"
kvals="1 2 3" # set this to whatever numbers you want 
pops= # file list of population assignments (single column) in same order as your sample input *careful here* get order from .fam or .nosex files
# and then manually make list of population assignments in order (is there a better way?)
indir=/u/flashscratch/a/ab08028/sandbox/vcf_filtering # eventually going to be filtered SNP vcf (no monomorphic sites)
infilePREFIX=XX.test # the prefix of the .bed file
outdir=/u/flashscratch/a/ab08028/sandbox/faststructure # eventually going to be FASTSTRUCTURE dir
plotdir=$outdir/plots
mkdir -p $outdir
mkdir -p $plotdir
# want to iterate over several values of K: 
for k in $kvals
do
echo "carrying out faststructure analysis with K = $k "
python $fastDir/structure.py -K $k --input=$indir/$infilePREFIX --output=$outdir/${infilePREFIX}.faststructure_output

# "This generates a genotypes_output.3.log file that tracks how the algorithm proceeds, 
# and files genotypes_output.3.meanQ and genotypes_output.3.meanP 
# containing the posterior mean of admixture proportions and allele frequencies, respectively."
# note that the output prefix has the K value appended, which is handy:
# e.g. XX.test.faststructure_output.2.log is the result of the above line of code with K =2 
# to choose the correct K:

# want to plot each one:
python $fastDir/distruct.py \
-K $k \
--input=$outdir/$infilePREFIX.faststructure_output \
--output=$plotdir/${infilePREFIX}.faststructure_plot.${k}.svg \
--title="fastStructure Results, K=$k" \
--popfile=$pops
# this fails due to lack of X11 forwarding. How to deal with?
done
# choose amongst the K values:
python $fastDir/chooseK.py --input=$outdir/$infilePREFIX.faststructure_output
