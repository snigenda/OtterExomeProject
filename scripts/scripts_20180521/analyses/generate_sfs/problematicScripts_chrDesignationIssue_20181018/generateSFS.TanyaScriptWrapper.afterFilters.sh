#! /bin/bash
#$ -cwd
#$ -l h_rt=24:00:00,h_data=8G,highp
#$ -N generate_sfs_allPops_afterFiltering
#$ -o /u/flashscratch/a/ab08028/captures/reports/SFS
#$ -e /u/flashscratch/a/ab08028/captures/reports/SFS
#$ -m abe
#$ -M ab08028

### This is for the neutral SFS, but can modify choice of bed file to make coding SFS

source /u/local/Modules/default/init/modules.sh
module load python/2.7

rundate=20180806
todaysdate=`date +%Y%m%d` # want to add date to sfs output
### wrapper for Tanya's script
SCRATCH=/u/flashscratch/a/ab08028

# location of per-population input VCFs (with NO no-call genotypes)
vcfdir=$SCRATCH/captures/vcf_filtering/${rundate}_filtered

# this is the old neutral bed file from old filtering scheme results that used 0.2 max no call frac across all pops which is too strict (these regions are good regions, there just might be more out there with new filtering; this is a conservative set)
#neutralBed=${vcfdir}/oldFilteringSchemeResults/bedCoords/all_7_passingBespoke.min10kb.fromExon.noCpGIsland.noRepeat.noFish.0based.sorted.merged.useThis.bed
# 20181009 this is the new neutral sites bed file -->
# it has been filtered for:
# is 10kb from exons
# is not in CpG island
# is not in repeat region
# does not blast to zebra fish
# no other GC content filter
neutralBed=${vcfdir}/bedCoords/all_8_rmRelatives_keepAdmixed_passingBespoke_maxNoCallFrac_0.9_rmBadIndividuals_passingFilters.min10kb.fromExon.noCpGIsland.noRepeat.noFish.0based.sorted.merged.useThis.bed
# output SFS location
SFSdir=$SCRATCH/captures/analyses/SFS/${rundate}
mkdir -p $SFSdir/neutralSFS
mkdir -p $SFSdir/neutralSFS/admixed

# location of tanya's scripts
# this is latest 20180822 where it runs faster (but need to give enough memory)
# and doesn't require pre-filtered SFS 
tanyaDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/scripts/scripts_20180521/scripts_from_others/tanya_scripts/

# generate folded SFS:
populations="CA AK AL COM KUR"

for pop in $populations
do
echo $pop

# if vcf file is not prefiltered to just contain neutral (or other) regions
inVCF=${pop}_'all_9_rmAllHet_rmRelativesAdmixed_passingAllFilters_allCalled.vcf.gz'

python $tanyaDir/popgen_tools/popgen_tools.py \
--vcf_file $vcfdir/populationVCFs/$inVCF \
--sfs_out $SFSdir/neutralSFS/${inVCF%.vcf.gz}.filtered.sfs.${todaysdate}.out \
--no_pi \
--target_bed $neutralBed

done

# admixed SFSes:
for pop in KUR AK
do
echo "admixed " $pop
inVCF='admixIndOnly_'${pop}'_all_9_rmAllHet_passingAllFilters_allCalled.vcf.gz'
python $tanyaDir/popgen_tools/popgen_tools.py \
--vcf_file $vcfdir/populationVCFs/admixedVCFs/$inVCF \
--sfs_out $SFSdir/neutralSFS/admixed/${inVCF%.vcf.gz}.filtered.sfs.${todaysdate}.out \
--no_pi \
--target_bed $neutralBed
done

# is this impacted by lack of chr designations??????? 