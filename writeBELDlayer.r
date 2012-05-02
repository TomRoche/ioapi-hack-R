#!/usr/bin/env Rscript

# description---------------------------------------------------------

# Inputs (not in argument order)

# 1 Path to an "BELD-data-less" input *.nc from EPIC
#   (via, e.g., computeCropSum.sh) with
#   dim(datavar) == [TSTEP, LAY, ROW, COL], where
# * [ROW, COL] is the gridspace
# * one layer per crop, 1 < i.layer <= n.layers.

# 2 Path to a *.rds BELD array (as output by beldToRDS.r) with
#   dim(array) == [LAY, ROW, COL], where
# * [ROW, COL] is the same gridspace as the EPIC datavar
# * one layer per crop, hence ...
# * the "BELD vector" for a gridcell has length==n.layers.

# 3 Path to a "BELDed" output *.nc
#   (via, e.g., computeCropSum.sh) very like the unsummed input, but
# + one new "BELD layer" per gridcell, i.layer == n.layers + 1,
#   with values to be ignored.

# Outputs the BELDed output EPIC file, containing, in each gridcell,
# a value in [gridcell, i.layer] containing the sum of crop coverage
# (i.e., total share of the land cover on that gridcell) from BELD.
  
# code----------------------------------------------------------------

library(ncdf4)
source('./ioapi.r')

# constants-----------------------------------------------------------

datavar.name <- "DN2"
# path to input file
# TODO: get from environment
epic.input.fp <- sprintf('./5yravg.%sunsummed.nc', datavar.name)
# path to output file
# TODO: get from environment
# TODO: delete if exists
epic.output.fp <- sprintf('./5yravg.%sbelded.nc', datavar.name)
# path to serialized BELD array, as produced by beldToRDS
beld.fp <- "./BELD4crops_12km_6_13_11_LimeiRan.rds"
# plot-related vars. TODO: move me to a separate file!
plot.layers <- FALSE
image.fp <- "./compare.DN2.layers.pdf" # file to which to plot
map.table <- './map.CMAQkm.world.dat'  # map to overlay on plot
l2d.fp <- "./layer2description.rds"    # env mapping layer#s to crop descriptions
# package=grDevices
palette.vec <- c("grey","purple","deepskyblue2","green","yellow","orange","red","brown")
colors <- colorRampPalette(palette.vec)
# used for quantiling legend
probabilities.vec <- seq(0, 1, 1.0/(length(palette.vec) - 1))

# functions-----------------------------------------------------------

# Write sum in sum.layer (or NA if BELD layers are empty).
# function procedure (copied from above):
# 2 Determine whether gridcell is "empty," i.e., all its crop layers==NA.
#   If so, write NAs to sum layer. If not:

# 3 Sum "BELD vector" and write to "BELD layer."

sum.beld.for.layers <- function(
  epic.vec, beld.vec, i.col, i.row,
  i.sum  # index of cell in vector in which to write the sum
) {
  beld.nna <- sum(subset(beld.vec, beld.vec > 0))
  if (beld.nna) {
    epic.vec[i.sum] <- beld.nna
  } else {
# debugging
#    cat(sprintf('No BELD data > 0 for gridcell==[%3i,%3i]\n', i.col, i.row))
    epic.vec[i.sum] <- NA
  }
  # note: explicit `return` halts execution!
  epic.vec
} # end function sum.beld.for.layers

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
  cat('writeBELDlayer.r: plotting layers\n')
  source('./plotLayersForTimestep.r')
} else {
  cat('writeBELDlayer.r: not plotting layers\n')
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

# NOTE: this assumes input and output file have SAME DIMENSIONS
datavar.dims.n <- length(dim(epic.output.datavar))
datavar.cols.n <- dim(epic.output.datavar)[1]
datavar.rows.n <- dim(epic.output.datavar)[2]
datavar.cells.n <- datavar.rows.n * datavar.cols.n
datavar.layers.n <- dim(epic.output.datavar)[3]
# ASSERT: files have already had layers augmented by 2:
# crops layers, then "BELD layer" then "sum layer"
i.sum <- datavar.layers.n - 1

# used in reading one timestep at a time
# (Pierce-style read: see help(ncvar_get)#Examples)
start <- rep(1,datavar.dims.n) # start=(1,1,1,...)
# Remember timelike dim is always the LAST dimension!
# but if val=1, it is omitted from dim(epic.output.datavar), breaking Pierce-style read (below)
if      (datavar.dims.n < 3) {
  # TODO: throw

# TODO: print(paste()) -> cat(sprintf())

  cat(sprintf('ERROR: datavar.dims.n==%i\n', datavar.dims.n))
} else if (datavar.dims.n == 3) {
  datavar.timesteps.n <- 1
  count <- c(dim(epic.output.datavar), 1)
  start <- c(start, 1)
  datavar.dims.max.vec <- count
  datavar.dims.n <- 4
} else if (datavar.dims.n == 4) {
  datavar.timesteps.n <- dim(epic.output.datavar)[datavar.dims.n]
  count <- dim(epic.output.datavar)
  datavar.dims.max.vec <- count
} else {
  # TODO: throw
  cat(sprintf('ERROR: datavar.dims.n==%i\n', datavar.dims.n))
}
# start debugging
# print('initially:')
# TODO: get output all on one line
# print('start==') ; print(start)
# print('count==') ; print(count)
#   end debugging

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

      # Determine whether gridcell is "empty" in BELD,
      # i.e., all its layers==0.
      # If so, write NAs to BELD layer. Else: write sum of BELD layers.
      beld.array[i.col,i.row,] -> beld.vec
      epic.input.timestep[i.col,i.row,] -> epic.input.vec
      epic.output.timestep[i.col,i.row,] -> epic.output.vec
      epic.output.vec <- sum.beld.for.layers(
        epic.input.vec, beld.vec, i.col, i.row, i.sum)
      epic.output.timestep[i.col,i.row,] <- epic.output.vec

    } # end for rows
  } # end for cols

  # Write the new'n'improved timestep back to file.
  # TODO: don't write if no layers changed
  ncvar_put(epic.output.file, varid=datavar.name, vals=epic.output.timestep, start=start, count=count)

  if (plot.layers) {
# debugging
    cat(sprintf('writeBELDlayer.r: plot.layers.for.timestep==%i, n.layers==%i\n',
      i.timestep, datavar.layers.n))
    epic.output.datavar <- ncvar_get(epic.output.file, varid=datavar.name)
    plot.layers.for.timestep(
      datavar=epic.output.datavar,
      datavar.name=datavar.name,
      datavar.parent=epic.output.file,
      i.timestep=i.timestep,
      n.layers=datavar.layers.n,
      attrs.list=attrs.list,
      q.vec=probabilities.vec,
      l2d.fp=l2d.fp,
      colors=colors,
      map=map)
  }
} # end for timesteps

# 5 Teardown

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
