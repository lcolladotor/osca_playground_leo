# Notes for 03-quality-control.R
# --------------------------------------
## Copy code from https://github.com/lcolladotor/osca_LIIGH_UNAM_2020/blob/master/03-quality-control.R

## ----all_code, cache=TRUE--------------------------------------------------------------------------------------------
## Data
library('scRNAseq')
sce.416b <- LunSpikeInData(which = "416b")
sce.416b$block <- factor(sce.416b$block)

# Download the relevant Ensembl annotation database
# using AnnotationHub resources
library('AnnotationHub')
ah <- AnnotationHub()
query(ah, c("Mus musculus", "Ensembl", "v97"))
# Annotate each gene with its chromosome location
ens.mm.v97 <- ah[["AH73905"]]
location <- mapIds(
    ens.mm.v97,
    keys = rownames(sce.416b),
    keytype = "GENEID",
    column = "SEQNAME"
)
# Identify the mitochondrial genes
is.mito <- which(location == "MT")

library('scater')

## sums of altExp are calculated
x <- colSums(counts(altExp(sce.416b, 'ERCC')))
head(x)
x_genes <- colSums(counts(sce.416b))
head(x_genes)

sce.416b <- addPerCellQC(sce.416b,
    subsets = list(Mito = is.mito))


## ----qc_metrics, cache=TRUE, dependson='all_code'--------------------------------------------------------------------
plotColData(sce.416b, x = "block", y = "detected")

plotColData(sce.416b, x = "block", y = "detected") +
    scale_y_log10()

plotColData(sce.416b,
    x = "block",
    y = "detected",
    other_fields = "phenotype") +
    scale_y_log10() +
    facet_wrap( ~ phenotype)


## ----all_code_part2, cache = TRUE, dependson='all_code'--------------------------------------------------------------
# Example thresholds
qc.lib <- sce.416b$sum < 100000
qc.nexprs <- sce.416b$detected < 5000
qc.spike <- sce.416b$altexps_ERCC_percent > 10
qc.mito <- sce.416b$subsets_Mito_percent > 10
discard <- qc.lib | qc.nexprs | qc.spike | qc.mito

class(qc.lib)
addmargins(table('lib' = qc.lib, 'nexprs' = qc.nexprs, 'spike' = qc.spike, 'mito' = qc.mito))

addmargins(table('lib' = qc.lib, 'spike' = qc.spike, 'mito' = qc.mito))


addmargins(table('lib' = qc.lib, 'other filters' = qc.nexprs | qc.spike | qc.mito))

which(qc.lib & (qc.nexprs | qc.spike | qc.mito))
which(qc.lib & !(qc.nexprs | qc.spike | qc.mito))

intersect(which(qc.lib), which(qc.nexprs | qc.spike | qc.mito))

# Summarize the number of cells removed for each reason
DataFrame(
    LibSize = sum(qc.lib),
    NExprs = sum(qc.nexprs),
    SpikeProp = sum(qc.spike),
    MitoProp = sum(qc.mito),
    Total = sum(discard)
)

plotColData(sce.416b, x = "block", y = "sum")
plotColData(sce.416b, x = "block", y = "sum") + scale_y_log10()

qc.lib2 <- isOutlier(sce.416b$sum, log = TRUE, type = "lower")
qc.nexprs2 <- isOutlier(sce.416b$detected, log = TRUE,
    type = "lower")
qc.spike2 <- isOutlier(sce.416b$altexps_ERCC_percent,
    type = "higher")
qc.mito2 <- isOutlier(sce.416b$subsets_Mito_percent,
    type = "higher")
discard2 <- qc.lib2 | qc.nexprs2 | qc.spike2 | qc.mito2

# Extract the thresholds
attr(qc.lib2, "thresholds")
attr(qc.nexprs2, "thresholds")
# Summarize the number of cells removed for each reason.
DataFrame(
    LibSize = sum(qc.lib2),
    NExprs = sum(qc.nexprs2),
    SpikeProp = sum(qc.spike2),
    MitoProp = sum(qc.mito2),
    Total = sum(discard2)
)

## More checks
plotColData(sce.416b,
    x = "block",
    y = "detected",
    other_fields = "phenotype") +
    scale_y_log10() +
    facet_wrap( ~ phenotype)

batch <- paste0(sce.416b$phenotype, "-", sce.416b$block)
qc.lib3 <- isOutlier(sce.416b$sum,
    log = TRUE,
    type = "lower",
    batch = batch)
qc.nexprs3 <- isOutlier(sce.416b$detected,
    log = TRUE,
    type = "lower",
    batch = batch)
qc.spike3 <- isOutlier(sce.416b$altexps_ERCC_percent,
    type = "higher",
    batch = batch)
qc.mito3 <- isOutlier(sce.416b$subsets_Mito_percent,
    type = "higher",
    batch = batch)
discard3 <- qc.lib3 | qc.nexprs3 | qc.spike3 | qc.mito3

sce.416b$discard3 <- discard3
plotColData(sce.416b,
    x = "block",
    y = "detected",
    colour_by = 'discard3',
    other_fields = "phenotype") +
    scale_y_log10() +
    facet_wrap( ~ phenotype)

# Extract the thresholds
attr(qc.lib3, "thresholds")
attr(qc.nexprs3, "thresholds")

# Summarize the number of cells removed for each reason
DataFrame(
    LibSize = sum(qc.lib3),
    NExprs = sum(qc.nexprs3),
    SpikeProp = sum(qc.spike3),
    MitoProp = sum(qc.mito3),
    Total = sum(discard3)
)


## ----use_case, cache=TRUE, dependson= c('all_code', 'all_code_part2')------------------------------------------------
sce.grun <- GrunPancreasData()
sce.grun <- addPerCellQC(sce.grun)

plotColData(sce.grun, x = "donor", y = "altexps_ERCC_percent")

hist(sce.grun$altexps_ERCC_percent[sce.grun$donor == 'D10'],
    breaks = 100,
    col = 'light blue')

hist(sce.grun$altexps_ERCC_percent[sce.grun$donor == 'D2'],
    breaks = 100,
    col = 'light blue')

discard.ercc <- isOutlier(sce.grun$altexps_ERCC_percent,
    type = "higher",
    batch = sce.grun$donor)
discard.ercc2 <- isOutlier(
    sce.grun$altexps_ERCC_percent,
    type = "higher",
    batch = sce.grun$donor,
    subset = sce.grun$donor %in% c("D17", "D2", "D7")
)

## Understanding %in%
class(sce.grun$donor)
length(sce.grun$donor)
dim(sce.grun)
table(sce.grun$donor)

manual_subset <- sce.grun$donor == 'D17' | sce.grun$donor == 'D2' | sce.grun$donor == 'D7'
class(manual_subset)
length(manual_subset)
sum(manual_subset)
480 + 96 + 384

## quicker
# x %in% y
x <- c('a', 'b', 'c', 'ch')
y <- letters
x %in% y
x[x %in% y]
auto_subset <- sce.grun$donor %in% c('D17', 'D2', 'D7')
identical(manual_subset, auto_subset)

plotColData(
    sce.grun,
    x = "donor",
    y = "altexps_ERCC_percent",
    colour_by = data.frame(discard = discard.ercc)
)
plotColData(
    sce.grun,
    x = "donor",
    y = "altexps_ERCC_percent",
    colour_by = data.frame(discard = discard.ercc2)
)

# Add info about which cells are outliers
sce.416b$discard <- discard2

# Look at this plot for each QC metric
plotColData(
    sce.416b,
    x = "block",
    y = "sum",
    colour_by = "discard",
    other_fields = "phenotype"
) +
    facet_wrap( ~ phenotype) +
    scale_y_log10()

# Another useful diagnostic plot
plotColData(
    sce.416b,
    x = "sum",
    y = "subsets_Mito_percent",
    colour_by = "discard",
    other_fields = c("block", "phenotype")
) +
    facet_grid(block ~ phenotype)


## ----use_case_pbmc, cache=TRUE, dependson='all_code'-----------------------------------------------------------------
library('BiocFileCache')
bfc <- BiocFileCache()
raw.path <-
    bfcrpath(
        bfc,
        file.path(
            "http://cf.10xgenomics.com/samples",
            "cell-exp/2.1.0/pbmc4k/pbmc4k_raw_gene_bc_matrices.tar.gz"
        )
    )
untar(raw.path, exdir = file.path(tempdir(), "pbmc4k"))

library('DropletUtils')
library('Matrix')
fname <- file.path(tempdir(), "pbmc4k/raw_gene_bc_matrices/GRCh38")
sce.pbmc <- read10xCounts(fname, col.names = TRUE)

bcrank <- barcodeRanks(counts(sce.pbmc))

# Only showing unique points for plotting speed.
uniq <- !duplicated(bcrank$rank)
plot(
    bcrank$rank[uniq],
    bcrank$total[uniq],
    log = "xy",
    xlab = "Rank",
    ylab = "Total UMI count",
    cex.lab = 1.2
)
abline(h = metadata(bcrank)$inflection,
    col = "darkgreen",
    lty = 2)
abline(h = metadata(bcrank)$knee,
    col = "dodgerblue",
    lty = 2)
legend(
    "bottomleft",
    legend = c("Inflection", "Knee"),
    col = c("darkgreen", "dodgerblue"),
    lty = 2,
    cex = 1.2
)


set.seed(100)
e.out <- emptyDrops(counts(sce.pbmc))

# See ?emptyDrops for an explanation of why there are NA # values.
summary(e.out$FDR <= 0.001)

set.seed(100)
limit <- 100
all.out <-
    emptyDrops(counts(sce.pbmc), lower = limit, test.ambient = TRUE)
# Ideally, this histogram should look close to uniform.
# Large peaks near zero indicate that barcodes with total
# counts below 'lower' are not ambient in origin.
hist(all.out$PValue[all.out$Total <= limit &
        all.out$Total > 0],
    xlab = "P-value",
    main = "",
    col = "grey80")

sce.pbmc <- sce.pbmc[, which(e.out$FDR <= 0.001)]

is.mito <- grep("^MT-", rowData(sce.pbmc)$Symbol)
sce.pmbc <- addPerCellQC(sce.pbmc, subsets = list(MT = is.mito))
discard.mito <-
    isOutlier(sce.pmbc$subsets_MT_percent, type = "higher")
plot(
    sce.pmbc$sum,
    sce.pmbc$subsets_MT_percent,
    log = "x",
    xlab = "Total count",
    ylab = "Mitochondrial %"
)
abline(h = attr(discard.mito, "thresholds")["higher"], col = "red")


## Exercise answers

### Why does emptyDrops() return NA values?

## Below lower & test.ambient = FALSE
## 0 "total" (even with test.ambient = TRUE)
with(all.out, table(
    'NA pvalue' = is.na(PValue),
    'Total is 0?' = Total == 0
))

### Are the p-values the same for e.out and all.out?
## Answers from the group: Yes: 4, No: 6
identical(e.out$PValue, all.out$PValue)

## What if you subset to the non-NA entries?
identical(
    e.out$PValue[!is.na(all.out$FDR)],
    all.out$PValue[!is.na(all.out$FDR)]
)
## false
identical(
    e.out$PValue[!is.na(e.out$FDR)],
    all.out$PValue[!is.na(e.out$FDR)]
)
## true
with(e.out, table(
    'NA pvalue' = is.na(PValue),
    'Total is <= 100' = Total <= 100
))

## We talked about the importance of setting the random seed
## using set.seed() before running any function that has
## a random component. Otherwise your results will not be
## reproducible and you'll never know if they didn't
## reproduce because of the random seed or because some
## other code changed in the function you are running.

## ----marking, cache=TRUE, dependson='use_case'-----------------------------------------------------------------------
# Removing low-quality cells
# Keeping the columns we DON'T want to discard
filtered <- sce.416b[,!discard2]
# Marking low-quality cells
marked <- sce.416b
marked$discard <- discard2


## ----'reproducibility', cache = TRUE, dependson=knitr::all_labels()--------------------------------------------------
options(width = 120)
sessioninfo::session_info()

## Notes

