#!/usr/bin/env Rscript

# Read a BELD CSV file, write a more-useful object as RDS
source('./beldRead.r')

input.dir <- "."
# BELD filename
input.fn <- "BELD4crops_12km_6_13_11.csv" # improper crop IDs are ignored
# path to BELD file
# TODO: with R path ops
input.fp <- sprintf('%s/%s', input.dir, input.fn)
# escape the dot! for use below
prefix <- unlist(strsplit(input.fn, '\\.'))[1]

# TODO: find R path ops ~= basename, dirname
output.dir <- input.dir
# how to interpret gridcell ID in CSV file: see beldRead.r:int2gridcell
# mode <- 'row'
# mode <- 'col'
mode <- 'LimeiRan'
output.fp <- sprintf('%s/%s_.rds', output.dir, prefix, mode)
# TODO: read me from netCDF file (e.g., 5yravg.test.nc)
#                 COL, ROW, LAY
datavar.dims <- c(459, 299, 42)

# saveRDS(object=beld.read(input.fp, datavar.dims), file=output.fp)
beld.array <- beld.read(input.fp, datavar.dims)
saveRDS(object=beld.array, file=output.fp)
system(sprintf('ls -alh %s\n', output.fp))
