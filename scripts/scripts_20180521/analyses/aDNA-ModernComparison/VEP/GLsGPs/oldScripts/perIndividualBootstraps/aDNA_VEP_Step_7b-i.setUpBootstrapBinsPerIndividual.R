############# This script will first pull out the scaffolds of the ferret genome for which you have cds information in your input file. It will then bin those scaffolds into bins of a specified bin size.  For the specified individual, it will get totals of differnet categories of site per bin. Many of these bins will be empty because they don't contain cds sites, so they will be dropped. Each remaining bin will have the GPs from ANGSD summed up (for sites *passing depth and GP filters*) to get the sums of HomRef, homAlt and het sites. It will do this for all sites and then for transversions only. It will write these bin totals out. In the next step (7b-ii), it will then resample (with replacement) those individual's bins until a threshold of sites is reached (which you specify, should be average callable cds sites across all your individuals).  It will do this a specified number of times (numBoot) to generate bootstrap distributions for each individual. 

# This is an improvement over my old way of doing it that just resampled sites. By resampling over bins of the genome we are getting at LD structure better. 

# Note this sums up combo annotations because it assumes --pick has been used! (so if it's missense,splice_something) it still gets to be missense; synonymous,splice is also syn.
################## left to do: somewhere need to check for uniqueness (maybe before the script) #### 
transversions=c('A,C','C,A','A,T','T,A','C,G','G,C','G,T','T,G')
#BiocManager::install("plyranges")
require(GenomicRanges)
require(dplyr)
require(plyranges)
#require(bootstrap)
# install plyranges (dplyr to work with Granges)
#if (!requireNamespace("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")
# BiocManager::install("plyranges")
## okay this works pretty well; want to parallelize and try running on hoffman and be able to feed in files; and make sure point estimates are inside there somewhere.
#require(plyranges) # this is needed so you can use group_by with GRanges objects!!
#minDepth=1 # make this match whatever I used to get point estimate
#minGP=0.95 # make this match whatever I used to get point estimate
#binsize=100000 # start with 100kb
#out.dir="/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/scripts/sandbox/bootStrapRegions/"
library("optparse")
option_list = list(
  make_option(c("--infile"), type="character", default=NULL, 
              help="path to your input file (superfile of cds sites with annotations from vep and GPs from angsd as well as depths", metavar="file"),
  make_option(c("--chrSizes"), type="character", default=NULL, 
              help="path to file with mustela chromosome sizes", metavar="character"),
  make_option(c("--outdir"), type="character", default=NULL, 
              help="path to outdir", metavar="dir"),
  make_option(c("--outPREFIX"), type="character", default=NULL, 
              help="outfilePrefix", metavar="prefix"),
  make_option(c("--minDepth"), type="numeric", default=NULL, 
              help="min depth per individual for a site to be 'callalble'", metavar="numeric"),
  make_option(c("--minGP"), type="numeric", default=NULL, 
              help="minimum value of the max. GP per site, per individual. Use 0.95.", metavar="numeric"),
  make_option(c("--binsize"), type="numeric", default=NULL, 
              help="Size of bin to chunk the genome into (should be > than a recombination block)", metavar="numeric"),
  make_option(c("--indNum"), type="numeric", default=NULL, 
              help="Individual number assigned by ANGSD, starts at 0 (for my study it's 0-8))", metavar="numeric")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

cdsFile=opt$infile
mustelaChrSizesFile=opt$chrSizes
out.dir=opt$outdir
outPREFIX=opt$outPREFIX
minDepth=as.numeric(opt$minDepth) # make this match whatever I used to get point estimate
minGP=as.numeric(opt$minGP) # make this match whatever I used to get point estimate
binsize=as.numeric(opt$binsize) # start with 100kb
ind=as.numeric(opt$indNum)
#print("read in arguments:\n")
#print("cdsFile: ",cdsFile,"\n")
#print("chrSizes: ",mustelaChrSizesFile,"\n")
#print("out.dir: ",out.dir,"\n")
#print("outPREFIX: ",outPREFIX,"\n")
#print("minDepth: ",minDepth,"\n")
#print("minGP: ",minGP,"\n")
#print("binsize: ",binsize,"\n")
#print("numBoots: ",numBoots,"\n")
#print("SitesToDraw: ",SitesToDraw,"\n")


###############read in cds superfile ######################
#cds=read.table("/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/scripts/sandbox/bootStrapRegions/test.out.bed",header=T,sep="\t",strip.white = T, comment.char = "") # converts # to X. in table ### will R be able to read it in on Hoffman?
cds=read.table(cdsFile,header=T,sep="\t",strip.white = T, comment.char = "")
############# get cds superfile and make it a Granges object #######
mustelaChrSizes=read.table(mustelaChrSizesFile,sep=",",stringsAsFactors = F,strip.white = T)
#mustelaChrSizes <- (read.table("/Users/annabelbeichman/Documents/UCLA/Otters/RawReadsToGenotypes_Dec2016/mappingGidgetReadsToFerret/genome-stats/SlidingWindowheterozygosity/Mustela_putorius_furo.MusPutFur1.0.dna.toplevel.224.ChrLengths.txt",sep=",",stringsAsFactors = F,strip.white = T))
mustelaChrSizes <- data.frame(t(mustelaChrSizes))
colnames(mustelaChrSizes) <- "record"
mustelaChrSizes$scaff <- lapply(strsplit(as.character(mustelaChrSizes$record),":"),"[",1)
mustelaChrSizes$size <- lapply(strsplit(as.character(mustelaChrSizes$record),":"),"[",2)

####### intersect with the scaffolds that are in my cds Granges object #########
mustelaChrSizes_cds <-  mustelaChrSizes[mustelaChrSizes$scaff %in% unique(cds$chromo),] # 
sizes <- as.numeric(mustelaChrSizes_cds$size)
names(sizes) <- mustelaChrSizes_cds$scaff
########### split scaffolds into even sized bins (some will be empty because don't contain cds) #######
###  bins for bootstrapping
bins   <- tileGenome(sizes, tilewidth=binsize, cut.last.tile.in.chrom=T)
#bins
# add a bin number to each bin
bins$binNum <- seq(1,length(bins))
print(c("number of unique bins:", length(unique(bins$binNum))))
write.table(bins,paste(out.dir,"/",outPREFIX,".Ind.",ind,".BinCoords.txt",sep=""),col.names = T,row.names = F,quote=F,sep="\t")
############### want to sum stuff up per bin per category #######
# so want to sum up missense GPs 00 01 11 per individual
# also need to specify depth min and GP min -- hold off for a second
# going individual by individual (0 -->8)
#ind=0 # eventually loop over each individual or do them in parallel
# pull out the columsn relevant to that individual:
# 1 based position:
allIndsAllBoots=data.frame()
#for(ind in seq(0,8)){
print(paste("starting ind",ind))
IndVariables=c("chromo","start0based","end","position","major","minor","ref",paste("Ind",ind,sep=""),paste("Ind",ind,".1",sep=""),paste("Ind",ind,".2",sep=""),paste("ind",ind,"TotDepth",sep=""),"Consequence") # note: IndX is 00, IndX.1 is 01, IndX.2 is 11 
indOnly <- cds[,IndVariables] # okay this works. 
# need to filter on a few things; 
# make generic column names:
colnames(indOnly) <- c("chromo","start0based","end","position1based","major","minor","ref","homRef","het","homAlt","indDepth","Consequence")

#head(indOnly)
####### employ filters:
# get maxGP value among the homRef, het or homAlt GTs:
indOnly$maxGP <- apply(indOnly[,c("homRef","het","homAlt")],1,max) # this works
# 1. min depth
# 20180816: fixed this to be >= not just > -- this could cause discrepancy! 
indOnly_filter <- indOnly %>% 
  filter(indDepth >= minDepth) %>%
  filter(maxGP >= minGP) # this makes sure that whatever the largest GP is for the site, that it is > some cutoff for the site (makes a 'callable site')

# okay so now it's been filtered by GP and by Depth
# want to sum up by category
totalCallableSites=dim(indOnly_filter)[1] # after filtering, the sites remaining are the total callable sites. 

# how to deal with no-consequence?
# also need to make sure are no duplicates
# also need to deal with TVs.
##### label them as Ti or Tv


# make sure ref is in major minor
indOnly_filter$Alleles <- paste(indOnly_filter$major,indOnly_filter$minor,sep=",")

test <- makeGRangesFromDataFrame(df=indOnly_filter,keep.extra.columns = T,ignore.strand = T,seqnames.field = "chromo",start.field = "start0based",end.field = "end",starts.in.df.are.0based = T,seqinfo = NULL)

### skip empty bins!
indAllBins <- data.frame()
print("setting up bins (takes a while)")
#test = data.frame(indAllBins) %>% 
#  group_by(Consequence)
for(bin in seq(1,length(unique(bins$binNum)))){
  print(bin)
  subset <- subsetByOverlaps(test, bins[bins$binNum==bin,])
  totalCallableSites=length(subset)
  print(c("total callable sites:", totalCallableSites))
  if(totalCallableSites>0){
    # all sites:
    TiTvTotals <- subset %>% 
      group_by(Consequence) %>%
      summarise(sumHomRef=sum(homRef),sumHet=sum(het),sumHomAlt=sum(homAlt))
    sum(TiTvTotals$sumHomRef,TiTvTotals$sumHet,TiTvTotals$sumHomAlt)==totalCallableSites # SHOULD BE TRUE -- should all add up to total
    # add metadata
    TiTvTotals$ind <- ind
    TiTvTotals$binNum <- bin
    TiTvTotals$scaff <- as.character(unlist(seqnames(bins[bins$binNum==bin,])))
    TiTvTotals$start <- start(bins[bins$binNum==bin,])
    TiTvTotals$end <- end(bins[bins$binNum==bin,])
    TiTvTotals$width <- width(bins[bins$binNum==bin,])
    TiTvTotals$totalCallableSitesPerBin <- totalCallableSites
    TiTvTotals$minDepth <- minDepth
    TiTvTotals$minGP <- minGP
    TiTvTotals$sites <- "Ti+Tv"
    # put all together: 

    indAllBins <- rbind(indAllBins,TiTvTotals)
    # TV only:
    print("starting transversions")
    TvTotals <- subset %>% 
      group_by(Consequence) %>%
      filter(Alleles %in% transversions) %>%
      summarise(sumHomRef=sum(homRef),sumHet=sum(het),sumHomAlt=sum(homAlt))
    # check to make sure there are transversions (may be where low-cov fails)
    if(dim(TvTotals)[1] > 0){
    # add metadata
    TvTotals$ind <- ind
    TvTotals$binNum <- bin
    TvTotals$scaff <- as.character(unlist(seqnames(bins[bins$binNum==bin,])))
    TvTotals$start <- start(bins[bins$binNum==bin,])
    TvTotals$end <- end(bins[bins$binNum==bin,])
    TvTotals$width <- width(bins[bins$binNum==bin,])
    TvTotals$totalCallableSitesPerBin <- totalCallableSites
    TvTotals$minDepth <- minDepth
    TvTotals$minGP <- minGP
    TvTotals$sites <- "TvOnly"
    # put all together:
    indAllBins <- rbind(indAllBins,TvTotals)
    }
    else{
      print("no TV in this bin!")
    }
  }}

print(c("Total filled bins for ind",ind,": ",length(unique(indAllBins$binNum))))

write.table(indAllBins,paste(out.dir,"/",outPREFIX,".Ind.",ind,".sumsPerBin.txt",sep=""),col.names = T,row.names = F,quote=F,sep="\t")
