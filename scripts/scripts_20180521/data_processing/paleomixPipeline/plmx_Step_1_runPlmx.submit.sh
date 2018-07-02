#! /bin/bash
#$ -cwd
#$ -l h_rt=50:00:00,h_data=1G,highp
#$ -o /u/flashscratch/a/ab08028/captures/reports/submissions/
#$ -e /u/flashscratch/a/ab08028/captures/reports/submissions/
#$ -m bea
#$ -M ab08028
#$ -N plmx_submit
######### This script run will submit a series of jobs that convert fastq to sam and adds readgroup info
QSUB=/u/systems/UGE8.0.1vm/bin/lx-amd64/qsub

# location of github:  which may be on remote server or local laptop
gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject/
# scripts:
scriptDir=$gitDir/scripts/scripts_20180521/data_processing/paleomix
# script to run: 
scriptname=plmx_Step_1_runPlmx.sh

# file locations:
SCRATCH=/u/flashscratch/a/ab08028
wd=$SCRATCH/captures
fastqs=$wd/fastqs
makefileDir=/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/scripts/scripts_20180521/data_processing/paleomixPipeline/makefiles

# makefile:

# outdirectory:
outdir=$wd/paleomix
mkdir -p $outdir
# job info: 
errorLocation=/u/flashscratch/a/ab08028/captures/reports/paleomix # report location
user=ab08028 # where emails are sent

# usage; qsub script [makefile, full path] [outdir]
START=1
END=12

cd $fastqs
for (( c=$START; c<=$END; c++ ))
do
fileR1=`ls A${c}_Elut*R1*fastq.gz` # the R1 fastq file; note that it starts with A for aDNA
header=${fileR1%_S*_R*} # this is the header sample name
$QSUB -e $errorLocation -o $errorLocation -M $user -N fq2sam${c} \
$scriptDir/$scriptname $makefileDir/${header}.paleomix.makefile.yam $outdir
sleep 10m
done