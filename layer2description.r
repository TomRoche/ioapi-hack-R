#!/usr/bin/env Rscript

# layer2description.csv maps our layer#s into crop descriptions.
# Read that into a more-useful RDS.

input.dir <- "."
input.processor <- "tlrRutilities.r"
source(sprintf('%s/%s', input.dir, input.processor))

input.fn <- "layer2description.csv"
input.fp <- sprintf('%s/%s', input.dir, input.fn)
# escape the dot! for use in naming output
prefix <- unlist(strsplit(input.fn, '\\.'))[1]
# TODO: find/use R path ops ~= basename, dirname
output.dir <- input.dir
output.fp <- sprintf('%s/%s.rds', output.dir, prefix)
# number of header lines (to ignore)
# TODO: just ignore comments!
n.header.lines <- 1
# number of used fields in each CSV line == |layer#, description|
n.fields <- 2
n.additional.fields <- 0
n.data.fields <- n.fields + n.additional.fields

# types of fields in each CSV line:
# see help(scan):Details
list.line.types <- list("A", "A")

l2d.env <-
  csv.read.to.environment(input.fp, n.header.lines, list.line.types)
saveRDS(object=l2d.env, file=output.fp)
system(sprintf('ls -alh %s\n', output.fp))
