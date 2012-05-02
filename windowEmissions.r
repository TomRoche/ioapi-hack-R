#!/usr/bin/env Rscript

# description---------------------------------------------------------

# Inputs (not in argument order)

# 1 Path to a fully-processed (e.g., summed) input *.nc from EPIC
#   (via, e.g., computeCropSum.sh) over CONUS.

# 2 Path to a windowed output *.nc with a subset of the above grid.

# code----------------------------------------------------------------

library(ncdf4)
library(M3)
source('./ioapi.r')         # for plotting
#source('./M3extensions.r')

# constants-----------------------------------------------------------
# default values, can be overridden from commandline

# path to input file
# TODO: get from environment
data.input.fp <- "./5yravg.DN2summed.nc"
# path to output file
# TODO: get from environment
# TODO: delete if exists
data.output.fp <- "./5yravg.DN2windowed.nc"
# the data variable of interest
datavar.name <- "DN2"

# Windowing bounds:
# * order follows m3wndw input convention
# * all values signed decimal (i.e., S,W are negative)
# Format: c(west lon, east lon, south lat, north lat)
window.bounds.latlon <- c(-96, -90, 39, 45)

# temporary file for m3wndw input
m3wndw.input.fp <- system('mktemp', intern=TRUE)

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

# Problem with stripping this attribute, below
attr.name <- "missing_value"
attr.prec <- "float"
attr.val <- -9.999e+36

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
  # so gotta post-process command to restore spaces:
  # see preprocessing in driver script
  m3wndw.command <-
    gsub(m3wndw.command.space.replacer, " ", m3wndw.command.space.replaced, fixed=TRUE)
# debugging
# cat(sprintf('windowEmissions.r: m3wndw.command=="%s"\n', m3wndw.command))
} # end parsing commandline args

if (plot.layers) {
  cat('windowEmissions.r: plotting layers\n')
  source('./plotLayersForTimestep.r')
} else {
  cat('windowEmissions.r: not plotting layers\n')
}

# main----------------------------------------------------------------

# 1 Setup: open connections and devices, load data
#   See http://rosettacode.org/wiki/Command-line_arguments#R
#   TODO: check arguments

# debugging
# print('window.bounds.latlon==') ; print(window.bounds.latlon)
# vectors with lonlat absolutely increasing (required for project.lonlat.to.M3)
lons.increasing <- c(window.bounds.latlon[1], window.bounds.latlon[2])
lats.increasing <- c(window.bounds.latlon[3], window.bounds.latlon[4])

rows.lower.m <- # southern bounds for each row, in meters
  get.coord.for.dimension(data.input.fp, 'row', position = 'lower', units='m')$coords
cols.left.m <-  # western bounds for each col, in meters
  get.coord.for.dimension(data.input.fp, 'col', position = 'lower', units='m')$coords
# start debugging
# cat(sprintf('%f < rows.lower.m < %f\n',
#             rows.lower.m[1], rows.lower.m[length(rows.lower.m)]))
# cat(sprintf('%f < cols.left.m < %f\n',
#             cols.left.m[1], cols.left.m[length(cols.left.m)]))
#   end debugging

bounds.coords <- # x,y in meters for each boundary specified by lonlat above
  project.lonlat.to.M3(
    lons.increasing, lats.increasing, data.input.fp, units='m')$coords
# debugging
# print('bounds.coords==') ; print(bounds.coords)

# not
# bounds.x.increasing <- bounds.coords$x
# since class==matrix, not class==list
bounds.x.increasing <- bounds.coords[,1]
bounds.y.increasing <- bounds.coords[,2]
# row,col for each boundary specified by lonlat above
bounds.rows.indices <- findInterval(bounds.x.increasing, rows.lower.m)
bounds.cols.indices <- findInterval(bounds.y.increasing, cols.left.m)
# start debugging
# cat(sprintf('%f < bounds.rows.indices < %f\n',
#             bounds.rows.indices[1], bounds.rows.indices[length(bounds.rows.indices)]))
# cat(sprintf('%f < bounds.cols.indices < %f\n',
#             bounds.cols.indices[1], bounds.cols.indices[length(bounds.cols.indices)]))
#   end debugging

# create input file for m3wndw
m3wndw.locol <- bounds.cols.indices[1]
m3wndw.hicol <- bounds.cols.indices[2]
m3wndw.lorow <- bounds.rows.indices[1]
m3wndw.hirow <- bounds.rows.indices[2]
# open output file connection, text mode
m3wndw.input.con <- file(m3wndw.input.fp, "wt")

# I have determined, from console, m3wndw input requires 8 lines:
# 4x"\n", then LOCOL\n, HICOL\n, LOROW\n, HIROW\n
cat(sprintf('\n\n\n\n%i\n%i\n%i\n%i\n',
  m3wndw.locol, m3wndw.hicol, m3wndw.lorow, m3wndw.hirow),
  file=m3wndw.input.con)
# close file connection
flush(m3wndw.input.con)
close(m3wndw.input.con)
# start debugging
cat(sprintf('windowEmissions.r: m3wndw input (from file==%s) is:\n',
            m3wndw.input.fp))
system(sprintf('cat %s', m3wndw.input.fp))
#   end debugging

# Window the file using m3tools/m3wndw
# Note `m3wndw.command` must be passed from the commandline!
# since it's got environmental dependencies (e.g., envvars, path)
# debugging
cat(sprintf('windowEmissions.r: about to call system(%s)\n',
            m3wndw.command))
system(m3wndw.command)
# ... and use resulting file, if we're plotting.
# TODO: test for creation of data.output.fp!

# Problem:
# + before this script, we have var attr=DN2:missing_value
# -  after this script, we lack var attr=DN2:missing_value
# start debugging
data.output.file <- nc_open(data.output.fp, write=TRUE, readunlim=FALSE)
attr.list <-
  ncatt_get(data.output.file, varid=datavar.name, attname=attr.name)
if (attr.list$hasatt) {
  cat(sprintf('windowEmissions.r: after M3WNDW, var=%s HAS attr=%s\n',
              datavar.name, attr.name))
} else {
  cat(sprintf('windowEmissions.r: after M3WNDW, var=%s LACKS attr=%s\n',
              datavar.name, attr.name))
  # restore it
  ncatt_put(data.output.file, varid=datavar.name,
            attname=attr.name, attval=attr.val, prec=attr.prec)
  # test restoration
  attr.list <-
    ncatt_get(data.output.file, varid=datavar.name, attname=attr.name)
  if (attr.list$hasatt) {
    cat(sprintf(
      'windowEmissions.r: succeeded in restoring attr=%s on var=%s\n',
      datavar.name, attr.name))
  } else {
    cat(sprintf(
      'windowEmissions.r: ERROR: failed to restore attr=%s on var=%s\n',
      datavar.name, attr.name))
  }
} # end testing if output file has desired attribute
nc_close(data.output.file)
#   end debugging

if (plot.layers) {
  # we're only plotting, so write=FALSE
  data.output.file <- nc_open(data.output.fp, write=FALSE, readunlim=FALSE)
  data.output.datavar <- ncvar_get(data.output.file, varid=datavar.name)

  # setup plot files
  map <- read.table(map.table, sep=",")
  attrs.list <- get.plot.addrs.from.IOAPI(data.output.file)
  # creates PDF, starts graphic device
  pdf(image.fp, height=3.5, width=5, pointsize=1, onefile=TRUE)

  datavar.dims.n <- length(dim(data.output.datavar))
  datavar.cols.n <- dim(data.output.datavar)[1]
  datavar.rows.n <- dim(data.output.datavar)[2]
  datavar.cells.n <- datavar.rows.n * datavar.cols.n
  datavar.layers.n <- dim(data.output.datavar)[3]
  # used in reading one timestep at a time
  # (Pierce-style read: see help(ncvar_get)#Examples)
  start <- rep(1,datavar.dims.n) # start=(1,1,1,...)
  # Remember timelike dim is always the LAST dimension!
  # but if val=1, it is omitted from dim(data.output.datavar), breaking Pierce-style read (below)
  if      (datavar.dims.n < 3) {
    # TODO: throw
    cat(sprintf('ERROR: datavar.dims.n==%i < 3\n', datavar.dims.n))
  } else if (datavar.dims.n == 3) {
    datavar.timesteps.n <- 1
    count <- c(dim(data.output.datavar), 1)
    start <- c(start, 1)
    datavar.dims.max.vec <- count
    datavar.dims.n <- 4
  } else if (datavar.dims.n == 4) {
    datavar.timesteps.n <- dim(data.output.datavar)[datavar.dims.n]
    count <- dim(data.output.datavar)
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
  # don't need to use start and count:
  # M3WNDW is doing the manipulating, we're only plotting

  for (i.timestep in 1:datavar.timesteps.n) {
#i.timestep <- 1

  # plot timestep
  # debugging
#    cat(sprintf('windowEmissions.r: plot.layers.for.timestep==%i, n.layers==%i\n',
#      i.timestep, datavar.layers.n))
    plot.layers.for.timestep(
      datavar=data.output.datavar,
      datavar.name=datavar.name,
      datavar.parent=data.output.file,
      i.timestep=i.timestep,
      n.layers=datavar.layers.n,
      attrs.list=attrs.list,
      q.vec=probabilities.vec,
      l2d.fp=l2d.fp,
      colors=colors,
      map=map)
  } # end for timesteps

} # end testing plot.layers

# Teardown. Close the connections (ncdf=close.ncdf), ...
if (plot.layers) {
  dev.off()
}
nc_close(data.output.file)
# * ... and remove their ADS (not the files!) from the workspace.
rm(data.output.file)

# debugging-----------------------------------------------------------
