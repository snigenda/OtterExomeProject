#! /bin/bash
#$ -cwd
#$ -l h_rt=24:00:00,h_data=8G
#$ -N treemix_bootstrap_bite
#$ -o /u/flashscratch/a/ab08028/captures/reports/treemix
#$ -e /u/flashscratch/a/ab08028/captures/reports/treemix
#$ -m abe
#$ -M ab08028
#$ -t 1-10


### array over migration rates in parallel
######### note a big change I make to BITE: I actually add the -bootstrap flag to treemix during the boot phase
# so that it resamples the data with replacement over the k size blocks! It seems like BITE was just rerunning treemix with different seeds
######## submit it:
source /u/local/Modules/default/init/modules.sh
module load treemix
indir=/u/flashscratch/a/ab08028/captures/vcf_filtering/20181119_filtered/treemixFormat

# first ran with AL-separated
fileFlag=snp7

infile=snp_7_maxNoCallFrac_0.2_passingBespoke_passingAllFilters_postMerge_raw_variants.noBAJA.exclRelatives.frq.strat.treemixFormat.gz		## treemix input file
# snp_7_maxNoCallFrac_0.2_passingBespoke_passingAllFilters_postMerge_raw_variants.noBAJA.exclRelatives.frq.strat.treemixFormat.gz
# snp_9a_forPCAetc_maxHetFilter_0.75_rmRelatives_rmAdmixed_passingBespoke_maxNoCallFrac_0.2_passingBespoke_passingAllFilters_postMerge_raw_variants.noBAJA.frq.strat.treemixFormat.gz


ncore=1 		## max number of cores to use

blockk=100 		## block size

outgroup=NoOutgroup 	## name of the selected outgroup population (if you want to do an unrooted ML tree put here 'NoOutgroup' (without quotes))

nboot=100 ### number of bootstrap replicates of the TREE

pathP=/u/home/a/ab08028/klohmueldata/annabel_data/bin/phylip-3.697/exe/consense
# path to Phylip consense program. Example: /biosoftware/phylip/phylip-3.696/exe/consense

outdir=/u/flashscratch/a/ab08028/captures/analyses/TREEMIX/20181119/BITE/sep-AL
mkdir -p $outdir
outname=mig.${numk}.k.${blockk}.out.${outgroup}.out		## name for output file

scriptdir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/scripts/scripts_20180521/analyses/TREEMIX/BITE-treemix
script=Treemix_bootstrap.AB.ResamplesData.sh

mig=$SGE_TASK_ID

outdir=/u/flashscratch/a/ab08028/captures/analyses/TREEMIX/20181119/BITE/$fileFlag/root.${outgroup}/mig${mig}/
mkdir -p $outdir
outname=treemix.k.$blockk.root.$outgroup.resampednBoots.${nboot}

$scriptdir/$script $indir/$infile $mig $ncore $blockk $outgroup $nboot $pathP $outdir $outname


sleep 10m
