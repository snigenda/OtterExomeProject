#! /bin/bash
#$ -cwd
#$ -l h_rt=24:00:00,h_data=8G
#$ -m abe
#$ -M ab08028
#$ -N generateContInput
#$ -e /u/flashscratch/a/ab08028/captures/reports/angsd
#$ -o /u/flashscratch/a/ab08028/captures/reports/angsd


source /u/local/Modules/default/init/modules.sh
module load python

gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
scriptDir=$gitDir/scripts/scripts_20180521/

script=$scriptDir/analyses/aDNA-ModernComparison/continuity/generateContinuityInput.py
ref=mfur # only mfur for continuity
################### alaska ###################
pop=AK
for category in ancient # just did ancient-AK comparison, didn't do modern AK-AK comparison yet
do
indir=/u/flashscratch/a/ab08028/captures/aDNA-ModernComparison/continuity/combinedCounts-Freqs
input=${pop}.angsdOut.mappedTo${ref}.${category}.counts.freqsFromModernGATK.superfile.0based.bed
outfile=${input%.0based.bed}.1based.contInput.txt
outfileTV=${input%.0based.bed}.1based.contInput.TVOnly.txt

python $script $indir/$input $indir/$outfile $indir/$outfileTV

done
################### california ###################
pop=CA
for category in ancient lowcov$pop highcov$pop
do
indir=/u/flashscratch/a/ab08028/captures/aDNA-ModernComparison/continuity/combinedCounts-Freqs
input=${pop}.angsdOut.mappedTo${ref}.${category}.counts.freqsFromModernGATK.superfile.0based.bed
outfile=${input%.0based.bed}.1based.contInput.txt
outfileTV=${input%.0based.bed}.1based.contInput.TVOnly.txt

python $script $indir/$input $indir/$outfile $indir/$outfileTV
done
