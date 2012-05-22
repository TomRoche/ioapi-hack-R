# description---------------------------------------------------------

# Source me

# code----------------------------------------------------------------

# constants-----------------------------------------------------------

# TODO: take switches for help, debugging, no/eval, target drive
THIS="$0"
THIS_FN="$(basename $0)"
THIS_DIR="$(dirname $0)"

# TODO: read from CCTM Makefile
IOAPI_VERSION="3.1" # desired
NCO_VERSION="4.0.5" # desired
HPCC_R_PATH="/share/linux86_64/bin"
HPCC_NCDUMP_PATH="/share/linux86_64/grads/supplibs-2.2.0/x86_64-unknown-linux-gnu/bin"
HPCC_IOAPI_LIB_PATH="/project/air5/roche/CMAQ-5-eval/lib/ioapi_${IOAPI_VERSION}"
HPCC_IOAPI_BIN_PATH="${HPCC_IOAPI_LIB_PATH}"
HPCC_NCO_PATH="/share/linux86_64/nco/nco-${NCO_VERSION}/bin"
TERRAE_IOAPI_MODULE="ioapi-${IOAPI_VERSION}"
TERRAE_NCO_MODULE="nco-${NCO_VERSION}" # in `module avail` as of May 2012
# this fixes removed vars, and dims and global attributes that must reflect them
FIX_VARS_SCRIPT="${THIS_DIR}/processVars.r"

# functions-----------------------------------------------------------

# ensure IOAPI is on path
# TODO: ensure your hostname matches here!
# TODO: setup packages={ncdf4} on infinity, not just amad
function setupPaths {
  H="$(hostname)"
  case "${H}" in
    terra*)
#      echo -e "${H} is on terrae"
      setupModules
      ;;
    amad*)
#      echo -e "${H} is on hpcc"
# ERROR: addPath: '/share/linux86_64/nco/nco-4.0.5/bin' is not a directory
# ERROR: addPath: '/share/linux86_64/grads/supplibs-2.2.0/x86_64-unknown-linux-gnu/bin' is not a directory
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_NCO_PATH}"
      addPath "${HPCC_NCDUMP_PATH}"
      addPath "${HPCC_R_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    imaster*)
#      echo -e "${H} is on hpcc"
      echo -e "For R packages such as ncdf4, must run on amad"
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_NCO_PATH}"
      addPath "${HPCC_NCDUMP_PATH}"
      addPath "${HPCC_R_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    *)
      echo -e "unknown ${H}"
#      exit 1
      ;;
  esac
} # end function setupPaths

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
} # end function findAttributeInFile

# Window a single IOAPI file. Convenience for callers.
# CONTRACT:
# * arguments are not checked here, must be checked by callers
# * m3tools/m3wndw must be in path
# * INFP != OUFP: m3wndw wants separate handles
function windowFile {
  # EMPIRICAL NOTE:
  # m3wndw (perhaps all of m3tools) truncate envvars @ length=16!
  # e.g., "M3WNDW_INPUT_FILE" -> "M3WNDW_INPUT_FIL", which fails lookup.
  # ASSERT: good arguments, must be tested by caller
  export INFP="$1"
  export OUFP="$2"
  M3WNDW_INPUT_FP="$3"
  # INFP, OUFP are handles for `m3wndw`: don't substitute in shell!

# start debugging
#  echo -e "windowFile: about to call m3wndw with INFP='${INFP}', OUFP='${OUFP}', M3WNDW_INPUT_FP='${M3WNDW_INPUT_FP}'"
#   end debugging

  for CMD in \
    "ls -alt ${INFP} ${OUFP} ${M3WNDW_INPUT_FP}" \
    "m3wndw INFP OUFP < ${M3WNDW_INPUT_FP}" \
    "ls -alt ${INFP} ${OUFP}" \
    "ncdump -h ${OUFP} | head -n 20" \
  ; do
    echo -e "$ ${CMD}"
    eval "${CMD}"
  done
} # end function windowFile

# Remove all netCDF datavars other than the one named by VAR_NAME.
# For IOAPI, subsequently gotta fix
# * global attr=VAR-LIST
# * coordinate var=VAR
# * data var=TFLAG
# Note I copy files to output, *then* work on them, because that's what
# R package=ncdf4 seems to want.
# CONTRACT:
# * arguments are not checked here, must be checked by callers
# * nco/ncks must be in path
function stripOtherDatavars {
  VAR_NAME="$1"
  INPUT_FP="$2"
  OUTPUT_FP="$3"
  if [[ -r "${FIX_VARS_SCRIPT}" ]] ; then

    TEMPFILE="$(mktemp)" # for R output
    INPUT_FN="$(basename ${INPUT_FP})"
    INPUT_PREFIX="${INPUT_FN%.*}"
    INPUT_SUFFIX="${INPUT_FN##*.}"
    OUTPUT_DIR="$(dirname ${OUTPUT_FP})"
    RAW_STRIPPED_FP="${OUTPUT_DIR}/${INPUT_PREFIX}_stripped.${INPUT_SUFFIX}"
  # start debugging
#    echo -e "INPUT_PREFIX='${INPUT_PREFIX}'"
#    echo -e "INPUT_SUFFIX='${INPUT_SUFFIX}'"
#    echo -e "RAW_STRIPPED_FP='${RAW_STRIPPED_FP}'"
  #   end debugging

    # gotta quote the double quotes :-(
    # need INPUT_FP to get original TFLAG?
    for CMD in \
      "ncks -O -v ${VAR_NAME},TFLAG ${INPUT_FP} ${RAW_STRIPPED_FP}" \
      "cp ${RAW_STRIPPED_FP} ${OUTPUT_FP}" \
      "R CMD BATCH --vanilla --slave '--args \
  datavar.name=\"${VAR_NAME}\" \
  epic.input.fp=\"${RAW_STRIPPED_FP}\" \
  epic.output.fp=\"${OUTPUT_FP}\" \
  ' \
  ${FIX_VARS_SCRIPT} ${TEMPFILE}" \
      "cat ${TEMPFILE}" \
    ; do
      echo -e "$ ${CMD}"
      eval "${CMD}"
    done
#    ncdump -v TFLAG ${OUTPUT_FP}
    export M3STAT_FILE="${OUTPUT_FP}"
  else
    echo -e "ERROR: stripOtherDatavars: script='${FIX_VARS_SCRIPT}' is not readable"
    exit 2
  fi # end testing -x "${FIX_VARS_SCRIPT}"
} # end function stripOtherDatavars
