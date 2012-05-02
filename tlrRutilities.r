# Tom Roche R utilities that don't fit anywhere else.

# For dealing with data like
# > ERROR: for gridcell==[ 30,161], both crop and BELD data are not empty, but their product==0
# > crop data==
# >  [1] NA NA NA NA  0 NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA
# > [26] NA NA NA NA NA NA NA NA NA NA NA  0  0 NA NA NA NA
# Return TRUE if every member of the vector is NA or 0, else FALSE.
is.vec.na.or.zero <- function(vec) {
# debugging
#  print('is.vec.na.or.zero: vec==')
#  print(vec)
  # Note this code does not work (i.e. does not return properly) if not wrapped in `if`
  if        (!sum(!is.na(vec))) {
    TRUE
  } else if (sum(subset(vec, !is.na(vec))) == 0) {
    TRUE
  } else {
    FALSE
  }
}

# for values, instead of vectors
# TODO: write generic
# TODO? equivalence tolerance for numeric but not integer
is.val.na.or.zero <- function(val) {
  if (is.na(val) || (val == 0)) {
    TRUE
  } else {
    FALSE
  }
}

# TODO: testcases!

# Fix passed monotonicized sparse matrix: thanks KMF!
# Why a function? because function=apply needs one.
demonotonicize.layer <- function(mx) {
  # why this? because because function=apply needs an array (of which a matrix is an instance)
  mx.vec <- matrix(mx)
  if (sum(!is.na(mx))) {
    # store results here
    result.vec <- mx.vec
    # vectorially extract the non-NA values (package=base.subset)
    minuend.vec <- subset(mx.vec, !is.na(mx.vec))
    # subtrahend.vec has values shifted to right ...
    subtrahend.vec <- c(0, minuend.vec[1:(length(minuend.vec)-1)])
    # ... to do vector subtraction (minuend − subtrahend = result)
    result.vec[!is.na(mx.vec)] <- (minuend.vec - subtrahend.vec)
    # note: explicit `return` halts execution!
    result.vec
  } else {
    mx.vec
  }
}

# Read a very-simple (input) CSV file into an "R dictionary": an "environment"
# Note a candidate input.csv has
# * a known number of header lines, to be ignored 
# * ... followed by data lines, each with 2 fields: index (which must be character) and value
# * line datatypes are defined by vec.line.types: see help(scan):Details

# TODO: validate inputs

csv.read.to.environment <- function(
  input.fp,             # path to input.csv file
  n.header.lines,       # number of header lines (to ignore) TODO: just ignore comments!
  vec.line.types        # types of fields in each CSV line
) {
  n.data.fields <- 2    # TODO: ensure match with vec.line.types
  ret.env <- new.env()  # return value
  i.lines <- 0
  n.lines <- 0
  i.errors <- 0
  input.con <- file(input.fp, "rt") # read-only file connection, text mode
  on.exit(close(input.con))

  while (length(line <- readLines(input.con, 1)) > 0) {
    i.lines <- i.lines + 1
    # skip header, could also do with scan(..., skip=n.header.lines)
    if (i.lines <= n.header.lines) { next }
# debugging
#    print(paste(i.lines,':', line))
    # parse comma-separated variables
    raw <- scan(textConnection(line), sep=",", quiet=TRUE, what=vec.line.types)
    if (length(raw) >= n.data.fields) {
      # process good line:
      index <- as.character(raw[1])
      value <- raw[2]
      ret.env[[index]] <- value
    } else {
      # bad line. TODO: throw
      i.errors <- i.errors + 1
      error.line.numbers[i.errors] <- i.lines
      cat(sprintf(
        'ERROR: csv.read.to.environment error#=%i @ line#=%i: %s\n',
        i.lines, i.errors, line))
    } # end testing raw scan
    n.lines <- i.lines
  } # end while'ing lines

# start debugging
#  cat(sprintf(
#    'csv.read.to.environment: read lines=%i, with errors=%i\n',
#    n.lines, n.errors))
#   end debugging

  ret.env # return
} # end function csv.read.to.environment(...)
