#!/usr/bin/env Rscript

# description---------------------------------------------------------

# NOTE: I cannot apparently both input and output to the same netCDF file.

# Inputs (not in argument order)

# 1 The name of a single data variable (datavar) which we want to keep
#   (other than the IOAPI metavar name=TFLAG)

# 2 Path to the input *.nc (with datavars previously removed by us
#   via, e.g., `ncks`) which needs fixing.

# 3 Path to the output *.nc, in which is fixed
# * datavar attr=_FillValue
# * TFLAG dim=VAR
# * global attrs NVARS, VAR-LIST
  
# code----------------------------------------------------------------

library(ncdf4)
source('./ioapi.r') # for IOAPI fix functions

# constants-----------------------------------------------------------

# may be overridden by commandline, below
datavar.name <- "DN2"
# vector of the names of the datavars we need to keep, for ourselves
# i.e. (not including TFLAG)
datavar.names.vec <- c(datavar.name)
epic.input.fp <- sprintf('./5yravg.%sstripped.nc', datavar.name)
epic.output.fp <- sprintf('./5yravg.%svars_fixed.nc', datavar.name)
# plot-related vars
plot.layers <- FALSE
# package=grDevices
palette.vec <- c("grey","purple","deepskyblue2","green","yellow","orange","red","brown")
colors <- colorRampPalette(palette.vec)
# used for quantiling legend
probabilities.vec <- seq(0, 1, 1.0/(length(palette.vec) - 1))

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
  cat('processVars.r: plotting layers\n')

  # plot-related vars: TODO: move me to a separate file!
  image.fp <- "./compare.DN2.layers.pdf" # file to which to plot
  map.table <- './map.CMAQkm.world.dat'  # map to overlay on plot

  source('./plotLayersForTimestep.r')
} else {
  cat('processVars.r: not plotting layers\n')
}

epic.input.file <- nc_open(epic.input.fp, write=TRUE, readunlim=FALSE)
epic.input.datavar <- ncvar_get(epic.input.file, varid=datavar.name)
epic.output.file <- nc_open(epic.output.fp, write=TRUE, readunlim=FALSE)
epic.output.datavar <- ncvar_get(epic.output.file, varid=datavar.name)

if (plot.layers) {
  map <- read.table(map.table, sep=",")
  attrs.list <- get.plot.addrs.from.IOAPI(epic.input.file)
  # creates PDF, starts graphic device
  pdf(image.fp, height=3.5, width=5, pointsize=1, onefile=TRUE)
}

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
  print(paste('ERROR: datavar.dims.n==', datavar.dims.n))
}
# start debugging
# print('initially:')
# TODO: get output all on one line
# print('start==') ; print(start)
# print('count==') ; print(count)
#   end debugging

# fix attributes (file-global and datavar-local)

fix.FillValue(epic.input.file, datavar.names.vec, epic.output.file)
# since we now have only DN2--shoulda fixed that earlier
# fix.NVARS(epic.output.file, 1)
# but `verdi` (and other consumers of IOAPI metadata) also need var=TFLAG
# fix.NVARS(epic.output.file, length(datavar.names.vec) +1)
fix.NVARS(epic.output.file, length(datavar.names.vec))
fix.VARdashLIST(epic.input.file, datavar.names.vec, epic.output.file)
# fix IOAPI-specific "datavar"=TFLAG
# ASSERT: number of timesteps is same for all datavars
# fix.TFLAG(epic.input.file, datavar.names.vec, datavar.timesteps.n, epic.output.file)
# kludge
fix.TFLAG(epic.input.file, datavar.names.vec, datavar.timesteps.n, epic.output.file, epic.output.fp)

if (plot.layers) {
  # for safety (and pedagogy), read in data one timestep at a time, dim-agnostically
  for (i.timestep in 1:datavar.timesteps.n) {
  #i.timestep <- 1

    # Initialize start and count to read one timestep of the variable:
    # start=(1,1,1,i), count=(COL,ROW,LAY,i)
    start[datavar.dims.n] <- i.timestep
    count[datavar.dims.n] <- i.timestep
# start debugging
#     print(paste('for timestep==', i.timestep, sep=""))
# TODO: get output all on one line
#     print('start==') ; print(start)
#     print('count==') ; print(count)
#   end debugging

    epic.output.timestep <- ncvar_get(epic.output.file, varid=datavar.name, start=start, count=count)
# debugging
    cat(sprintf('processVars.r: plot.layers.for.timestep==%i, n.layers==%i\n',
      i.timestep, datavar.layers.n))
    epic.output.datavar <- ncvar_get(epic.output.file, varid=datavar.name)
    plot.layers.for.timestep(
      epic.output.datavar, datavar.name, i.timestep, datavar.layers.n,
      attrs.list, probabilities.vec, colors, map)
  } # end for timesteps
} # end if plotting

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
