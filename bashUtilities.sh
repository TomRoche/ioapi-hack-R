# description---------------------------------------------------------

# Source me

# code----------------------------------------------------------------

# constants-----------------------------------------------------------

# TODO: read from CCTM Makefile
IOAPI_VERSION="3.1" # desired
NCO_VERSION="4.0.5" # desired
HPCC_IOAPI_LIB_PATH="/project/air5/roche/CMAQ-5-eval/lib/ioapi_${IOAPI_VERSION}"
HPCC_IOAPI_BIN_PATH="${HPCC_IOAPI_LIB_PATH}"
HPCC_NCO_PATH="/share/linux86_64/nco/nco-${NCO_VERSION}/bin"
TERRAE_IOAPI_MODULE="ioapi-${IOAPI_VERSION}"
TERRAE_NCO_MODULE="nco-${NCO_VERSION}" # in `module avail` as of May 2012

# functions-----------------------------------------------------------

# ensure IOAPI is on path
# TODO: ensure your hostname matches here!
function setup {
  H="$(hostname)"
  case "${H}" in
    terra*)
#      echo -e "${H} is on terrae"
      setupModules
      ;;
    amad*)
#      echo -e "${H} is on hpcc"
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_NCO_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    imaster*)
#      echo -e "${H} is on hpcc"
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_NCO_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    *)
      echo -e "unknown ${H}"
#      exit
      ;;
  esac
}

# add $1 to PATH if not already there
function addPath {
    DIR="$1"
    if [[ -n "${DIR}" ]] ; then
      if [ -d "${DIR}" ] ; then
        if [[ ":${PATH}:" != *":${DIR}:"* ]] ; then
          PATH="${DIR}:${PATH}"
        else
          echo -e "PATH contains '${DIR}'"
        fi
      else
        echo -e "ERROR: addPath: '${DIR}' is not a directory"
      fi
    else
      echo -e 'ERROR: addPath: DIR not defined'
    fi
}

# add $1 to LD_LIBRARY_PATH if not already there
function addLdLibraryPath {
    DIR="$1"
    if [[ -n "${DIR}" ]] ; then
      if [ -d "${DIR}" ] ; then
        if [[ ":${LD_LIBRARY_PATH}:" != *":${DIR}:"* ]] ; then
          LD_LIBRARY_PATH="${DIR}:${LD_LIBRARY_PATH}"
        else
          echo -e "LD_LIBRARY_PATH contains '${DIR}'"
        fi
      else
        echo -e "ERROR: addLdLibraryPath: '${DIR}' is not a directory"
      fi
    else
      echo -e 'ERROR: addLdLibraryPath: DIR not defined'
    fi
}

# If your computing platform uses Environment Modules (
# http://modules.sourceforge.net/
# ), load modules for current NCO and IOAPI, noting
# how this syntax differs from the commandline.
# (Thanks, Barron Henderson for noting this.)
# TODO: test for non/existence of paths above!
function setupModules {
  # for CMD in \
  #   "modulecmd bash add ${TERRAE_NCO_MODULE} ${TERRAE_IOAPI_MODULE}" \
  # ; do
  #   echo -e "$ ${CMD}"
  #   eval "${CMD}"
  # done
  TEMPFILE="$(mktemp)"
  modulecmd bash add ${TERRAE_NCO_MODULE} ${TERRAE_IOAPI_MODULE} > ${TEMPFILE}
  source ${TEMPFILE}
}

# Used to search for where we're losing var attr=missing_value
# Don't use return value, rely on side effect on stdout
function findAttributeInFile {
  ATTR_NAME="$1" # mandatory argument=attribute name
  NC_FP="$2"     # mandatory argument=path to a netCDF file
  if [[ -z "${ATTR_NAME}" ]] ; then
    echo -e 'ERROR: findAttribute: blank or missing attribute name'
    return 1
  fi
  if [[ -z "${NC_FP}" ]] ; then
    echo -e 'ERROR: findAttribute: blank or missing path to netCDF file'
    return 2
  fi
  if [[ ! -r "${NC_FP}" ]] ; then
    echo -e "ERROR: findAttribute: cannot read netCDF file='${NC_FP}'"
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
