# modified from plotLayersForTimestep.r.1
# * move device control outside of these methods
# * refactor code for plotting single dataset, for reuse

library(fields)

plot.layers.for.timestep <- function(
  datavar,          # data variable
  datavar.name,     # string naming the datavar # TODO: get from datavar
  datavar.parent,   # file object containing the datavar
  i.timestep=1,     # index of timestep to plot
  n.layers=0,       # max number of layers (in timestep) to plot
  attrs.list,       # list of global attributes
  q.vec=NULL,       # for quantiles # TODO: handle when null!
  colors,
  map
) {
  for (i.layer in 1:n.layers) {
# debugging
# i.layer <- 1

    # get title string:
    # first, minimally:
    title <- sprintf('%s: layer#=%2i', datavar.name, i.layer)
#    title <- sprintf('%s: layer#=%2i (%s) # when we have the crop name
    attr.list <-
      ncatt_get(datavar.parent, varid=datavar.name, attname="units")
    if (attr.list$hasatt) {
      title <- sprintf('%s, units=%s', title, attr.list$value)
    } else {
      cat(sprintf(
        'plot.layers.for.timestep: ERROR: no units for var=%s\n',
        datavar.name))
    }

#    data <- datavar[,,i.layer,i.timestep]
    data <- datavar[,,i.layer]
# start debugging for Doug Nychka Mon, 13 Feb 2012 21:33:36 -0700
#    print(paste('class(data)==', class(data), sep=""))
#   end debugging for Doug Nychka Mon, 13 Feb 2012 21:33:36 -0700
    plot.layer(data, title, attrs.list, q.vec, colors, map)
  } # end interating layers
} # end function plot.layers.for.timestep

plot.before.and.after.layers.for.timestep <- function(
  source.datavar,   # source/unmodified data variable
  target.datavar,   # target/modified data variable
  datavar.name,     # string naming the datavar
  i.timestep=1,     # index of timestep to plot
  datavar.n.layers, # max number of layers (in timestep) to plot
  attrs.list,       # list of global attributes
  probabilities.vec=NULL, # for quantiles # TODO: handle when null!
  colors,
  map
) {
  for (i.layer in 1:datavar.n.layers) {
# debugging
# i.layer <- 1

#    source.data <- source.datavar[,,i.layer,i.timestep]
    source.data <- source.datavar[,,i.layer]
#    target.data <- target.datavar[,,i.layer,i.timestep]
    target.data <- target.datavar[,,i.layer]
# start debugging for Doug Nychka Mon, 13 Feb 2012 21:33:36 -0700
#    print(paste('class(source.data)==', class(source.data), sep=""))
#    print(paste('class(target.data)==', class(target.data), sep=""))
#   end debugging for Doug Nychka Mon, 13 Feb 2012 21:33:36 -0700
    source.title <- paste(
      datavar.name, " original, ",
      "Timestep: ", i.timestep, ", ",
      "Layer: ", i.layer,
      sep="")
    plot.layer(source.data, source.title, attrs.list, probabilities.vec, colors, map)
    target.title <- paste(
      datavar.name, " modified, ",
      "Timestep: ", i.timestep, ", ",
      "Layer: ", i.layer,
      sep="")
    plot.layer(target.data, target.title, attrs.list, probabilities.vec, colors, map)
  } # end interating layers
} # end function plot.before.and.after.layers.for.timestep

plot.layer <- function(
  data,             # data to plot
  title,            # string for plot title
  attrs.list,       # list of global attributes (used for plotting)
  probabilities.vec=NULL, # for quantiles # TODO: handle when null!
  colors,
  map
) {
  x.centers <- attrs.list$x.cell.centers.km
  y.centers <- attrs.list$y.cell.centers.km
  if (sum(!is.na(data))) {
    plot.list <- list(x=x.centers, y=y.centers, z=data)
    quantiles <- quantile(c(data), probabilities.vec, na.rm=TRUE)
    quantiles.formatted <- format(as.numeric(quantiles), digits=3)
# start debugging
#      print(paste('Non-null image.plot for source layer==', i.layer, ', quantile bounds=='))
#      print(quantiles)
#   end debugging
    image.plot(plot.list, xlab="", ylab="", axes=F, col=colors(100),
      axis.args=list(at=quantiles, labels=quantiles.formatted),
      main=title)
    lines(map)
  } else {
# debugging
#      print(paste('Null image.plot for source layer=', i.layer))
    plot(0, type="n", axes=F, xlab="", ylab="",
      xlim=range(x.centers), ylim=range(y.centers),
      main=title)
    lines(map)
  } # end testing data
} # end function plot.layer
