require(ggplot2)
require(RColorBrewer)
colorPal=RColorBrewer::brewer.pal(n=6,name = "Dark2")
colors=list(CA=colorPal[1],BAJ=colorPal[7],AK=colorPal[2],AL=colorPal[3],COM=colorPal[4],KUR=colorPal[5]) # your population colors
ancShape=8
modShape=1
######### Exploring heterozygosity with many different conditions ##########
### R plot pis from parsing Beagle:
# this is only based on 200K sites
todaysdate=format(Sys.Date(),"%Y%m%d")
plot.dir="/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/results/analysisResults/aDNA-ModernComparison/Heterozygosity/"
require(ggplot2)
require(reshape2)
#dates=c("20190524-highcov","20190524-lowcov") # eventually both
dates=c("20190701-highcov-AFprior-MajorMinor4","20190701-lowcov-AFprior-MajorMinor4")
#category=c("GPs","GLs")
categories="GPs"
#sites=c("",".neutralOnly") # either all sites or neutral # don't have neutral het yet.
sites="" # for now it's all sites 
#priors=c("AFprior") # not using UNIF prior -- it way overestimates heterozygosity "UNIFprior" based on my experiements on the 20190524 GLs 
overallDir="/Users/annabelbeichman/Documents/UCLA/Otters/OtterExomeProject/results/analysisResults/aDNA-ModernComparison/Heterozygosity/"
#probCutoffs=c(0.5,0.95) # two possible cutoffs
# I found that 0.5 is too lax; using 0.95 from here out
probCutoffs=0.95
depthCutoff=1
minInds=c(2) # for now just did minInd =2 (maybe should do minInd = 1? ,3,5,9) # different combos of minInds I used
#refs=c("mfur","elut") 
# for now just ferret
refs=c("elut","mfur")
allInputs=data.frame()
# could make this a function to apply to a matrix as well
################################ Genome-Wide ################################
for(angsdDate in dates) {
    data.dir=paste(overallDir,angsdDate,"/",sep="")
    for(ref in refs){
      for(sitetype in sites){
        for(category in categories){
          for(probCutoff in probCutoffs){
            for(minInd in minInds){
              input <- read.table(paste(data.dir,"angsdOut.mappedTo",ref,".superfile.",category,sitetype,".hetHomTotals.ProbCutoff.",probCutoff,".DepthCutoff.",depthCutoff,".minInd.",minInd,".",angsdDate,".txt",sep=""),header=T,sep="\t")
              input$date <- angsdDate
              input$category <- category
              input$label <- "modern"
              input[grep("^A",input$sample),]$label <- "ancient"
              input$population <- unlist(lapply(strsplit(as.character(input$sample),"_"),"[",3))
              # check if any of the sample IDs contain "downsamp":
              input$downsampled <- "Non-Downsampled"
              #if(any(grepl("downsamp",input$sample))){
              #  input[grep("downsamp",input$sample),]$downsampled <- "downsampled-dataset"
              #}
              # this will assign ancient samples to highcover-dataset or downsampled-dataset as well
              # that is actually desired for plotting to split up ancient GPs gotten in context of high or low coverage modern data
              if(grepl("lowcov",angsdDate)){
                input$downsampled <- "Downsampled"
              }
              input$reference <- ref
              if(sitetype==""){
                input$sites <- "allSites"
              }
              else if(sitetype==".neutralOnly"){
                input$sites <- "neutral"
              }
              allInputs = rbind(allInputs,input)
            }
          }
        }
      }
    }
  }

# just get heterozygosity measures: (can eventually get the others)
input_melt <- melt(allInputs,measure.vars = c("HetPerSite","HetPerSite_TransversionsOnly","callableSites","sumHomAltGLsOrGPs","sumHomAltGLsOrGPs_TransversionsOnly"),id.vars = c("sample","label","population","reference","date","Filter_PerIndividualDepthMinimum","Filter_ProbThresholdForCallableSite","Filter_minIndsPerSite","downsampled","sites"))

# label transitions+transv vs transv only
input_melt$TVLabel <- "Transitions+Transversions"
input_melt[input_melt$variable=="HetPerSite_TransversionsOnly",]$TVLabel <- "TransversionsOnly"

hetOnly_input_melt <- input_melt[input_melt$variable %in% c("HetPerSite","HetPerSite_TransversionsOnly"),]
callableSitesONly_input_melt <- input_melt[input_melt$variable %in% c("callableSites"),]
# characterize this
for(ref in refs){
  p1 <- ggplot(hetOnly_input_melt[hetOnly_input_melt$reference==ref,],aes(x=label,y=value,fill=label))+
    geom_violin(position=position_dodge(.5))+
    geom_point(position=position_dodge(.5),size = 1)+
    theme_bw()+
    ggtitle(paste("Comparing Heterozygosity based on ",category,"\nmapped to ",ref,"\nfilter info format: depth.minInd.minDepthPerInd.MaxProbCutoff",sep=""))+
    theme(legend.title = element_blank(),axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"))+
    xlab("")+
    facet_grid(interaction(downsampled,Filter_minIndsPerSite,Filter_PerIndividualDepthMinimum,Filter_ProbThresholdForCallableSite)~TVLabel~sites,scales="free")
  p1
  ggsave(paste(plot.dir,"mappedto.",ref,".hetComparison.basic.",todaysdate,".pdf",sep=""),p1,height=8,width=7) 
  ############### P2: impact of min GP filter #######################
  # minInd=2 # just plot with this to see impact of something else 
  # p2 <- ggplot(hetOnly_input_melt[hetOnly_input_melt$prior=="AFprior" & hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_minIndsPerSite==minInd,],aes(x=interaction(downsampled,as.factor(Filter_ProbThresholdForCallableSite)),y=value,fill=label))+
  #   geom_violin(position=position_dodge(.5))+
  #   #geom_point(position=position_dodge(.5),size = 1)+
  #   geom_point(position=position_jitterdodge(jitter.width = 0.05,
  #                                            dodge.width = 0.5,seed=3),size=.8)+
  #   theme_bw()+
  #   ggtitle(paste("minInd = ",minInd,"\nInfluence of max prob filter on heterozygosity from ", category,"\nmapped to ",ref,"\nDashed black line is what we expect genome-wide het to be from Gidget's genome",sep=""))+
  #   theme(legend.title = element_blank(),axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=14))+
  #   xlab("GP minimum cutoff for most supported genotype")+
  #   facet_grid(TVLabel~sites)+
  #   geom_hline(data=data.frame(yint=0.0003,TVLabel="Transitions+Transversions"),aes(yintercept=yint),linetype="dashed") # just adding to Transit+Transv
 # p2
 # ggsave(paste(plot.dir,"mappedto.",ref,".hetComparison.effectOfProbCutoff.",todaysdate,".pdf",sep=""),p2,height=5,width=14) 
  
  ############ P3: influence of min individuals filter ######################
  # just use filter of 0.95 to simplify results:
    #probs=c(0.5,0.95)
    #for(prob in probs){
   # p3 <- ggplot(hetOnly_input_melt[hetOnly_input_melt$prior=="AFprior" & hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_ProbThresholdForCallableSite==prob,],aes(x=as.factor(Filter_minIndsPerSite),y=value,fill=label))+
    #geom_violin(position=position_dodge(.5))+
   # geom_point(position=position_jitterdodge(jitter.width = 0.05,
   #                                          dodge.width = 0.5,seed=3),size = 1)+
   # theme_bw()+
    #ggtitle(paste("Influence of min individuals filter on heterozygosity from ",category,"\nmapped to ",ref,"\nProbThreshold: ",prob,"\nDashed black line is what we expect genome-wide het to be from Gidget's genome", sep=""))+
   # theme(legend.title = element_blank(),axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=14))+
   # xlab("Minimum Individuals with data per site")+
    #geom_hline(data=data.frame(yint=c(0.0001,0.0003),TVLabel="Transitions+Transversions",downsampled=c("Downsampled","Downsampled","Non-Downsampled","Non-Downsampled"),sites=c("neutral","allSites"),Filter_PerIndividualDepthMinimum=1),aes(yintercept=yint),linetype="dashed")+ # just adding to Transit+Transv
#facet_grid(sites~interaction(downsampled,Filter_PerIndividualDepthMinimum)~TVLabel,scales="free")# just adding to Transit+Transv
  #p3
  #ggsave(paste(plot.dir,"mappedto.",ref,".hetComparison.effectOfMinInd.prob.",prob,".",todaysdate,".pdf",sep=""),p3,height=10,width=10) 
  #  }
  ###### I think min = 2 -3 is best.

  # so based on this, I think 0.95 filter is better
  ###################### P4: MAIN TEXT FIGURE COMPONENT #####################################
  minInd=2 # choose whatever you want, 2-3 seem reasonable
  prob=0.95 # definitely choose 0.95
  p4a <- ggplot(hetOnly_input_melt[hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_ProbThresholdForCallableSite==prob & hetOnly_input_melt$Filter_minIndsPerSite==minInd,],aes(x=label,y=value,fill=label))+
    geom_violin(position=position_dodge(.5))+
    geom_point(position=position_jitterdodge(jitter.width = 0.05,
                                             dodge.width = 0.5,seed=3),size = 1)+
    theme_bw()+
    ggtitle(paste("Influence of min individuals filter on heterozygosity from ",category,"\nmapped to ",ref,"\nProbThreshold: ",prob," MinInd: ",minInd,"\nDashed black line is what we expect genome-wide het to be from Gidget's genome", sep=""))+
    theme(legend.title = element_blank(),legend.position = "none",axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=10))+
    xlab("")+ylab("Individual Heterozygosity")+
    geom_hline(data=data.frame(yint=0.0003,sites=("allSites"),TVLabel="Transitions+Transversions",downsampled=c("Downsampled","Downsampled","Non-Downsampled","Non-Downsampled"),Filter_PerIndividualDepthMinimum=1),aes(yintercept=yint),linetype="dashed")+ # just adding to Transit+Transv
    facet_grid(sites~downsampled~TVLabel)# just adding to Transit+Transv
  p4a
  ggsave(paste(plot.dir,"mappedto.",ref,".hetComparison.ExampleForMainText.prob.",prob,".",todaysdate,".pdf",sep=""),p4a,height=10,width=10) 
  p4b <- ggplot(hetOnly_input_melt[hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_ProbThresholdForCallableSite==prob & hetOnly_input_melt$Filter_minIndsPerSite==minInd & hetOnly_input_melt$TVLabel=="TransversionsOnly",],aes(x=label,y=value,fill=label))+
    geom_violin(position=position_dodge(.5))+
    geom_point(position=position_jitterdodge(jitter.width = 0.05,
                                             dodge.width = 0.5,seed=3),size = 1)+
    theme_bw()+
    ggtitle(paste("Heterozygosity from ",category,"\nmapped to ",ref,"\nProbThreshold: ",prob," MinInd: ",minInd,"\nTransversions Only" ,sep=""))+
    theme(legend.title = element_blank(),legend.position = "none",axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=14))+
    xlab("")+ylab("Individual Heterozygosity")+
    facet_grid(sites~downsampled)# just adding to Transit+Transv
  p4b
  ggsave(paste(plot.dir,"mappedto.",ref,".hetComparison.ExampleForMainText.TransversionsOnly.prob.",prob,".",todaysdate,".pdf",sep=""),p4b,height=10,width=10) 
  ######### P5: Plot callable sites for different filters (focus on GP 0.95 only): #############
  prob=0.95
  p5 <- ggplot(callableSitesONly_input_melt[callableSitesONly_input_melt$reference==ref & callableSitesONly_input_melt$Filter_ProbThresholdForCallableSite==prob,],aes(x=sample,y=value,fill=as.factor(Filter_minIndsPerSite)))+
    geom_bar(position="dodge",stat="identity")+
    coord_flip()+
    facet_wrap(~downsampled~sites,scales="free")+
    theme_bw()+
    theme(legend.title = element_blank(),axis.text = element_text(size=8),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=14))+
    ggtitle("Callable Sites after filters applied\nColors show impact of minInd = 2,3,5,9")
   p5 
   ggsave(paste(plot.dir,"mappedto.",ref,".callableSites.prob.",prob,".",todaysdate,".pdf",sep=""),p5,height=4,width=14) 
   ############################ P6: plot callable sites vs het for aDNA only ############
   p6a <- ggplot(allInputs[allInputs$reference==ref & allInputs$Filter_ProbThresholdForCallableSite==prob & allInputs$Filter_minIndsPerSite==minInd,],aes(x=callableSites,y=HetPerSite,color=label))+
     geom_point()+
     theme_bw()+
     theme(legend.title = element_blank(),axis.text = element_text(size=8),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=14))+
     facet_wrap(~downsampled,scales="free")
   p6a
   ggsave(paste(plot.dir,"mappedto.",ref,".aDNA.callableSitesVsHet.",prob,".",todaysdate,".pdf",sep=""),p6a,height=4,width=14) 
   p6b <- ggplot(allInputs[allInputs$reference==ref & allInputs$Filter_ProbThresholdForCallableSite==prob & allInputs$Filter_minIndsPerSite==minInd,],aes(x=callableSites,y=HetPerSite_TransversionsOnly,color=label))+
     geom_point()+
     theme_bw()+
     theme(legend.title = element_blank(),axis.text = element_text(size=8),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=14))+
     facet_wrap(~downsampled,scales="free")
   p6b
   ggsave(paste(plot.dir,"mappedto.",ref,".aDNA.callableSitesVsHet.",prob,".transversionsOnly.",todaysdate,".pdf",sep=""),p6b,height=4,width=14) 
   
   ########### Plot 7: experimenting with alternate plots for paper ###########
   # just want full coverage (non-downsampled) and want to put the downsampled in the SI # 
   minInd=2 # choose whatever you want, 2-3 seem reasonable
   prob=0.95 # definitely choose 0.95
   # make an abbreviated TiTv label:
   hetOnly_input_melt$TVLabel2 <- "Ti+Tv"
   hetOnly_input_melt[hetOnly_input_melt$TVLabel=="TransversionsOnly",]$TVLabel2 <- "Tv Only"
   p7a <- ggplot(hetOnly_input_melt[hetOnly_input_melt$downsampled=="Non-Downsampled"& hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_ProbThresholdForCallableSite==prob & hetOnly_input_melt$Filter_minIndsPerSite==minInd,],aes(x=TVLabel2,y=value,shape=label,color=as.factor(population)))+
     #geom_violin(position=position_dodge(.5))+
     #geom_point(position=position_jitterdodge(jitter.width = 0.1,dodge.width = 0.5,seed=3),size = 4,alpha=0.75)+
     #geom_point(size = 3)+
     geom_jitter(width = 0.05,size=3)+
     theme_bw()+
     #ggtitle(paste("heterozygosity from ",category,"\nmapped to ",ref,"\nProbThreshold: ",prob," MinInd: ",minInd,"\nDashed black line is what we expect genome-wide het to be from Gidget's genome", sep=""))+
     theme(legend.title = element_blank(),axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=10))+
     xlab("")+ylab("Individual Heterozygosity")+
     geom_hline(data=data.frame(yint=0.0003,sites=("allSites"),TVLabel="Transitions+Transversions",downsampled=c("Downsampled","Downsampled","Non-Downsampled","Non-Downsampled"),Filter_PerIndividualDepthMinimum=1),aes(yintercept=yint),linetype="dashed")+
     scale_shape_manual(values=c(8,1)) +
     scale_color_manual(values=c(unlist(colors['AK']), unlist(colors['CA'])))
   p7a
   ggsave(paste(plot.dir,"FORPAPER.mappedto.",ref,".aDNA.Het.TiTv.smallJitter.highCovOnly.",prob,".transversionsOnly.",todaysdate,".pdf",sep=""),p7a,height=4,width=5) 
   
   
   ############## downsampled version for SI ##############
   # order of factors: 
   hetOnly_input_melt$downsampled <- factor(hetOnly_input_melt$downsampled, levels=c("Non-Downsampled","Downsampled"))
   p7b <- ggplot(hetOnly_input_melt[ hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_ProbThresholdForCallableSite==prob & hetOnly_input_melt$Filter_minIndsPerSite==minInd,],aes(x=TVLabel2,y=value,shape=label,color=as.factor(population)))+
     #geom_violin(position=position_dodge(.5))+
     #geom_point(position=position_jitterdodge(jitter.width = 0.1,dodge.width = 0.5,seed=3),size = 4,alpha=0.75)+
     #geom_point(size = 3)+
     geom_jitter(width = 0.05,size=3)+
     theme_bw()+
     #ggtitle(paste("heterozygosity from ",category,"\nmapped to ",ref,"\nProbThreshold: ",prob," MinInd: ",minInd,"\nDashed black line is what we expect genome-wide het to be from Gidget's genome", sep=""))+
     theme(legend.title = element_blank(),axis.text = element_text(size=14),legend.text = element_text(size=14),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=10))+
     xlab("")+ylab("Individual Heterozygosity")+
     geom_hline(data=data.frame(yint=0.0003,sites=("allSites"),TVLabel="Transitions+Transversions",downsampled=c("Downsampled","Downsampled","Non-Downsampled","Non-Downsampled"),Filter_PerIndividualDepthMinimum=1),aes(yintercept=yint),linetype="dashed")+
     scale_shape_manual(values=c(8,1)) +
     scale_color_manual(values=c(unlist(colors['AK']), unlist(colors['CA'])))+
     facet_wrap(~downsampled)
   p7b
   ggsave(paste(plot.dir,"FORSI.mappedto.",ref,".aDNA.Het.TiTv.smallJitter.lowCovOnly.",prob,".transversionsOnly.",todaysdate,".pdf",sep=""),p7b,height=4,width=6) 
   
   ########### Plot 8: want to show transversions with downsampling on own ###########
   #new groups
   hetOnly_input_melt$newGroupName <- NA
   hetOnly_input_melt[hetOnly_input_melt$population=="CA" & hetOnly_input_melt$label=="ancient",]$newGroupName <-"Ancient"
   hetOnly_input_melt[hetOnly_input_melt$population=="CA" & hetOnly_input_melt$label=="modern",]$newGroupName <-"Modern-CA"
   hetOnly_input_melt[hetOnly_input_melt$population=="AK" & hetOnly_input_melt$label=="modern",]$newGroupName <-"Modern-AK"
   p8a <- ggplot(hetOnly_input_melt[hetOnly_input_melt$TVLabel2=="Tv Only" & hetOnly_input_melt$reference==ref & hetOnly_input_melt$Filter_ProbThresholdForCallableSite==prob & hetOnly_input_melt$Filter_minIndsPerSite==minInd,],aes(x=newGroupName,y=value,shape=label,color=as.factor(population)))+
     geom_jitter(width = 0.05,size=3)+
     theme_bw()+
     theme(legend.title = element_blank(),axis.text = element_text(size=10),legend.text = element_text(size=10),legend.background = element_rect(fill = "transparent"),strip.text = element_text(size=10))+
     xlab("")+ylab("Individual Heterozygosity")+
     scale_shape_manual(values=c(8,1)) +
     scale_color_manual(values=c(unlist(colors['AK']), unlist(colors['CA'])))+
     facet_wrap(~downsampled)+
     ggtitle(paste("Heterozygosity (transversions only)\nmapped to ",ref,sep=""))+
     theme(legend.position = "none")
   p8a
   ggsave(paste(plot.dir,"FORPAPER.mappedto.",ref,".aDNA.Het.TvOnly.smallJitter.",prob,".transversionsOnly.",todaysdate,".pdf",sep=""),p8a,height=2.2,width=7) 

}


