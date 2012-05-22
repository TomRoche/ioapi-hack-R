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
epic.input.fp <- sprintf('./5yravg.%sstripped.nc', datavar.name)
epic.output.fp <- sprintf('./5yravg.%svars_fixed.nc', datavar.name)
# plot-related vars? NO: NO PLOTTING HERE!

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

# vector of the names of the datavars we need to keep, for ourselves
# i.e. (not including TFLAG)
# Don't compute this until after caller gets a chance to set!
datavar.names.vec <- c(datavar.name)
epic.input.file <- nc_open(epic.input.fp, write=TRUE, readunlim=FALSE)
epic.input.datavar <- ncvar_get(epic.input.file, varid=datavar.name)
epic.output.file <- nc_open(epic.output.fp, write=TRUE, readunlim=FALSE)
epic.output.datavar <- ncvar_get(epic.output.file, varid=datavar.name)
datavar.dims.n <- length(dim(epic.input.datavar))

# following is NOT only for plotting: fix.TFLAG needs n.timesteps
# kludging higher dimensions: do we have (layers > 1) or (timesteps > 1)?
# note dim=1 often omitted by default :-(
if ((datavar.dims.n < 2) || (datavar.dims.n > 4)) {
  # TODO: throw
  cat(sprintf('ERROR: processVars.r: datavar.dims.n==%i', datavar.dims.n))
  stopifnot((datavar.dims.n > 1) && (datavar.dims.n < 5)) # ASSERT
} else {
  datavar.cols.n <- dim(epic.input.datavar)[1]
  datavar.rows.n <- dim(epic.input.datavar)[2]
  datavar.cells.n <- datavar.rows.n * datavar.cols.n
  if (datavar.dims.n == 2) {
    datavar.layers.n <- 1
    dim(epic.input.datavar)[3] <- datavar.layers.n
    datavar.dims.n <- 3
  }
  # Remember timelike dim is always the LAST dimension!
  if (datavar.dims.n == 3) {
    datavar.layers.n <- dim(epic.input.datavar)[3]
    datavar.timesteps.n <- 1
    dim(epic.input.datavar)[4] <- datavar.timesteps.n
    datavar.dims.n <- 4
  }
  if (datavar.dims.n == 4) {
    datavar.timesteps.n <- dim(epic.input.datavar)[4]
  }
} # end testing datavar.dims.n

# used in reading one timestep at a time
# (Pierce-style read: see help(ncvar_get)#Examples)
start <- rep(1,datavar.dims.n) # start=(1,1,1,...)
count <- dim(epic.input.datavar)
datavar.dims.max.vec <- count

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

nc_close(epic.input.file)
nc_close(epic.output.file)
# * ... and remove their ADS (not the files!) from the workspace.
rm(epic.input.file)
rm(epic.output.file)

# debugging-----------------------------------------------------------
