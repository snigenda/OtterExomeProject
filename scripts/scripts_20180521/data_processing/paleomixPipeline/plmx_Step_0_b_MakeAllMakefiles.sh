########### THIS SCRIPT (SHELL) WILL MAKE 1 makefile for every sample to be used in paleomix ########

############  directories ########
gitDir=/u/home/a/ab08028/klohmueldata/annabel_data/OtterExomeProject
# scripts:
scriptDir=$gitDir/scripts/scripts_20180521/data_processing
# script to run: 
scriptname=Step_2_FastqToSam.sh

########### file locations: ########
SCRATCH=/u/flashscratch/a/ab08028
wd=$SCRATCH/captures
fastqs=$wd/fastqs
makefileDir=/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/scripts/scripts_20180521/data_processing/paleomixPipeline/makefiles
modernTemplate=$makefileDir/sandbox_makefile_template.modernDNA.yaml
ancientTemplate=$makefileDir/sandbox_makefile_template.aDNA.yaml

########### ancient makefiles ########
START=1
END=12

cd $fastqs
for (( c=$START; c<=$END; c++ ))
do
fileR1=`ls A${c}_Elut*R1*fastq.gz` # the R1 fastq file; note that it starts with A for aDNA
header=${fileR1%_S*_R*} # this is the header sample name
# note the need for double quotation marks for sed
# make a new version of the makefile
cp $makefileDir/$modernTemplate $makefileDir/${header}.paleomix.makefile.yaml
newMake=$makefileDir/${makefileHeader}.${header}.paleomix.makefile.yaml
# for now NAME OF TARGET and SAMPLE are going to be the same
sed -i'' "s/NAME_OF_TARGET:/$header:/g" $newMake
sed -i'' "s/NAME_OF_SAMPLE:/$header:/g" $newMake
sed -i'' "s/NAME_OF_LIBRARY:/${header}_1a:/g" $newMake
# for now just naming Lane: Lane 1 because just one lane of novaseq
sed -i'' "s/NAME_OF_LANE:/Lane_1:/g" $newMake
# use different delims (|) to avoid filepath slash confusion:
sed -i'' 's|: PATH_WITH_WILDCARDS|: '${fastqs}\/${header}*fastq.gz'|g' $newMake

# clear variables
fileR1=''
header=''
makefileHeader=''
newMake=''
done
########### modern makefiles ########
# modern dna
START=30
END=167

# 
cd $fastqs
for (( c=$START; c<=$END; c++ ))
do
fileR1=`ls ${c}_Elut*R1*fastq.gz` # the R1 fastq file
header=${fileR1%_S*_R*} # this is the header sample name
# note the need for double quotation marks for sed
# make a new version of the makefile
cp $makefileDir/$modernTemplate $makefileDir/${header}.paleomix.makefile.yaml
newMake=$makefileDir/${makefileHeader}.${header}.paleomix.makefile.yaml
# for now NAME OF TARGET and SAMPLE are going to be the same
sed -i'' "s/NAME_OF_TARGET:/$header:/g" $newMake
sed -i'' "s/NAME_OF_SAMPLE:/$header:/g" $newMake
sed -i'' "s/NAME_OF_LIBRARY:/${header}_1a:/g" $newMake
# for now just naming Lane: Lane 1 because just one lane of novaseq
sed -i'' "s/NAME_OF_LANE:/Lane_1:/g" $newMake
# use different delims (|) to avoid filepath slash confusion:
sed -i'' 's|: PATH_WITH_WILDCARDS|: '${fastqs}\/${header}*fastq.gz'|g' $newMake

# clear variables
fileR1=''
header=''
makefileHeader=''
newMake=''
done