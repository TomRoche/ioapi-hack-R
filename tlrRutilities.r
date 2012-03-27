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
