# Notes for 02-data-infrastructure-and-import.R
# --------------------------------------
## Copy code from https://github.com/lcolladotor/osca_LIIGH_UNAM_2020/blob/master/02-data-infrastructure-and-import.R

## ----all_code, cache=TRUE--------------------------------------------------------------------------------------------
library('scRNAseq')
sce.416b <- LunSpikeInData(which = "416b")

# Load the SingleCellExperiment package
library('SingleCellExperiment')
# Extract the count matrix from the 416b dataset
counts.416b <- counts(sce.416b)
# Construct a new SCE from the counts matrix
sce <- SingleCellExperiment(assays = list(counts = counts.416b))

# Inspect the object we just created
sce

## How big is it?
pryr::object_size(sce)

# Access the counts matrix from the assays slot
# WARNING: This will flood RStudio with output!

# 1. The general method
assay(sce, "counts")[1:6, 1:3]
# 2. The special method for the assay named "counts"
counts(sce)[1:6, 1:3]

sce <- scater::logNormCounts(sce)
# Inspect the object we just updated
sce

## How big is it?
pryr::object_size(sce)

# 1. The general method
assay(sce, "logcounts")[1:6, 1:3]
# 2. The special method for the assay named "logcounts"
logcounts(sce)[1:6, 1:3]

# assign a new entry to assays slot
assay(sce, "counts_100") <- assay(sce, "counts") + 100
# List the assays in the object
assays(sce)
assayNames(sce)

## How big is it?
pryr::object_size(sce)

# Extract the sample metadata from the 416b dataset
colData.416b <- colData(sce.416b)
# Add some of the sample metadata to our SCE
colData(sce) <- colData.416b[, c("phenotype", "block")]
# Inspect the object we just updated
sce
# Access the sample metadata from our SCE
colData(sce)
# Access a specific column of sample metadata from our SCE
table(sce$block)

# Example of function that adds extra fields to colData
sce <- scater::addPerCellQC(sce.416b)
# Access the sample metadata from our updated SCE
colData(sce)

# Inspect the object we just updated
sce

## How big is it?
pryr::object_size(sce)

## Add the lognorm counts again
sce <- scater::logNormCounts(sce)

## How big is it?
pryr::object_size(sce)

# E.g., subset data to just wild type cells
# Remember, cells are columns of the SCE
x <- sce$phenotype == "wild type phenotype"
class(x)
table(x)
table(sce$phenotype)

sce[, sce$phenotype == "wild type phenotype"]

# Access the feature metadata from our SCE
# It's currently empty!
rowData(sce)

# Example of function that adds extra fields to rowData
sce <- scater::addPerFeatureQC(sce)
# Access the feature metadata from our updated SCE
rowData(sce)

## How big is it?
pryr::object_size(sce)


# Download the relevant Ensembl annotation database
# using AnnotationHub resources
library('AnnotationHub')
ah <- AnnotationHub()
query(ah, c("Mus musculus", "Ensembl", "v97"))

# Annotate each gene with its chromosome location
#download_data <- function(ah, id) { access_data(sh, id) }
ensdb <- ah[["AH73905"]]
chromosome <- mapIds(ensdb,
    keys = rownames(sce),
    keytype = "GENEID",
    column = "SEQNAME")

class(chromosome)
rowData(sce)$chromosome <- chromosome

# Access the feature metadata from our updated SCE
rowData(sce)

## How big is it?
pryr::object_size(sce)

# E.g., subset data to just genes on chromosome 3
# NOTE: which() needed to cope with NA chromosome names
x <- rowData(sce)$chromosome
table(is.na(x))
y <- x == '3'
table(is.na(y))
table(is.na(which(y)))
head(which(y))
sce[which(rowData(sce)$chromosome == "3"), ]

# Access the metadata from our SCE
# It's currently empty!
metadata(sce)

# The metadata slot is Vegas - anything goes
metadata(sce) <- list(favourite_genes = c("Shh", "Nck1", "Diablo"),
    analyst = c("Pete"))

# Access the metadata from our updated SCE
metadata(sce)

# E.g., add the PCA of logcounts
# NOTE: We'll learn more about PCA later
sce <- scater::runPCA(sce)
# Inspect the object we just updated
sce
# Access the PCA matrix from the reducedDims slot
reducedDim(sce, "PCA")[1:6, 1:3]

# E.g., add a t-SNE representation of logcounts
# NOTE: We'll learn more about t-SNE later
sce <- scater::runTSNE(sce)
# Inspect the object we just updated
sce
# Access the t-SNE matrix from the reducedDims slot
head(reducedDim(sce, "TSNE"))

# E.g., add a 'manual' UMAP representation of logcounts
# NOTE: We'll learn more about UMAP later and a
# 		  simpler way to compute it.
u <- uwot::umap(t(logcounts(sce)), n_components = 2)
# Add the UMAP matrix to the reducedDims slot
# Access the UMAP matrix from the reducedDims slot
reducedDim(sce, "UMAP") <- u

# List the dimensionality reduction results stored in # the object
reducedDims(sce)

# Extract the ERCC SCE from the 416b dataset
ercc.sce.416b <- altExp(sce.416b, "ERCC")
# Inspect the ERCC SCE
ercc.sce.416b

# Add the ERCC SCE as an alternative experiment to our SCE
altExp(sce, "ERCC") <- ercc.sce.416b
# Inspect the object we just updated
sce

## How big is it?
pryr::object_size(sce)

# List the alternative experiments stored in the object
altExps(sce)

# Subsetting the SCE by sample also subsets the
# alternative experiments
sce.subset <- sce[, 1:10]
ncol(sce.subset)
ncol(altExp(sce.subset))

## How big is it?
pryr::object_size(sce.subset)

# Extract existing size factors (these were added
# when we ran scater::logNormCounts(sce))
head(sizeFactors(sce))

# 'Automatically' replace size factors
sce <- scran::computeSumFactors(sce)
head(sizeFactors(sce))

# 'Manually' replace size factors
sizeFactors(sce) <- scater::librarySizeFactors(sce)
head(sizeFactors(sce))

## Which function defines the sce class?
## SingleCellExperiment::SingleCellExperiment

## What are the minimum type of tables an sce object contains?
## info genes: rowData()
## number of reads overlapping each gene for each cell: assays
## info about cells: colData()
## optionally: PCA, TSNE (reducedDims), alternative experiments (altExp),
## random info (metadata)

## Where are the colnames(sce) used?
head(colnames(sce))
## column names of the assays + rownames of the colData
# identical(colnames(assays(sce, 'counts')), rownames(colData(sce))) ## colnames(assays(sce, 'counts')) is NULL in this example =(
identical(rownames(reducedDim(sce, 'PCA')), rownames(colData(sce)))

## Similarly, where are the rownames(sce) used?
head(rownames(sce))
## rownames(assays(sce, 'counts'))
head(rownames(rowData(sce)))

## How many principal components did we compute?
reducedDimNames(sce)
dim(reducedDim(sce, 'TSNE'))
dim(reducedDim(sce, 'PCA'))
dim(sce)
head(reducedDim(sce, 'PCA'))
## 50

## Which three chromosomes have the highest mean gene expression?
rowData(sce)
sort(with(rowData(sce), tapply(mean, chromosome, base::mean)), decreasing = TRUE)
sort(tapply(rowData(sce)$mean, rowData(sce)$chromosome, base::mean),
    decreasing = TRUE)

## ----ercc_exercise, cache = TRUE, dependson='all_code'---------------------------------------------------------------
## Read the data from the web
ercc_info <-
    read.delim(
        'https://tools.thermofisher.com/content/sfs/manuals/cms_095046.txt',
        # as.is = TRUE,
        row.names = 2,
        check.names = FALSE,
        stringsAsFactors = FALSE
    )
dim(ercc_info)
dim(sce) # 192 cells
dim(altExp(sce, "ERCC")) # 92 ERCC sequences for our 192 cells

head(rownames(ercc_info))
head(rownames(altExp(sce, "ERCC"))) ## use as reference

## Match the ERCC data
m <- match(rownames(altExp(sce, "ERCC")), rownames(ercc_info))

## Check that it worked
table(is.na(m)) ## all should be FALSE
stopifnot(all(!is.na(m)))
if(!all(!is.na(m))) {
    stop("Hay al menos un NA!")
}

## Align the table from the web
ercc_info <- ercc_info[m, ]

## Check that it all worked
stopifnot(identical(rownames(altExp(sce, "ERCC")), rownames(ercc_info)))

## Normalize the ERCC counts
#altExp(sce, "ERCC") <- scater::logNormCounts(altExp(sce, "ERCC"))

i <- 1
plot(ercc_info[, "concentration in Mix 1 (attomoles/ul)"]  ~
        counts(altExp(sce, "ERCC"))[, i]
)


plot(ercc_info[, "concentration in Mix 1 (attomoles/ul)"]  ~
        counts(altExp(sce, "ERCC"))[, i],
    xlab = 'Observed ERCC',
    ylab = 'Expected ERCC'
)


plot(log(ercc_info[, "concentration in Mix 1 (attomoles/ul)"])  ~
        log(counts(altExp(sce, "ERCC"))[, i]),
    xlab = 'Observed ERCC',
    ylab = 'Expected ERCC'
)



abline(0, 1, lty = 2, col = 'red')


## ----ercc_solution_plots, cache = TRUE, dependson='ercc_exercise'----------------------------------------------------

xlimits <- log2(c(min(counts(altExp(
    sce, "ERCC"
))), max(counts(altExp(
    sce, "ERCC"
)))) + 1)

for (i in seq_len(2)) {
    plot(
        log2(10 * ercc_info[, "concentration in Mix 1 (attomoles/ul)"] + 1) ~
            log2(counts(altExp(sce, "ERCC"))[, i] +
                    1),
        xlab = "log2 counts + 1",
        ylab = "Mix 1: log2(10 * Concentration + 1)",
        main = colnames(altExp(sce, "ERCC"))[i],
        xlim = xlimits
    )
    abline(0, 1, lty = 2, col = 'red')
}




pdf('ERCC_example.pdf')
for (i in seq_len(ncol(sce))) {
    message(paste(Sys.time(), 'plotting cell', i))
    plot(
        log2(10 * ercc_info[, "concentration in Mix 1 (attomoles/ul)"] + 1) ~
            log2(counts(altExp(sce, "ERCC"))[, i] +
                    1),
        xlab = "log2 counts + 1",
        ylab = "Mix 1: log2(10 * Concentration + 1)",
        main = colnames(altExp(sce, "ERCC"))[i],
        xlim = xlimits
    )
    abline(0, 1, lty = 2, col = 'red')
}
dev.off()

## ggplot2 version
library('ggplot2')
library('cowplot')

plot_list <- lapply(seq_len(ncol(sce)), function(i) {
    message(paste(Sys.time(), 'plotting cell', i))
    df <- data.frame(
        x = log2(counts(altExp(sce, "ERCC"))[, i] +
                1),
        y = log2(10 * ercc_info[, "concentration in Mix 1 (attomoles/ul)"] + 1),
        stringsAsFactors = FALSE
    )
    ggplot(df, aes(x = x, y = y)) + geom_point() +
        xlab("log2 counts + 1") +
        ylab("Mix 1: log2(10 * Concentration + 1)") +
        xlim(xlimits) +
        geom_abline(
            slope = 1,
            intercept = 0,
            linetype = 2,
            color = 'red'
        ) +
        ggtitle(colnames(sce)[i]) +
        theme_bw(base_size = 12)
})
pdf(
    'ERCC_example_ggplot2_version.pdf',
    useDingbats = FALSE,
    width = 10 * 5,
    height = 20 * 5
)
cowplot::plot_grid(plotlist = plot_list,
    ncol = 10)
dev.off()


## ----all_code_part2, cache=TRUE--------------------------------------------------------------------------------------
# Download example data processed with CellRanger
# Aside: Using BiocFileCache means we only download the
#        data once
library('BiocFileCache')
bfc <- BiocFileCache()
pbmc.url <-
    paste0(
        "http://cf.10xgenomics.com/samples/cell-vdj/",
        "3.1.0/vdj_v1_hs_pbmc3/",
        "vdj_v1_hs_pbmc3_filtered_feature_bc_matrix.tar.gz"
    )
pbmc.data <- bfcrpath(bfc, pbmc.url)

# Extract the files to a temporary location
untar(pbmc.data, exdir = tempdir())

# List the files we downloaded and extracted
# These files are typically CellRanger outputs
pbmc.dir <- file.path(tempdir(),
    "filtered_feature_bc_matrix")
list.files(pbmc.dir)

# Import the data as a SingleCellExperiment
library('DropletUtils')
sce.pbmc <- read10xCounts(pbmc.dir)
# Inspect the object we just constructed
sce.pbmc

## How big is it?
pryr::object_size(sce.pbmc)

# Store the CITE-seq data in an alternative experiment
sce.pbmc <- splitAltExps(sce.pbmc, rowData(sce.pbmc)$Type)
# Inspect the object we just updated
sce.pbmc

## How big is it?
pryr::object_size(sce.pbmc)

# Download example data processed with scPipe
library('BiocFileCache')
bfc <- BiocFileCache()
sis_seq.url <-
    "https://github.com/LuyiTian/SIS-seq_script/archive/master.zip"
sis_seq.data <- bfcrpath(bfc, sis_seq.url)

# Extract the files to a temporary location
unzip(sis_seq.data, exdir = tempdir())

# List (some of) the files we downloaded and extracted
# These files are typical scPipe outputs
sis_seq.dir <- file.path(tempdir(),
    "SIS-seq_script-master",
    "data",
    "BcorKO_scRNAseq",
    "RPI10")
list.files(sis_seq.dir)

# Import the data as a SingleCellExperiment
library('scPipe')
sce.sis_seq <- create_sce_by_dir(sis_seq.dir)
# Inspect the object we just constructed
sce.sis_seq

## How big is it?
pryr::object_size(sce.sis_seq)

# Download example bunch o' files dataset
library('BiocFileCache')
bfc <- BiocFileCache()
lun_counts.url <-
    paste0(
        "https://www.ebi.ac.uk/arrayexpress/files/",
        "E-MTAB-5522/E-MTAB-5522.processed.1.zip"
    )
lun_counts.data <- bfcrpath(bfc, lun_counts.url)
lun_coldata.url <-
    paste0("https://www.ebi.ac.uk/arrayexpress/files/",
        "E-MTAB-5522/E-MTAB-5522.sdrf.txt")
lun_coldata.data <- bfcrpath(bfc, lun_coldata.url)

# Extract the counts files to a temporary location
lun_counts.dir <- tempfile("lun_counts.")
unzip(lun_counts.data, exdir = lun_counts.dir)

# List the files we downloaded and extracted
list.files(lun_counts.dir)

# Import the count matrix (for 1 plate)
lun.counts <- read.delim(
    file.path(lun_counts.dir, "counts_Calero_20160113.tsv"),
    header = TRUE,
    row.names = 1,
    check.names = FALSE
)
# Store the gene lengths for later
gene.lengths <- lun.counts$Length
# Convert the gene counts to a matrix
lun.counts <- as.matrix(lun.counts[, -1])

# Import the sample metadata
lun.coldata <- read.delim(lun_coldata.data,
    check.names = FALSE,
    stringsAsFactors = FALSE)
library('S4Vectors')
lun.coldata <- as(lun.coldata, "DataFrame")

# Match up the sample metadata to the counts matrix
m <- match(colnames(lun.counts),
    lun.coldata$`Source Name`)
lun.coldata <- lun.coldata[m,]

# Construct the feature metadata
lun.rowdata <- DataFrame(Length = gene.lengths)

# Construct the SingleCellExperiment
lun.sce <- SingleCellExperiment(
    assays = list(assays = lun.counts),
    colData = lun.coldata,
    rowData = lun.rowdata
)
# Inspect the object we just constructed
lun.sce

## How big is it?
pryr::object_size(lun.sce)


## ----'reproducibility', cache = TRUE, dependson=knitr::all_labels()--------------------------------------------------
options(width = 120)
sessioninfo::session_info()


## Notes

