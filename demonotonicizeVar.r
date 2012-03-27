#!/usr/bin/env Rscript

# description---------------------------------------------------------

# NOTE: I cannot apparently both input and output to the same netCDF file.

# Inputs:

# 1 Path to the input *.nc containing the data variable (datavar) of interest.

# 2 The name of one datavar which we want to "demonotonicize":
#   it has values which, instead of being recorded separately,
#   (e.g., a[i]==u, a[j]==v, a[k]==w, with i < j < k,
#   with all intervening values == NA), have been inadvertently summed, 
#   such that, e.g., a[i]==u, a[j]==u+v, a[k]==u+v+w.

# 3 Path to the output *.nc, in which the datavar is fixed.
  
# code----------------------------------------------------------------

library(ncdf4)
source('./ioapi.r') # for IOAPI fix functions
source('./tlrRutilities.r')

# constants-----------------------------------------------------------

# may be overridden by commandline, below
datavar.name <- "DN2"
# undamaged layers, which don't need demonotonicized
layers.n.good <- c(0)
input.fp <- sprintf('./5yravg.%svars_fixed.nc', datavar.name)
output.fp <- sprintf('./5yravg.%sdemonotonicized.nc', datavar.name)
# plot-related vars
plot.layers <- FALSE
image.fp <- "./compare.DN2.layers.pdf"
map.table <- '../GIS/map.CMAQkm.world.dat'
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
  cat('demonotonicizeVar.r: plotting layers\n')
  source('./plotLayersForTimestep.r')
} else {
  cat('demonotonicizeVar.r: not plotting layers\n')
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

  for (i.layer in 1:datavar.layers.n) {
# debugging
# i.layer <- 1
    input.data <- input.timestep[,,i.layer]
    if (is.element(i.layer, layers.n.good)) {
      output.timestep[,,i.layer] <- input.data
    } else {
      # debugging
#      cat(sprintf('processing layer#==%2i\n', i.layer))
      output.timestep[,,i.layer] <- demonotonicize.layer(input.data)
    }
  } # end looping over layer#s

  # Write the new'n'improved timestep back to file.
  ncvar_put(output.file, varid=datavar.name, vals=output.timestep, start=start, count=count)

# start debugging
#  for (i.layer.to.fix in
#       (datavar.layers.n - layers.to.fix + 1):datavar.layers.n) {
#    epic.test.timestep <- ncvar_get(output.file, varid=datavar.name, start=start, count=count)
#    cat(sprintf('processLayers.r: layer to fix==%i\n\t  end: sum(!is.na(layer))==%i\n',
#      i.layer.to.fix, sum(!is.na(epic.test.timestep[,,i.layer.to.fix]))))
#  }
#   end debugging

  if (plot.layers) {
# debugging
#    cat(sprintf('processLayers.r: plot.layers.for.timestep==%i, n.layers==%i\n',
#      i.timestep, datavar.layers.n))
    output.datavar <- ncvar_get(output.file, varid=datavar.name)
    plot.layers.for.timestep(
      output.datavar, datavar.name, i.timestep, datavar.layers.n,
      attrs.list, probabilities.vec, colors, map)
  }
} # end for timesteps

# Close the connections (ncdf=close.ncdf), ...
if (plot.layers) {
  dev.off()
}
nc_close(input.file)
nc_close(output.file)
# ... and remove their ADS (not the files!) from the workspace.
rm(input.file)
rm(output.file)

# debugging-----------------------------------------------------------
