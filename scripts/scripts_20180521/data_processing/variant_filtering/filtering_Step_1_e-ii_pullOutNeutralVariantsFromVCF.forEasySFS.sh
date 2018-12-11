#! /bin/bash
#$ -cwd
#$ -l h_rt=50:00:00,h_data=16G,highp,arch=intel*
#$ -N vcf1e_pullOutNeutral
#$ -o /u/flashscratch/a/ab08028/captures/reports/GATK
#$ -e /u/flashscratch/a/ab08028/captures/reports/GATK
#$ -m abe
#$ -M ab08028module load java
module load bedtools
GATK=/u/home/a/ab08028/klohmueldata/annabel_data/bin/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar

rundate=20181119
noCallFrac=1.0 # no filter used
#### file locations
SCRATCH=/u/flashscratch/a/ab08028
wd=$SCRATCH/captures/vcf_filtering
REFERENCE=/u/home/a/ab08028/klohmueldata/annabel_data/ferret_genome/Mustela_putorius_furo.MusPutFur1.0.dna.toplevel.fasta

vcfdir=$wd/${rundate}_filtered # date you called genotypes
outdir=$vcfdir/populationVCFs/neutralVCFs
mkdir -p $outdir
 # note that these still have per-population all-het sites present ; but I modified the easy sfs script to remove them ()
# 20181018 bed file of neutral sites that have been called (min 10kb from genes, not in CpG island, doesn't blast to zebra fish); max no call frac is 0.9 (liberal)
neutralBed=${vcfdir}/bedCoords/all_8_rmRelatives_rmAdmixed_passingBespoke_maxNoCallFrac_1.0_rmBadIndividuals_passingFilters.min10kb.fromExon.noCpGIsland.noRepeat.noFish.0based.sorted.merged.bed

# pull out neutral regions from the all_8 file (to use for getting monomorphic sites) and from the snp_8 file (for easy sfs projection)
allVCF=all_8_rmRelatives_rmAdmixed_passingBespoke_maxNoCallFrac_1.0_rmBadIndividuals_passingFilters.vcf.gz

snpVCF=snp_8b_forEasySFS_rmRelatives_rmAdmixed_passingBespoke_maxNoCallFrac_1.0_passingBespoke_passingAllFilters_postMerge_raw_variants.vcf.gz

# snp vcf first:  # for easy SFS, don't have snp sfs be gzipped 

java -jar $GATK \
-R $REFERENCE \
-T SelectVariants \
--variant ${vcfdir}/${snpVCF} \
-o $outdir/neutral.${snpVCF%.gz} \
-L $neutralBed

# then all-sfs  (DO output as .gz)
java -jar $GATK \
-R $REFERENCE \
-T SelectVariants \
--variant ${vcfdir}/${allVCF} \
-o $outdir/neutral.${allVCF} \
-L $neutralBed

