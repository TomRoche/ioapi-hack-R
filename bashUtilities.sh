# description---------------------------------------------------------

# Source me

# code----------------------------------------------------------------

# constants-----------------------------------------------------------

# TODO: take switches for help, debugging, no/eval, target drive

# Following does not work with `source`
# THIS="$0"
# THIS_FN="$(basename ${THIS})"
# THIS_DIR="$(dirname ${THIS})"

THIS="${HOME}/ioapi-hack-R/bashUtilities.sh"
THIS_FN="$(basename ${THIS})"
THIS_DIR="$(dirname ${THIS})"

# debugging: get commandline==all positional parameters
#echo -e "hostname=$(hostname): cmdline='${@}', THIS_DIR='${THIS_DIR}', THIS_FN='${THIS_FN}'"

# TODO: read from CCTM Makefile
IOAPI_VERSION="3.1" # desired
NCO_VERSION="4.0.5" # version on terrae; infinity has 4.0.8
HPCC_R_PATH="/share/linux86_64/bin"
# `ncdump` now on hpcc in /usr/bin
#HPCC_NCDUMP_PATH="/share/linux86_64/grads/supplibs-2.2.0/x86_64-unknown-linux-gnu/bin"
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
# as of 22 May 12, on the hpcc R servers NCO is installed normally, in /usr/bin
#      addPath "${HPCC_NCO_PATH}"
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_R_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    global*)
#      echo -e "${H} is on hpcc"
#      addPath "${HPCC_NCO_PATH}"
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_R_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    imaster*) # == infinity
#      echo -e "${H} is on hpcc"
      echo -e "For R packages such as ncdf4, must run on amad"
      addPath "${HPCC_NCO_PATH}"
      addPath "${HPCC_IOAPI_BIN_PATH}"
      addPath "${HPCC_R_PATH}"
      addLdLibraryPath "${HPCC_IOAPI_LIB_PATH}"
      ;;
    inode*) # == node39
#      echo -e "${H} is on hpcc"
      echo -e "For R packages such as ncdf4, must run on amad"
      addPath "${HPCC_NCO_PATH}"
      addPath "${HPCC_IOAPI_BIN_PATH}"
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
        echo -e "ERROR: ${THIS_FN}:addPath: '${DIR}' is not a directory" 1>&2
      fi
    else
      echo -e "ERROR: ${THIS_FN}:addPath: DIR not defined" 1>&2
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
        echo -e "ERROR: ${THIS_FN}:addLdLibraryPath: '${DIR}' is not a directory" 1>&2
      fi
    else
      echo -e "ERROR: ${THIS_FN}:addLdLibraryPath: DIR not defined" 1>&2
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
# * if output path already exists, it gets overwritten
function stripOtherDatavars {
  VAR_NAME="$1"
  INPUT_FP="$2"
  OUTPUT_FP="$3"
  if [[ -r "${OUTPUT_FP}" ]] ; then
    if [[ -w "${OUTPUT_FP}" ]] ; then
      DEBUG echo -e "ERROR? ${FUNCNAME[0]}: output file='${OUTPUT_FP}' already exists"
    else
      echo -e "ERROR: ${FUNCNAME[0]}: output file='${OUTPUT_FP}' exists but can't be written" 1>&2
      exit 1
    fi
  fi
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
      "rm ${RAW_STRIPPED_FP}" \
    ; do
      echo -e "$ ${CMD}"
      eval "${CMD}"
    done
#    ncdump -v TFLAG ${OUTPUT_FP}
    export M3STAT_FILE="${OUTPUT_FP}"
  else
    echo -e "ERROR: ${THIS_FN}:stripOtherDatavars: script='${FIX_VARS_SCRIPT}' is not readable" 1>&2
    exit 2
  fi # end testing -x "${FIX_VARS_SCRIPT}"
} # end function stripOtherDatavars

# "Comments" lines from running iff _DEBUG='on' (which can be export'ed by caller),
# and runs with `set xtrace`
# For `echo`, use DEBUG()
function DEBUGx {
  if [[ "${_DEBUG}" == 'on' ]] ; then
    set -x
    "$@" 1>&2
    set +x
  fi
} # end function DEBUG

# "Comments" lines from running iff _DEBUG='on'
# (which can be export'ed by caller)
function DEBUG {
  if [[ "${_DEBUG}" == 'on' ]] ; then
    "$@" 1>&2
  fi
} # end function DEBUG

# Stop if cannot find datavar in file. kludged implementation!
# CONTRACT: arguments tested by caller
function exitIfDatavarNotFound {
  NETCDF_FP="$1"
  VAR_NAME="$2"
  VAR_ATTR_NAME="$3"
  VAR_ATTR_VAL="$4"
  KEY_NAME="${VAR_NAME}:${VAR_ATTR_NAME}"
  # add no single quotes to search command!
  SEARCH_RESULTS="$(ncdump -h ${NETCDF_FP} | fgrep -e ${KEY_NAME} | fgrep -e ${VAR_ATTR_VAL})"
  if [[ -z "${SEARCH_RESULTS}" ]] ; then
    echo -e "ERROR: ${THIS_FN}:exitIfDatavarNotFound: could not find varname='${VAR_NAME}' in netCDF file='${NETCDF_FP}'" 1>&2
    exit 1
  else
    DEBUG echo -e "${FUNCNAME[0]}: 'ncdump -h ${NETCDF_FP} | fgrep -e ${KEY_NAME} | fgrep -e ${VAR_ATTR_VAL}' found ${SEARCH_RESULTS}"
  fi
}

# Stop on finding datavar in file. kludged implementation!
# CONTRACT: arguments tested by caller
function exitIfDatavarIsFound {
  NETCDF_FP="$1"
  VAR_NAME="$2"
  VAR_ATTR_NAME="$3"
  VAR_ATTR_VAL="$4"
  KEY_NAME="${VAR_NAME}:${VAR_ATTR_NAME}"
  # add no single quotes to search command!
  SEARCH_RESULTS="$(ncdump -h ${NETCDF_FP} | fgrep -e ${KEY_NAME} | fgrep -e ${VAR_ATTR_VAL})"
  if [[ -n "${SEARCH_RESULTS}" ]] ; then
    echo -e "ERROR: ${THIS_FN}:exitIfDatavarIsFound: found varname='${VAR_NAME}' in netCDF file='${NETCDF_FP}'" 1>&2
    exit 1
  else
    DEBUG echo -e "${FUNCNAME[0]}: nothing found for 'ncdump -h ${NETCDF_FP} | fgrep -e ${KEY_NAME} | fgrep -e ${VAR_ATTR_VAL}'"
  fi
}

# Stop if cannot find attribute.
# For datavar attribute, pass datavar name in $3; else, omit or pass null string.
# Don't use return value, rely on side effect on stdout.
# CONTRACT: dependency availability, arguments tested by caller
function findAttributeInFile {
  ATTR_NAME="$1"
  NETCDF_FP="$2"
  VAR_NAME="$3"
  KEY_NAME="${VAR_NAME}:${VAR_ATTR_NAME}" # note colon needed for `ncdump`
  # add no single quotes to search command! which is our "return value"
  ncdump -h "${NETCDF_FP}" | fgrep -e "${KEY_NAME}"
} # end function findAttributeInFile

# Stop if cannot find datavar in file. kludged implementation!
# Don't use return value, rely on side effect on stdout.
# CONTRACT: dependency availability, arguments tested by caller
function findDatavarInFile {
  VAR_NAME="$1"
  NETCDF_FP="$2"
  # kludge: also pass the name of an attribute of the datavar, since we're only `ncdump`ing
  VAR_ATTR_NAME="$3"
  findDatavarAttributeInFile "${VAR_ATTR_NAME}" "${NETCDF_FP}" "${VAR_NAME}"
} # end function findDatavarInFile
