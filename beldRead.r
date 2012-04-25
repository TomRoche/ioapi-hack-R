# Read a BELD CSV file into a form more usable for calculating emissions on an EPIC IOAPI grid.
# Note that a BELD CSV file have the form [header, data ...], e.g.,

# BELD4crops_12km_6_13_11.csv
# > CROPID,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63

# where the first line is crop IDs.
# These can be mapped into EPIC layers by subtracting 21 from each.

# All subsequent (data) lines have the form
# [gridcell ID, % cover of crop ID on that gridcell]

# > 5718,0.3,0.47,0,0,0,0,0,0,0,0,0.08,0.37,0,0,0.83,1.55,0,0,0,0,0,0,0,0,0,0.00,2.48,2.33,0.17,0,0,0,0,0,0,0.00,10.69,0.18,0,0,0,0...
# > 6176,1.91,2.98,0,0,0.01,0,0,0,0,0,0.05,0.25,0,0,0.56,1.04,0,0,0,0,0,0,0,0,0,0.00,1.67,1.57,0.12,0,0,0,0,0,0,0.00,6.83,0.12,0,0,0,0...

# where the number of fields read/used in each line == n.data.fields (below). ALL SUBSEQUENT FIELDS WILL BE IGNORED.

# The gridcell ID maps to EPIC (or other 12km CONUS LCC grids) like
# Ran, Limei Wed, 22 Feb 2012 14:24:17 +0000
# > GRIDID = (row-1) * 459 + col [and]
# > GRIDID starts from the LL corner as 1 going right and up

# The following functions seek to

# 1 strip the header (which has length==n.header.lines)

# 2 convert the data into a 3D array more consumable for emissions calculations, with dimensions
# cols x rows x layers
# where

# 2.1 cols x rows == the grid space of the matching EPIC output

# 2.2 layers == proportion of the crop specie represented by that layer
#     present in the gridcell == [cols, rows]

# Task 2.2 requires only dividing by 100.
# Task 2.1 is more difficult, since the single integer only ambiguously refers to a gridcell.
# The implementations of function int2gridcell (below) provide several two means of resolving this.

# Consider an example with i.gridcell== 27, n.cols==5, n.rows==7.
# Note that i.gridcell %/% n.cols == 5 == i.gridcell mod n.cols
#           i.gridcell  %% n.cols == 2 == i.gridcell rem n.cols
#           i.gridcell %/% n.rows == 3 == i.gridcell mod n.rows
#           i.gridcell  %% n.rows == 6 == i.gridcell rem n.rows

# If we count from top left, going right then down, 27 -> 6,2
# i.rows <- (i.gridcell %/% n.cols) + 1 == 6
# since we start in row 1, not row 0^^^
# i.cols <- (i.gridcell %%  n.rows) - 1 == 2

# returns c(cols, rows) for BELD gridcell ID
int2gridcell <- function(
  i.gridcell,   # int mapping to gridcell in a BELD data line,
                # 0 < i.gridcell <= n.max
  n.cols=459,   # number of cols in gridspace (CONUS -> 459)
  n.rows=299,   # number of rows in gridspace (CONUS -> 299)
  n.max=137241  # max gridcell ID, default==n.cols * n.rows
) {
  if        (i.gridcell <= 0) {
    # TODO: throw
    cat(sprintf('ERROR: int2gridcell: i.gridcell==%d <= 0\n', i.gridcell))
    ret.vec <- c(0,0)
  } else if (i.gridcell > n.max) {
    # TODO: throw
    cat(sprintf('ERROR: int2gridcell: i.gridcell==%d, max==%d\n', i.gridcell, n.max))
    ret.vec <- c(0,0)
  } else {
    modulus <- n.cols
    remainder <- i.gridcell %% modulus
    if (remainder == 0) {
      i.rows <- floor(i.gridcell/modulus)
      i.cols <- n.cols
    } else {
      # since we start in row=1, not row=0
      i.rows <- floor(i.gridcell/modulus) +1
      i.cols <- remainder
    }
    ret.vec <- c(i.cols,i.rows)
  }
# debugging
#  cat(sprintf('int2gridcell: mode==%s, mod==%i, grid==%i -> [col, row]==[%i,%i]\n',
#    mode, modulus, i.gridcell, i.cols, i.rows))
  ret.vec
} # end function int2gridcell

# Inputs
# * path==beld.fp to a row-oriented BELD CSV file
# * dim==datavar.dim, i.e., the dimensions of the matching EPIC data variable
# * mode==string used in int2gridcell (above)

# TODO: validate inputs
  
# Outputs a 3-dim BELD proportions array s.t.
# * dim(output) == cols x rows x layers
# * cols x rows == the grid space of the matching EPIC output
#   TODO: get this from passed datavar object
# * layers == proportion of the crop specie represented by that layer
#   present in the gridcell with index == [cols, rows]

beld.read <- function(beld.fp, datavar.dim, n.header.lines, n.data.fields, list.line.types) {
  datavar.cols.n <- datavar.dim[1]
  datavar.rows.n <- datavar.dim[2]
  datavar.layers.n <- datavar.dim[3]
  # return value
  beld.array <- rep(NA, datavar.cols.n * datavar.rows.n * datavar.layers.n)
  dim(beld.array) <- c(datavar.cols.n, datavar.rows.n, datavar.layers.n)

  i.lines <- 0
  n.lines <- 0
  i.errors <- 0
  error.line.numbers <- numeric()

# Thanks to Bill Dunlap for the pointer to connection objects
# https://mail.google.com/mail/u/0/?tab=cm#search/label%3aR+connection/1348b9421afad29d
# https://stat.ethz.ch/pipermail/r-help/2011-December/299325.html

  beld.con <- file(beld.fp, "rt")  # open input file connection, text mode
  on.exit(close(beld.con))

  while (length(line <- readLines(beld.con, 1)) > 0) {
    i.lines <- i.lines + 1
    if (i.lines <= n.header.lines) { next } # skip header, could also do with scan(..., skip=n.header.lines)
# debugging
#    print(paste(i.lines,':', line))
    # parse comma-separated variables
    raw <- scan(textConnection(line), sep=",", quiet=TRUE, what=list.line.types)
    if (length(raw) >= n.data.fields) {
      # process good line:
      # note that, if typeof(raw)==list, must cast to numeric (vector)
      i.gridcell <- as.numeric(raw[1])
      beld.data.raw <- as.numeric(raw[2:n.data.fields])
# start debugging
#      print(paste('beldRead: typeof(beld.data.raw)=', typeof(beld.data.raw)))
#      print(paste('beldRead: beld.data.raw=', beld.data.raw))
#   end debugging
      
      # raw BELD data is percentage, convert to proportion
      beld.data <- beld.data.raw / 100.0
      colrow <- int2gridcell(i.gridcell,
                  datavar.cols.n, datavar.rows.n,
                  datavar.cols.n * datavar.rows.n)
      i.cols <- colrow[1]
      i.rows <- colrow[2]

      if ((i.rows <= datavar.rows.n) && (i.cols <= datavar.cols.n)) {
        # write beld.data to that "location" ... after testing beld.data?
        # no: most locations are fully cropped, so don't sum anywhere near 1
#        if (sum(beld.data) == 1.0) {
          beld.array[i.cols, i.rows,] <- beld.data
#        } else {
#          # bad line. TODO: throw
#          print(paste(
#            'ERROR: line#=', i.lines, ': sum(BELD data)=', sum(beld.data)))
#          print(paste('BELD data=', beld.data))
#        } # end testing beld.data

      } else {
        # bad line. TODO: throw
        print(paste(
          'ERROR: beldRead: line#=', i.lines, 'i.gridcell=', i.gridcell,
           '-> i.rows=', i.rows, ', i.cols=', i.cols))
      } # end testing line processing

    } else {
      # bad line. TODO: throw
      i.errors <- i.errors + 1
      error.line.numbers[i.errors] <- i.lines
      print(paste(
        'ERROR: beldRead: line#=', i.lines, 'length=', length(raw), 'class=', class(raw)))
      print(paste('line=', line))
    } # end testing raw scan
    n.lines <- i.lines
  } # end while'ing lines

# start debugging
#  n.errors <- length(error.line.numbers)
#  print(paste(
#    'read lines=', n.lines, ' with errors=', n.errors))
#  if (n.errors > 0) {
#    print(paste('errors in line#s=', error.line.numbers))
#  }
#   end debugging

  beld.array # return
} # end function beld.read(beld.fp)
