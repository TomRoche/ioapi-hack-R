#!/usr/bin/env Rscript

# Read a BELD CSV file, write a more-useful object as RDS

input.dir <- "."
source(sprintf('%s/%s', input.dir, 'beldRead.r'))

# BELD filename
input.fn <- "epic_site_crops_0529_USA_2Ellen.csv" # improper crop IDs are ignored
# escape the dot! for use in naming output
prefix <- unlist(strsplit(input.fn, '\\.'))[1]
# path to BELD file
# TODO: with R path ops
input.fp <- sprintf('%s/%s', input.dir, input.fn)

# TODO: find R path ops ~= basename, dirname
output.dir <- input.dir
output.fp <- sprintf('%s/%s.rds', output.dir, prefix)
# TODO: read me from netCDF file (e.g., 5yravg.test.nc)
#                 COL, ROW, LAY
datavar.dims <- c(459, 299, 42)

# number of header lines (to ignore)
n.header.lines <- 2

# number of used fields in each CSV line == the number of EPIC layers, plus n.additional.fields
datavar.layers.n <- datavar.dims[3]
n.additional.fields <- 1
n.data.fields <- datavar.layers.n + n.additional.fields

# types of fields in each CSV line (ignoring string @ end)
# '0' signifies type=numeric
# fail! list of length=2
# list.line.types <- list(rep.int(0, times=n.data.fields), NULL)
# instead do with emacs (TODO: do with R!)
list.line.types <- list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL)

# saveRDS(object=beld.read(input.fp, datavar.dims), file=output.fp)
beld.array <- beld.read(input.fp, datavar.dims, n.header.lines, n.data.fields, list.line.types)
saveRDS(object=beld.array, file=output.fp)
system(sprintf('ls -alh %s\n', output.fp))
