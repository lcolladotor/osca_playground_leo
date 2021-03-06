# Notes for 04-normalization.R
# --------------------------------------
## Copy code from https://github.com/lcolladotor/osca_LIIGH_UNAM_2020/blob/master/04-normalization.R

## ----all_code, cache=TRUE--------------------------------------------------------------------------------------------
library('scRNAseq')
sce.zeisel <- ZeiselBrainData(ensembl = TRUE)

# Quality control
library('scater')
is.mito <- which(rowData(sce.zeisel)$featureType == "mito")
stats <- perCellQCMetrics(sce.zeisel, subsets = list(Mt = is.mito))
qc <-
    quickPerCellQC(stats,
        percent_subsets = c("altexps_ERCC_percent", "subsets_Mt_percent"))
sce.zeisel <- sce.zeisel[, !qc$discard]


## ----all_code2, cache=TRUE, dependson='all_code'---------------------------------------------------------------------
# Library size factors
lib.sf.zeisel <- librarySizeFactors(sce.zeisel)
class(lib.sf.zeisel)
length(lib.sf.zeisel)
head(lib.sf.zeisel)
mean(lib.sf.zeisel)

# Examine distribution of size factors
summary(lib.sf.zeisel)
hist(log10(lib.sf.zeisel), xlab = "Log10[Size factor]", col = "grey80")

class(counts(sce.zeisel))
dim(counts(sce.zeisel))
?colSums

ls.zeisel <- colSums(counts(sce.zeisel))
class(ls.zeisel)
length(ls.zeisel)

plot(
    ls.zeisel,
    lib.sf.zeisel,
    log = "xy",
    xlab = "Library size",
    ylab = "Size factor"
)


## ----exercise_solution, cache=TRUE, dependson='all_code'-------------------------------------------------------------

## No, they are not identical
identical(ls.zeisel, lib.sf.zeisel)
all(ls.zeisel == lib.sf.zeisel) # Brenda

## Are they proportional?
# a * b = c ## Find b
# a * b / a = c / a
# a / a * b = c / a
# 1 * b = c / a
# b = c / a
table(lib.sf.zeisel / ls.zeisel)
# length(unique(lib.sf.zeisel / ls.zeisel)) ## numerical discrepancies
table(ls.zeisel / lib.sf.zeisel)


## First compute the sums
zeisel_sums <- colSums(counts(sce.zeisel))
identical(zeisel_sums, ls.zeisel)

## Next, make them have unity mean
mean(zeisel_sums)
zeisel_size_factors <- zeisel_sums/mean(zeisel_sums)
identical(zeisel_size_factors, lib.sf.zeisel)


## ----all_code3, cache=TRUE, dependson='all_code2'--------------------------------------------------------------------
# Normalization by convolution

library('scran')
# Pre-clustering
set.seed(100)
clust.zeisel <- quickCluster(sce.zeisel)
# Compute deconvolution size factors
deconv.sf.zeisel <-
    calculateSumFactors(sce.zeisel, clusters = clust.zeisel, min.mean = 0.1)

table(clust.zeisel)
class(deconv.sf.zeisel)
length(deconv.sf.zeisel)

# Examine distribution of size factors
summary(deconv.sf.zeisel)
hist(log10(deconv.sf.zeisel), xlab = "Log10[Size factor]",
    col = "grey80")
plot(
    ls.zeisel,
    deconv.sf.zeisel,
    log = "xy",
    xlab = "Library size",
    ylab = "Size factor"
)

## Solutions

### How many quick clusters did we get?
## Answer: 12
class(clust.zeisel)
summary(clust.zeisel) ## Isaac
table(clust.zeisel)

### How many cells per quick cluster did we get?
## Answer: from 113 to 325
sort(table(clust.zeisel))
summary(as.vector(table(clust.zeisel)))

### How many quick clusters will we get if we set the minimum size to 200? Use 100 as the seed.
## Answer: 10
set.seed(100)
sort(table(quickCluster(sce.zeisel, min.size = 200)))
## Remember to set the seed before running any function
## that has a random component.

### How many lines do you see?
## Answer: More than one, but I don't know how many

## ----all_code4, cache=TRUE, dependson='all_code3'--------------------------------------------------------------------
# Library size factors vs. convolution size factors

# Colouring points using the supplied cell-types
plot(
    lib.sf.zeisel,
    deconv.sf.zeisel,
    xlab = "Library size factor",
    ylab = "Deconvolution size factor",
    log = 'xy',
    pch = 16,
    col = as.integer(factor(sce.zeisel$level1class))
)
abline(a = 0, b = 1, col = "red")


###
sce.zeisel <- logNormCounts(sce.zeisel)
assayNames(sce.zeisel)

## ----'reproducibility', cache = TRUE, dependson=knitr::all_labels()--------------------------------------------------
options(width = 120)
sessioninfo::session_info()

## Notes

