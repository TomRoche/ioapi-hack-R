#!/usr/bin/env Rscript

# description---------------------------------------------------------

# NOTE: I cannot apparently both input and output to the same netCDF file.

# Inputs (in argument order)

# 1 The name of a single data variable (datavar) for which
#   we need to fix a few layers.

# 2 The number of layers we need to fix (write with NAs)
#   (assumed to be at end, e.g., 2 -> last 2)
#   and which we need to add to the pesky IOAPI global var.

# 3 Path to the *.nc (with layers previously added by us
#   via, e.g., computeCropSum.sh) which needs fixing.
#   dim(datavar) == [TSTEP, LAY, ROW, COL], where
# * [ROW, COL] is the gridspace
# * one layer per crop, 1 < i.layer <= n.layers.
#   Thus the "crop vector" for that gridcell has length==n.layers.

# Outputs the fixed file with
# * correct number of layers in global attr=NLAYS
# * all values in last n layers overwritten by NA
  
# code----------------------------------------------------------------

library(ncdf4)
source('./ioapi.r')

# constants-----------------------------------------------------------

# may be overridden by commandline, below
datavar.name <- "DN2"
input.fp <- sprintf('./5yravg.%slayered.nc', datavar.name)
output.fp <- sprintf('./5yravg.%slayers_fixed.nc', datavar.name)
layers.add.n <- 2
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
  cat('processLayers.r: plotting layers\n')

  # plot-related vars: TODO: move me to a separate file!
  image.fp <- "./compare.DN2.layers.pdf" # file to which to plot
  map.table <- './map.CMAQkm.world.dat'  # map to overlay on plot

  source('./plotLayersForTimestep.r')
} else {
  cat('processLayers.r: not plotting layers\n')
}

input.file <- nc_open(input.fp, write=TRUE, readunlim=FALSE)
input.datavar <- ncvar_get(input.file, varid=datavar.name)
output.file <- nc_open(output.fp, write=TRUE, readunlim=FALSE)
output.datavar <- ncvar_get(output.file, varid=datavar.name)

if (plot.layers) {
  map <- read.table(map.table, sep=",")
  attrs.list <- get.plot.addrs.from.IOAPI(input.file)
  # creates PDF, starts graphic device
  pdf(image.fp, height=3.5, width=5, pointsize=1, onefile=TRUE)
}

datavar.dims.n <- length(dim(input.datavar))
datavar.cols.n <- dim(input.datavar)[1]
datavar.rows.n <- dim(input.datavar)[2]
datavar.cells.n <- datavar.rows.n * datavar.cols.n
datavar.layers.n <- dim(input.datavar)[3]
# used in reading one timestep at a time
# (Pierce-style read: see help(ncvar_get)#Examples)
start <- rep(1,datavar.dims.n) # start=(1,1,1,...)
# Remember timelike dim is always the LAST dimension!
# but if val=1, it is omitted from dim(input.datavar), breaking Pierce-style read (below)
if      (datavar.dims.n < 3) {
  # TODO: throw
  print(paste('ERROR: datavar.dims.n==', datavar.dims.n))
} else if (datavar.dims.n == 3) {
  datavar.timesteps.n <- 1
  count <- c(dim(input.datavar), 1)
  start <- c(start, 1)
  datavar.dims.max.vec <- count
  datavar.dims.n <- 4
} else if (datavar.dims.n == 4) {
  datavar.timesteps.n <- dim(input.datavar)[datavar.dims.n]
  count <- dim(input.datavar)
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

# fix IOAPI global attr=NLAYS
fix.NLAYS(output.file, datavar.layers.n)
# fix IOAPI global attr=VGLVLS
fix.VGLVLS(input.file, datavar.layers.n, output.file)

# For each timestep in EPIC file:

# for safety (and pedagogy), read in data one timestep at a time, dim-agnostically
for (i.timestep in 1:datavar.timesteps.n) {
#i.timestep <- 1

  # Initialize start and count to read one timestep of the variable:
  # start=(1,1,1,i), count=(COL,ROW,LAY,i)
  start[datavar.dims.n] <- i.timestep
  count[datavar.dims.n] <- i.timestep
# start debugging
#   print(paste('for timestep==', i.timestep, sep=""))
# TODO: get output all on one line
#   print('start==') ; print(start)
#   print('count==') ; print(count)
#   end debugging

  input.timestep <- ncvar_get(input.file, varid=datavar.name, start=start, count=count)
  output.timestep <- input.timestep
  for (i.layer.to.fix in
       (datavar.layers.n - layers.add.n + 1):datavar.layers.n) {
# debugging
#    cat(sprintf('processLayers.r: layer to fix==%i\n\tstart: sum(!is.na(layer))==%i\n',
#      i.layer.to.fix, sum(!is.na(output.timestep[,,i.layer.to.fix]))))
    output.timestep <- overwrite.layer.in.timestep(
      output.timestep, value.to.write=NA, i.lay=i.layer.to.fix)
  }
  # Write the new'n'improved timestep back to file.
  ncvar_put(output.file, varid=datavar.name, vals=output.timestep, start=start, count=count)

# start debugging
#  for (i.layer.to.fix in
#       (datavar.layers.n - layers.add.n + 1):datavar.layers.n) {
#    epic.test.timestep <- ncvar_get(output.file, varid=datavar.name, start=start, count=count)
#    cat(sprintf('processLayers.r: layer to fix==%i\n\t  end: sum(!is.na(layer))==%i\n',
#      i.layer.to.fix, sum(!is.na(epic.test.timestep[,,i.layer.to.fix]))))
#  }
#   end debugging

  if (plot.layers) {
# debugging
    cat(sprintf('processLayers.r: plot.layers.for.timestep==%i, n.layers==%i\n',
      i.timestep, datavar.layers.n))
    output.datavar <- ncvar_get(output.file, varid=datavar.name)
    plot.layers.for.timestep(
      datavar=output.datavar,
      datavar.name=datavar.name,
      datavar.parent=output.file,
      i.timestep=i.timestep,
      n.layers=datavar.layers.n,
      attrs.list=attrs.list,
      q.vec=probabilities.vec,
      colors=colors,
      map=map)
  }
} # end for timesteps

# Close the connections (ncdf=close.ncdf), ...
if (plot.layers) {
  dev.off()
}
nc_close(input.file)
nc_close(output.file)
# * ... and remove their ADS (not the files!) from the workspace.
rm(input.file)
rm(output.file)

# debugging-----------------------------------------------------------
