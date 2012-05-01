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

    # get stats for subtitle
    plot.layer(data,
    title=title,
#    sub="subtitle",
    sub=subtitle.stats(data),
    attrs.list=attrs.list,
    q.vec=q.vec,
    colors=colors,
    map=map)
  } # end interating layers
} # end function plot.layers.for.timestep

subtitle.stats <- function(vec) {
  return.str <- ""
  # is it numeric, and not empty?
  if (is.numeric(vec) && sum(!is.na(vec))) {
#    unsparse.vec <- subset(vec, !is.na(vec)) # fail: intended for interactive use
#    unsparse.vec <- na.omit(vec) # fail: omits all *rows* containing an NA!
    unsparse.vec <- vec[!is.na(vec)]
    len <- length(unsparse.vec)
    len.str <- sprintf('obs=%i', len)
    min <- min(unsparse.vec)
    min.str <- sprintf('min=%f', min)
    med <- median(unsparse.vec)
    med.str <- sprintf('med=%f', med)
    max <- max(unsparse.vec)
    max.str <- sprintf('max=%f', max)
    return.str <-
      sprintf('%s: %s, %s, %s', len.str, min.str, med.str, max.str)
  } else {
    return.str <-"no data"
  }
  return.str
} # end function subtitle.stats

plot.before.and.after.layers.for.timestep <- function(
  source.datavar,   # source/unmodified data variable
  target.datavar,   # target/modified data variable
  datavar.name,     # string naming the datavar
  i.timestep=1,     # index of timestep to plot
  datavar.n.layers, # max number of layers (in timestep) to plot
  attrs.list,       # list of global attributes
  q.vec=NULL,       # for quantiles # TODO: handle when null!
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

    source.title <-
      sprintf('%s original: layer#=%2i', datavar.name, i.layer)
#    source.title <-
#      sprintf('%s original: layer#=%2i (%s) # when we have the crop name
    target.title <-
      sprintf('%s modified: layer#=%2i', datavar.name, i.layer)
#    target.title <-
#      sprintf('%s modified: layer#=%2i (%s) # when we have the crop name
    attr.list <-
      ncatt_get(datavar.parent, varid=datavar.name, attname="units")
    if (attr.list$hasatt) {
      source.title <-
        sprintf('%s, units=%s', source.title, attr.list$value)
      target.title <-
        sprintf('%s, units=%s', target.title, attr.list$value)
    } else {
      cat(sprintf(
        'plot.layers.for.timestep: ERROR: no units for var=%s\n',
        datavar.name))
    }
    plot.layer(source.data,
      title=source.title,
#      sub="subtitle",
      sub=subtitle.stats(data),
      attrs.list=attrs.list,
      q.vec=q.vec,
      colors=colors,
      map=map)
    plot.layer(target.data,
      title=target.title,
#      sub="subtitle",
      sub=subtitle.stats(data),
      attrs.list=attrs.list,
      q.vec=q.vec,
      colors=colors,
      map=map)
  } # end interating layers
} # end function plot.before.and.after.layers.for.timestep

plot.layer <- function(
  data,             # data to plot (required)
  title,            # string for plot title (required?)
                    # TODO: handle when null!
  subtitle=NULL,    # string for plot subtitle
  attrs.list=NULL,  # list of global attributes (used for plotting)
  q.vec=NULL,       # for quantiles
  colors,
  map
) {
  x.centers <- attrs.list$x.cell.centers.km
  y.centers <- attrs.list$y.cell.centers.km
  if (sum(!is.na(data)) && (!is.null(q.vec))) {
    plot.list <- list(x=x.centers, y=y.centers, z=data)
    quantiles <- quantile(c(data), q.vec, na.rm=TRUE)
    quantiles.formatted <- format(as.numeric(quantiles), digits=3)
# start debugging
#      print(paste('Non-null image.plot for source layer==', i.layer, ', quantile bounds=='))
#      print(quantiles)
#   end debugging
    image.plot(plot.list, xlab="", ylab="", axes=F, col=colors(100),
      axis.args=list(at=quantiles, labels=quantiles.formatted),
#      main=title)
      main=title, sub=subtitle)
    lines(map)
  } else {
# debugging
#      print(paste('Null image.plot for source layer=', i.layer))
    plot(0, type="n", axes=F, xlab="", ylab="",
      xlim=range(x.centers), ylim=range(y.centers),
#      main=title)
      main=title, sub=subtitle)
    lines(map)
  } # end testing data
} # end function plot.layer
