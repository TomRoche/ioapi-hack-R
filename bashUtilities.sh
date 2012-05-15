# description---------------------------------------------------------

# Source me

# code----------------------------------------------------------------

# constants-----------------------------------------------------------

# functions-----------------------------------------------------------

# If your computing platform uses Environment Modules (
# http://modules.sourceforge.net/
# ), load modules for current NCO and IOAPI, noting
# how this syntax differs from the commandline.
# (Thanks, Barron Henderson for noting this.)
# TODO: test for non/existence of paths above!
function setup {
  # for CMD in \
  #   "modulecmd bash add nco ioapi-3.1" \
  # ; do
  #   echo -e "$ ${CMD}"
  #   eval "${CMD}"
  # done
  TEMPFILE="$(mktemp)"
  modulecmd bash add nco ioapi-3.1 > ${TEMPFILE}
  source ${TEMPFILE}
}

# Used to search for where we're losing var attr=missing_value
# Don't use return value, rely on side effect on stdout
function findAttributeInFile {
  ATTR_NAME="$1" # mandatory argument=attribute name
  NC_FP="$2"     # mandatory argument=path to a netCDF file
  if [[ -z "${ATTR_NAME}" ]] ; then
    echo "ERROR: findAttribute: blank or missing attribute name"
    return 1
  fi
  if [[ -z "${NC_FP}" ]] ; then
    echo "ERROR: findAttribute: blank or missing path to netCDF file"
    return 2
  fi
  if [[ ! -r "${NC_FP}" ]] ; then
    echo "ERROR: findAttribute: cannot read netCDF file='${NC_FP}'"
    return 3
  fi

  # TODO: test these are in path
  for CMD in \
    "ncdump -h ${NC_FP} | fgrep -e '${ATTR_NAME}'" \
  ; do
    echo -e "$ ${CMD}"
    eval "${CMD}"
  done
}
