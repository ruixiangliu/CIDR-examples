## install CIDR from https://github.com/VCCRI/CIDR
library(cidr)

## Read in data 
## Tag tables were downloaded from the data repository NCBI Gene Expression Omnibus (GSE67835)
## Tag tables were combined into one table and hybrid cells have been excluded.
brainTags <- read.csv("brainTags.csv")
rownames(brainTags) <- brainTags[,1]
brainTags <- brainTags[,-1]

## Read in annotation
info <- read.csv("SraRunTable.txt",sep="\t")
cellType <- info$cell_type_s[match(colnames(brainTags),info$Sample_Name_s)]
cellType <- factor(cellType)
types <- levels(cellType)

## Assign each cell type a color
scols <- c("red","blue","green","brown","pink","purple","darkgreen","grey")
cols <- rep(NA,length(cellType))
for (i in 1:length(cols)){
  cols[i] <- scols[which(types==cellType[i])]
}

## Clearer cell type names
types[3] <- "fetal quiescent neurons"
types[4] <- "fetal replicating neurons"
types[8] <- "oligodendrocyte precursor cells"

##  Standard principal component analysis using prcomp
priorTPM <- 1
brain10 <- brainTags[rowSums(brainTags)>10,]
brain10_lcpm <- log2(t(t(brain10)/colSums(brain10))*1000000+priorTPM)
pca <- prcomp(t(brain10_lcpm))
plot.new()
legend("center", legend=types, col=scols, pch=1)
plot(pca$x[,c(1,2)], col=cols, pch=1,
     xlab="PC1", ylab="PC2",
     main="Principal Component Analysis (prcomp)")

#### CIDR ######
################
scBrain <- scDataConstructor(as.matrix(brainTags))
scBrain <- determineDropoutCandidates(scBrain)
scBrain <- wThreshold(scBrain)
scBrain <- scDissim(scBrain)
scBrain <- scPCA(scBrain)
scBrain <- nPC(scBrain)
nCluster(scBrain)
scBrain <- scCluster(scBrain)

## Two dimensional visualization plot output by CIDR
## Different colors denote the cell types annotated by the human brain single-cell RNA-Seq study
## Different plotting symbols denote the clusters output by CIDR
plot.new()
legend("center", legend=types, col=scols, pch=15)
plot(scBrain@PC[,c(1,2)], col=cols, pch=scBrain@clusters, 
     main="CIDR", xlab="PC1", ylab="PC2")

## Use Adjusted Rand Index to measure the accuracy of CIDR clustering
ARI_CIDR <- adjustedRandIndex(scBrain@clusters,cols)
ARI_CIDR
## 0.8977449

## This section shows how to alter the parameters of CIDR
scBrain@nPC
## The default number of principal coordinates used in clustering is 4
## Use 6 instead of 4 principal coordinates in clustering
scBrain <- scCluster(scBrain, nPC=6)

plot(scBrain@PC[,c(1,2)],
     col=cols, pch=scBrain@clusters, main="CIDR (nPC=6)", 
     xlab="PC1", ylab="PC2")

ARI_CIDR <- adjustedRandIndex(scBrain@clusters,cols)
ARI_CIDR
## 0.9068305

scBrain@nCluster
## The default number of clusters is 6
## Examine the Calinski-Harabasz Index versus Number of Clusters plot
nCluster(scBrain)
## Try 10 clusters
scBrain <- scCluster(scBrain, nCluster=10)

plot(scBrain@PC[,c(1,2)], col=cols, pch=scBrain@clusters, 
     main="CIDR (nPC=6, nCluster=10)", xlab="PC1", ylab="PC2")

ARI_CIDR <- adjustedRandIndex(scBrain@clusters,cols)
ARI_CIDR
## 0.7294235

## Use a different imputation weighting threshold
scBrain@wThreshold <- 8
scBrain <- scDissim(scBrain)
scBrain <- scPCA(scBrain)
scBrain <- nPC(scBrain)
scBrain <- scCluster(scBrain)

plot(scBrain@PC[,c(1,2)], col=cols, pch=scBrain@clusters, 
     main="CIDR (wThreshold=8)", xlab="PC1", ylab="PC2")

ARI_CIDR <- adjustedRandIndex(scBrain@clusters,cols)
ARI_CIDR
## 0.8101352
