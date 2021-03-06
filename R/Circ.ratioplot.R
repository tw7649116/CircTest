## Give a circRNA count data, plot a certain row or plot all rows
#' @title Circ.ratioplot
#' 
#' @description
#' Plot the ratio of circRNAs to the total transcripts (circRNA plus liner RNA).
#' @param Circ CircRNACount file. A file of circRNA read count table. First three columns are circRNA coordinates, and followed by columns for circRNA read counts, each sample per column. 
#' @param Linear LinearCount file. A file of circRNA host gene expression count table. Same configuration as CircRNACount file.
#' @param plotrow The rownumber or rowname in the CircRNACount table corresponding the specific gene which you want to plot.
#' @param size the text size. Default 18.
#' @param ncol if groupindicator2 is provided, specify the panel layout. Default 2.
#' @param CircCoordinates BED format circRNA coordinates file. 
#' @param groupindicator1 A vector of group indicators. For example, ages. 
#' @param groupindicator2 An other vector of group indicators. For example, tissues. This indicator will be used to segement plots out.
#' @param x x axis lable. Default 'Conditions'.
#' @param y y axis lable. Default 'circRNA/(circRNA+Linear)'.
#' @param lab_legend legend title
#' @param circle_description Column indices which do not carry circle/linear read counts.
#' @param gene_column Column index of the column containing the gene name in CircCoordinates if available, otherwise its chosen from Circ.
#' @examples data(Coordinates)
#' data(Circ)
#' data(Linear)
#' @examples data(Coordinates)
#' data(Circ)
#' data(Linear)
#' Circ.ratioplot(Circ,Linear,Coordinates,plotrow=10,groupindicator1=c(rep('1days',6),rep('4days',6),rep('20days',6)),groupindicator2=rep(c(rep('Female',4),rep('Male',2)),3),lab_legend='Ages', circle_description = c(1:3), gene_column = 4)
#' 
#' @export Circ.ratioplot
#' 
Circ.ratioplot <- function(Circ,Linear,CircCoordinates = None,plotrow='1',size=18,ncol=2,groupindicator1=NULL,groupindicator2=NULL,x='Conditions',y='circRNA/(circRNA+Linear)',lab_legend='groupindicator1', circle_description = c(1:3), gene_column = None){
  require(ggplot2)
  #require(Rmisc)

  if( !is.null(groupindicator1) & length(groupindicator1) != ncol(Circ)-length(circle_description) ){
    stop("If provided, the length of groupindicator1 should be equal to the number of samples.")
  }
  if( !is.null(groupindicator2) & length(groupindicator2) != ncol(Circ)-length(circle_description) ){
    stop("If provided, the length of groupindicator2 should be equal to the number of samples.")
  }
  if(is.null(groupindicator1)){
    stop("At least one grouping should be provided through groupindicator1.")
  }
  if(!is.null(groupindicator2)){
    twolevel <- TRUE
  }else{
    twolevel <- FALSE
  }
  
  rownames.circ <- rownames(Circ)
  Circ <- data.frame(lapply(Circ, as.character), stringsAsFactors=FALSE)
  rownames(Circ) <- rownames.circ
  
  rownames.linear <- rownames(Linear)
  Linear <- data.frame(lapply(Linear, as.character), stringsAsFactors=FALSE)
  rownames(Linear) <- rownames.linear
  
  if(!missing(CircCoordinates)){
    rownames.circCoordinates <- rownames(CircCoordinates)
    CircCoordinates <- data.frame(lapply(CircCoordinates, as.character), stringsAsFactors=FALSE)
    rownames(CircCoordinates) <- rownames.circCoordinates
  }else{
    CircCoordinates <- data.frame(Circ[,circle_description])
    rownames(CircCoordinates) <- rownames.circ
    rownames.circCoordinates <- rownames(CircCoordinates)
    CircCoordinates <- data.frame(lapply(CircCoordinates, as.character), stringsAsFactors=FALSE)
    rownames(CircCoordinates) <- rownames.circCoordinates  
  }
  
  groupindicator1 <- factor(groupindicator1,levels=unique(groupindicator1))
  groupindicator2 <- factor(groupindicator2,levels=unique(groupindicator2))
  
  # Get gene name, if no annotation, output NULL
  if (is.character(plotrow)){
    if ( ! plotrow %in% rownames(CircCoordinates) ){
      stop("Specified 'plotrow' not found.")
    }
  }else{
    if ( is.numeric(plotrow) ){
      if ( ! plotrow %in% 1:nrow(CircCoordinates) ){
        stop("Specified 'plotrow' not found.")
      }
    }else{
      stop("Specified plotrow should be ONE rowname or ONE rownumber.")
    }
  }
  # Choose your own column containing the gene name using gene_column. The genename will be displayed in the plot title if available
  if (missing(gene_column)){
    genename = NULL
  }else{
    genename <- as.character(CircCoordinates[plotrow,gene_column])
    if (genename == '.'){
      genename = NULL
    }
  }
  if(twolevel){
    plotdat <- summarySE( data.frame(Ratio=as.numeric(Circ[plotrow,-circle_description])/(as.numeric(Linear[plotrow,-circle_description])+as.numeric(Circ[plotrow,-circle_description])),
                                    groupindicator1,
                                    groupindicator2),
                         measurevar='Ratio',groupvars=c('groupindicator1','groupindicator2') )
  }else{
    plotdat <- summarySE( data.frame(Ratio=as.numeric(Circ[plotrow,-circle_description])/(as.numeric(Linear[plotrow,-circle_description])+as.numeric(Circ[plotrow,-circle_description])),
                                     groupindicator1),
                                     measurevar='Ratio',groupvars=c('groupindicator1') )
  }
  #View(plotdat)
  Q <- ggplot(plotdat, aes(x=groupindicator1, y=Ratio)) +
       theme_bw()+
       theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1))+
       theme(text=element_text(size=size))+
       labs(list(title=paste(toString(Circ[plotrow,circle_description]),genename,sep=" "),x=x,y=y))+
       geom_bar(stat="identity",aes(fill=groupindicator1))+
       geom_errorbar(aes(ymin=Ratio-se, ymax=Ratio+se), width=.1 )+   # Width of the error bars
       scale_fill_discrete(name=lab_legend)
  if(twolevel){
    Q <- Q + facet_wrap( ~ groupindicator2,ncol=ncol )
  }

  print(Q)
}

