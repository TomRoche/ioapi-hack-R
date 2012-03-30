#!/usr/bin/env Rscript

# description---------------------------------------------------------

# Inputs (not in argument order)

# 1 The name of a single data variable (datavar) for which to sum

# 2 Path to an "unsummed" input *.nc from EPIC
#   (via, e.g., computeCropSum.sh) with
#   dim(datavar) == [TSTEP, LAY, ROW, COL], where
# * [ROW, COL] is the gridspace
# * one layer per crop, 1 < i.layer <= n.layers.
#   Thus the "crop vector" for that gridcell has length==n.layers.

# 3 Path to a *.rds BELD array (as output by beldToRDS.r) with
#   dim(array) == [LAY, ROW, COL], where
# * [ROW, COL] is the same gridspace as the EPIC datavar
# * one layer per crop, hence ...
# * the "BELD vector" for a gridcell has length==n.layers.

# 4 Path to a "summed" output *.nc from EPIC
#   (via, e.g., computeCropSum.sh) very like the unsummed input, but
# + one new "sum layer" per gridcell, i.layer == n.layers + 1,
#   with (input) values to be overwritten.

# Outputs the summed output EPIC file, containing, in each gridcell,
# a value in [gridcell, i.layer] "summing the emissions" for that gridcell,
# by multiplying each crop's emittivity in that gridcell by
# its share of the land cover on that gridcell (from BELD).

# Procedure:

# 1 Setup

# For each timestep in EPIC file:
#   For each gridcell:

#     2 Determine whether gridcell is "empty," i.e., all its crop layers==NA.
#       If so, write NAs to sum layer. If not:

#     3 Compute sum of products of "BELD vector" and "crop vector,"
#       write to sum layer.

#   4 Plot all layers in timestep.

# 5 Teardown

# code----------------------------------------------------------------

library(ncdf4)
source('./ioapi.r')
source('./tlrRutilities.r')
source('./plotLayersForTimestep.r')

# constants-----------------------------------------------------------

# path to input file
# TODO: get from environment
epic.input.fp <- "./5yravg.DN2unsummed.nc"
# path to output file
# TODO: get from environment
# TODO: delete if exists
epic.output.fp <- "./5yravg.DN2summed.nc"
datavar.name <- "DN2"
# path to serialized BELD array, as produced by beldToRDS
beld.fp <- "./BELD4crops_12km_6_13_11_LimeiRan.rds"

# plot-related vars
plot.layers <- FALSE
# package=grDevices
palette.vec <- c("grey","purple","deepskyblue2","green","yellow","orange","red","brown")
colors <- colorRampPalette(palette.vec)
# used for quantiling legend
probabilities.vec <- seq(0, 1, 1.0/(length(palette.vec) - 1))

# functions-----------------------------------------------------------

# function procedure (copied from above):
# 2 Determine whether gridcell is "empty," i.e., all its crop layers==NA.
#   If so, write NAs to sum layer. If not:
# 3 Compute sum of products of "BELD vector" and "crop vector,"

# Returns list of
# * the payload:
#   list$sum.vec: vector of emissions (sum of products)
# * reporting data mismatches:
#   list$scoreboard.gridcells: where we have crop and BELD data, but sum there == 0
#   list$scoreboard.have.crop.not.beld: mismatches where BELD layer == 0 
#   list$scoreboard.have.beld.not.crop: mismatches where EPIC layer == 0
sum.emissions.for.layers <- function(
  epic.vec, beld.vec, # data
  i.col, i.row,       # for debugging and statistics only
  scoreboard.gridcells,             # for statistics only
  scoreboard.have.crop.not.beld,    # for statistics only
  scoreboard.have.beld.not.crop     # for statistics only
) {
# start debugging
# epic.vec <- epic.input.vec # if self-stepping through source
#  cat(sprintf('class(epic.vec)==%s\n', class(epic.vec)))
#  cat(sprintf('length(epic.vec)==%i\n', length(epic.vec)))
#  print('dim(epic.vec)==') ; print(dim(epic.vec))
#  cat(sprintf('class(beld.vec)==%s\n', class(beld.vec)))
#  cat(sprintf('length(beld.vec)==%i\n', length(beld.vec)))
#  print('dim(beld.vec)==') ; print(dim(beld.vec))
#   end debugging

  i.sum <- length(epic.vec)
  # EPIC input now has *2* extra layers: one for BELD, and one for sum
  crops.vec <- epic.vec[1:(i.sum - 2)]
  beld.vec.len <- length(beld.vec)
  crops.vec.len <- length(crops.vec)
  stopifnot(crops.vec.len == beld.vec.len) # assert
  vec.len <- beld.vec.len # just pick one

#  beld.nna <- sum(!is.na(beld.vec))
#  crops.nna <- sum(!is.na(crops.vec))
#  if (!crops.nna) {
  if (is.vec.na.or.zero(crops.vec)) {

# TODO: print(paste()) -> cat(sprintf())
    
# start debugging
#    cat(sprintf('No crop data for gridcell==[%3i,%3i]\n', i.col, i.row))
#   end debugging
    # write NA to the sum layer
    epic.vec[i.sum] <- NA
  }
#  if (!beld.nna) {
  if (is.vec.na.or.zero(beld.vec)) {
# start debugging
#    cat(sprintf('No BELD data for gridcell==[%3i,%3i]\n', i.col, i.row))
#   end debugging
    epic.vec[i.sum] <- NA
  }
#  if (crops.nna && beld.nna) {
  if (!is.vec.na.or.zero(crops.vec) && !is.vec.na.or.zero(beld.vec)) {
# nope: matrix multiply does not DWIM with NA
#    result <- crops.vec %*% beld.vec # matrix multiply
    # thanks, Kristen Foley
    result <- sum(crops.vec * beld.vec, na.rm=TRUE)
# start debugging

# This does not happen ...
#    if (is.na(result)) {
#      cat(sprintf('ERROR: for gridcell==[%3i,%3i], both crop and BELD data are not empty, but their product==NA\n', i.col, i.row))
#      cat('crop data==\n')
#      print(crops.vec)
#      cat('BELD data==\n')
#      print(beld.vec)
#      flush(stdout()) # otherwise, I get only the 'crop data==' prompt on terrae
#      return # halts? no
#    }

# ... but this *does* happen, a lot:
# TODO: trap these errors, halt, and examine
    if (result == 0) {
#      cat(sprintf('ERROR: for gridcell==[%3i,%3i], both crop and BELD data are not empty, but their product==0\n', i.col, i.row))
#      cat('crop data==\n')
#      print(crops.vec)
#      cat('BELD data==\n')
#      print(beld.vec)
#      flush(stdout())
       scoreboard.gridcells[length(scoreboard.gridcells) +1] <-
         sprintf('[%3i,%3i]', i.col, i.row)
       # TODO: vectorize
       for (i.data in 1:vec.len) {
         crop <- crops.vec[i.data]
         beld <- beld.vec[i.data]
         if       (!is.val.na.or.zero(beld) && is.val.na.or.zero(crop)) {
           scoreboard.have.beld.not.crop <- scoreboard.have.beld.not.crop +1
         } else if (is.val.na.or.zero(beld) && !is.val.na.or.zero(crop)) {
           scoreboard.have.crop.not.beld <- scoreboard.have.crop.not.beld +1
         }
       }
    }
#   end debugging
    epic.vec[i.sum] <- result
  }

  # note: explicit `return` halts execution!

  list(sum.vec=epic.vec,
       gridcells.vec=scoreboard.gridcells,
       have.crop.not.beld=scoreboard.have.crop.not.beld,
       have.beld.not.crop=scoreboard.have.beld.not.crop
  )
} # end function sum.emissions.for.layers

# Report statistics gathered in function sum.emissions.for.layers
report.mismatches <- function(
  gridcells.vec,
  scoreboard.have.beld.not.crop,
  scoreboard.have.crop.not.beld,
  gridcells.n,
  layers.n
  ) {
  stopifnot(is.vector(gridcells.vec))
  stopifnot(gridcells.n > 0)
  stopifnot(layers.n > 0)
  if (length(gridcells.vec) > 0) {
    cat(sprintf('computeCropSum.r: of total spatial gridcells==%i and total data points==%i\n',
       gridcells.n, gridcells.n * layers.n))
    cat(sprintf('\tdata points==%i have BELD data but not EPIC data\n',
       scoreboard.have.beld.not.crop))
    cat(sprintf('\tdata points==%i have EPIC data but not BELD data\n',
       scoreboard.have.crop.not.beld))
    cat(sprintf('\tcausing spatial gridcells==%i to have no emissions due to mismatch\n',
       length(gridcells.vec)))
#    cat(sprintf('\tcausing spatial gridcells==%i to have no emissions due to mismatch:\n',
#      length(gridcells.vec)))
#    print(gridcells.vec)
    flush(stdout())
  }
} # end function report.mismatches

# main----------------------------------------------------------------

# 1 Setup: open connections and devices, load data
#   See http://rosettacode.org/wiki/Command-line_arguments#R
#   TODO: check arguments

# Read the commandline arguments
args <- (commandArgs(TRUE))

# args is now a list of character vectors
# First check to see if any arguments were passed,
# then evaluate each argument.
if (length(args)==0) {
  cat("No arguments supplied\n")
  # defaults supplied above
} else {
  # Note: cannot have spaces in arguments!
  for (i in 1:length(args)) {
    eval(parse(text=args[[i]]))
  }
}

if (plot.layers) {
  cat('computeCropSum.r: plotting layers\n')

  # plot-related vars: TODO: move me to a separate file!
  image.fp <- "./compare.DN2.layers.pdf" # file to which to plot
  map.table <- './map.CMAQkm.world.dat'  # map to overlay on plot

  source('./plotLayersForTimestep.r')
} else {
  cat('computeCropSum.r: not plotting layers\n')
}

beld.array <- readRDS(beld.fp)
epic.input.file <- nc_open(epic.input.fp, write=FALSE, readunlim=FALSE)
epic.output.file <- nc_open(epic.output.fp, write=TRUE, readunlim=FALSE)
epic.input.datavar <- ncvar_get(epic.input.file, varid=datavar.name)
epic.output.datavar <- ncvar_get(epic.output.file, varid=datavar.name)

if (plot.layers) {
  map <- read.table(map.table, sep=",")
  attrs.list <- get.plot.addrs.from.IOAPI(epic.input.file)
  # creates PDF, starts graphic device
  pdf(image.fp, height=3.5, width=5, pointsize=1, onefile=TRUE)
}

# NOTE: this assumes input=unsummed file and output=summed file have SAME DIMENSIONS
datavar.dims.n <- length(dim(epic.input.datavar))
datavar.cols.n <- dim(epic.input.datavar)[1]
datavar.rows.n <- dim(epic.input.datavar)[2]
datavar.cells.n <- datavar.rows.n * datavar.cols.n
datavar.layers.n <- dim(epic.input.datavar)[3]
# used in reading one timestep at a time
# (Pierce-style read: see help(ncvar_get)#Examples)
start <- rep(1,datavar.dims.n) # start=(1,1,1,...)
# Remember timelike dim is always the LAST dimension!
# but if val=1, it is omitted from dim(epic.input.datavar), breaking Pierce-style read (below)
if      (datavar.dims.n < 3) {
  # TODO: throw
  print(paste('ERROR: datavar.dims.n==', datavar.dims.n))
} else if (datavar.dims.n == 3) {
  datavar.timesteps.n <- 1
  count <- c(dim(epic.input.datavar), 1)
  start <- c(start, 1)
  datavar.dims.max.vec <- count
  datavar.dims.n <- 4
} else if (datavar.dims.n == 4) {
  datavar.timesteps.n <- dim(epic.input.datavar)[datavar.dims.n]
  count <- dim(epic.input.datavar)
  datavar.dims.max.vec <- count
} else {
  # TODO: throw
  cat(sprintf('ERROR: datavar.dims.n==%i > 4\n', datavar.dims.n))
}
# start debugging
# print('initially:')
# TODO: get output all on one line
# print('start==') ; print(start)
# print('count==') ; print(count)
#   end debugging

# Following are used for data analysis in sum.emissions.for.layers:
# scoreboard.gridcells is a vector of strings like '[col,row]'
#   recording gridcells where we have crop and BELD data,
#   but their product == 0 (due to data cell mismatch)
scoreboard.gridcells <- character(0)
# scoreboard.have.crop.not.beld records mismatches where BELD layer == 0
scoreboard.have.crop.not.beld <- 0
# scoreboard.have.beld.not.crop records mismatches where EPIC layer == 0
scoreboard.have.beld.not.crop <- 0

# For each timestep in EPIC file:

# for safety (and pedagogy), read in data one timestep at a time, dim-agnostically
for (i.timestep in 1:datavar.timesteps.n) {
#i.timestep <- 1

  # Initialize start and count to read one timestep of the variable:
  # start=(1,1,1,i), count=(COL,ROW,LAY,i)
  start[datavar.dims.n] <- i.timestep
  count[datavar.dims.n] <- i.timestep
# start debugging
#   cat(sprintf('for timestep==%i\n', i.timestep))
# TODO: get output all on one line
#   print('start==') ; print(start)
#   print('count==') ; print(count)
#   end debugging
  epic.input.timestep <- ncvar_get(epic.input.file, varid=datavar.name, start=start, count=count)
  epic.output.timestep <- ncvar_get(epic.output.file, varid=datavar.name, start=start, count=count)

  # TODO: can this be done as a dual `apply`, or a linear-algebra op?
  # For each gridcell in timestep:

  for (i.col in 1:datavar.cols.n) {
    for (i.row in 1:datavar.rows.n) {
# debugging
# epic.vec has one value @ [248,50,5]                       (rest NA)
# beld.vec has one value @ [248,50,5], another @ [248,50,1] (rest 0)
# i.col <- 248 ; i.row <- 50

      # Determine whether gridcell is "empty," i.e., all its crop layers==NA.
      # If so, write NAs to sum layer. Else:
      # compute sum of products of "BELD vector" and "crop vector," write to sum layer.
      beld.array[i.col,i.row,] -> beld.vec
      epic.input.timestep[i.col,i.row,] -> epic.input.vec
      epic.output.timestep[i.col,i.row,] -> epic.output.vec

# initial implementation:
#        epic.output.vec <- sum.emissions.for.layers(
#          epic.input.vec, beld.vec, i.col, i.row,
#          scoreboard.gridcells,
#          scoreboard.have.crop.not.beld,
#          scoreboard.have.beld.not.crop)
      # The scoreboard* vars don't increment: not in global scope?
      sum.list <- sum.emissions.for.layers(
        epic.input.vec, beld.vec, i.col, i.row,
        scoreboard.gridcells,
        scoreboard.have.crop.not.beld,
        scoreboard.have.beld.not.crop)
      epic.output.vec <- sum.list$sum.vec
      scoreboard.gridcells <- sum.list$gridcells.vec
      scoreboard.have.crop.not.beld <- sum.list$have.crop.not.beld
      scoreboard.have.beld.not.crop <- sum.list$have.beld.not.crop
      epic.output.timestep[i.col,i.row,] <- epic.output.vec

    } # end for rows
  } # end for cols
# start debugging
#  cat(sprintf('data points==%i have BELD data but not EPIC data\n',
#     scoreboard.have.beld.not.crop))
#  cat(sprintf('data points==%i have EPIC data but not BELD data\n',
#     scoreboard.have.crop.not.beld))
#  cat(sprintf('causing spatial gridcells==%i to have no emissions due to mismatch:\n',
#    length(scoreboard.gridcells)))
#  flush(stdout())
#   end debugging
  
  # Write the new'n'improved timestep back to file.
  # TODO: don't write if no layers changed
  ncvar_put(epic.output.file, varid=datavar.name, vals=epic.output.timestep, start=start, count=count)

# TODO: test sums!

#   4 Plot all layers in timestep.

  if (plot.layers) {
# debugging
    cat(sprintf('computeCropSum.r: plot.layers.for.timestep==%i, n.layers==%i\n',
      i.timestep, datavar.layers.n))
    epic.output.datavar <- ncvar_get(epic.output.file, varid=datavar.name)
    plot.layers.for.timestep(
      epic.output.datavar, datavar.name, i.timestep, datavar.layers.n,
      attrs.list, probabilities.vec, colors, map)
  }
} # end for timesteps

# 5 Report on data mismatches (to stdout, no retval)
report.mismatches(
  scoreboard.gridcells,
  scoreboard.have.beld.not.crop,
  scoreboard.have.crop.not.beld,
  datavar.cells.n, datavar.layers.n)

# 6 Teardown.

# Close the connections (ncdf=close.ncdf), ...
if (plot.layers) {
  dev.off()
}
nc_close(epic.input.file)
nc_close(epic.output.file)
# * ... and remove their ADS (not the files!) from the workspace.
rm(epic.input.file)
rm(epic.output.file)

# debugging-----------------------------------------------------------
