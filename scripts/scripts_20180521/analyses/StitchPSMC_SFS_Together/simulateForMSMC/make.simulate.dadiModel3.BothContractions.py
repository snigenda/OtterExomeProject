# -*- coding: utf-8 -*-
"""
Created on Tue Oct 31 13:40:10 2017

@author: annabelbeichman
"""
# This is to set up a MACS script to simulate the full demographic history of the sea otter or giant otter
# want to make generic
# input
# spp
# mu
# Len

import pandas as pd

mu= float(8.64e-09)


r = float(1e-08)
Len = 30000000
num=60
blocksPerGroup=10
groups=num/blocksPerGroup
############ I don't yet know how consistent this model is with the SFS ; I just want to see how it behaves with MSMC first #############
Na = float(4500) # set based on MSMC weighted average (larger than dadi model, but we just want to look at msmc behavior right now)
# model design:
# starts at nuCur at 0
# then changes to nuMed at T_macs1
# then changes to Na=1 at T_macs2
nuMed = float(0.4) # set at 2000/4500
T_macs2 = float(0.06) # set at 1000/(2*4500) /2 to get it into macs format (scaled by 4N not 2N)
nuCur = float(0.06) # keep at 0.06 which is what it was relative to 3500, even for higher Nanc here. It's teh ratio that matters (0.06=195/3500 or 270/4500)
T_macs1 = float(0.0025) # keep atat 35/(2*3500) /2 to get it into macs format (scaled by 4N not 2N) which is what it was relative to 3500, but it's the ratio that matters.
### this model has two contractions, one ancient and one more recent. want to see how msmc responds to this.

ss=2 # two haplotypes (one genome)
theta = 4*Na*mu
rho = 4 * Na*r

# Note that theta will be the same across different values of Mu for the same
# models, because mutation rate changes scaling of MSMC and so alters Na, but then
# theta = 4Namu = 4 (1/(lamba*2mu))*mu = 2/lamba [is this right?]
############################## WRITE SCRIPT ################
print("#!/bin/bash")
print("#$ -cwd")
print("#$ -l h_rt=5:00:00,h_data=28G,highp")
print("#$ -N simDadiModel2")
print("#$ -m abe")
print("#$ -M ab08028")
print("#$ -o /u/flashscratch/a/ab08028/captures/reports/MaCS")
print("#$ -e /u/flashscratch/a/ab08028/captures/reports/MaCS")
print("#$ -t 1-10")

print("source /u/local/Modules/default/init/modules.sh")
print("module load anaconda")
# set up conda env:
print("# conda create -n MaCsSimulations python=3.6 # only once")
print("source activate MaCsSimulations")
print("wd=/u/flashscratch/a/ab08028/captures/analyses/simulateForMSMC")
print("cd $wd")
print("macsFile=/u/home/a/ab08028/klohmueldata/annabel_data/bin/macs")
print("msformatterFile=/u/home/a/ab08028/klohmueldata/annabel_data/bin/msformatter")
print("ms2multiFile=/u/home/a/ab08028/klohmueldata/annabel_data/bin/msmc-tools/ms2multihetsep.py")
#print("cp $macsFile $msformatter $ms2multiFile $wd")

print("rundate=`date +%Y%m%d`")
print("replicate=$SGE_TASK_ID")
print("model=dadiModel3.BothContractions")
print("mkdir -p ${model}")
print("for j in {1.."+str(groups)+"}")
# simulate slightly more than you need
print("do")
print("outdir=$wd/${model}/rep_${replicate}/group_$j.${model}")
print("mkdir -p $outdir")
print("cd $outdir")
print("cp -n $macsFile $outdir")
print("cp -n $msformatterFile $outdir")
print("cp -n $ms2multiFile $outdir")
print("for i in {1.."+str(blocksPerGroup)+"}")
print("do")

print("# dadi model 3 for msmc")
print("mu="+str(mu))
print("r="+str(r))
print("Na="+str(Na))
print("rho=" +str(rho))
print("theta="+str(theta))
print("date=`date +%Y%m%d`")
print("SEED=$((date+$RANDOM+((j-1)*"+str(blocksPerGroup)+")+i))") #
print("# this is a new addition! need to have a different random seed for each simulation; if they start within a second of each other, they will have the same seed. not an issue for big simulations of 30Mb because those are slow, but 100kb can start within a second of each other!")
print("./macs " +str(ss) +" "+str(Len)+" -t "+str(theta)+" -r "+str(rho)+" -s $SEED"+" -eN 0.0 "+str(nuCur)+" -eN "+str(T_macs1)+" "+str(nuMed)+" -eN "+str(T_macs2)+" 1"),
#for x, y in zip(times_gen_trimancient_4Na,diploids_trimancient_Na):
#    print("-eN " + str(x)+" "+str(y)),
print(" > $outdir/group_${j}_block_${i}.${model}.macsFormat.OutputFile.txt")

print("#convert to ms format")
print("./msformatter < $outdir/group_${j}_block_${i}.${model}.macsFormat.OutputFile.txt > $outdir/group_${j}_block_${i}.${model}.msFormat.OutputFile.txt")
print("#convert to msmc input format")
print("python ./ms2multihetsep.py $i "+ str(Len) +" < $outdir/group_${j}_block_${i}.${model}.msFormat.OutputFile.txt > $outdir/group_${j}_block_${i}.${model}.MSMCFormat.OutputFile.txt")

###################################################
print("done")
print("cd $wd")
print("done")
print("sleep 5m")
print("source deactivate # deactivate conda env")
