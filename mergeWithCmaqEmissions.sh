#!/usr/bin/env bash

# description---------------------------------------------------------

# A top-level driver for github project=ioapi-hack-R. See ./README
# https://github.com/TomRoche/ioapi-hack-R/blob/master/README

# code----------------------------------------------------------------

# constants-----------------------------------------------------------

# TODO: take switches for help, debugging, no/eval, target drive
THIS="$0"
THIS_FN="$(basename $0)"
THIS_DIR="$(dirname $0)"

# name of the EPIC datavar
INPUT_VAR_NAME="DN2"
# name of specie/datavar to be created in CMAQ-5 emissions
let VAR_LIST_FIELD_LENGTH=16
OUTPUT_VAR_NAME_IOAPI_FORMATTED="N2O             " # field length=${VAR_LIST_FIELD_LENGTH}
OUTPUT_VAR_NAME="${OUTPUT_VAR_NAME_IOAPI_FORMATTED%% *}"
#echo -e "OUTPUT_VAR_NAME='${OUTPUT_VAR_NAME}'"
# Replace the IOAPI datavar attr long_name with new datavar name.
# For string attributes, use type='c', not type='sng'?
NCATTED_LONG_NAME_STRING="long_name,${OUTPUT_VAR_NAME},m,c,${OUTPUT_VAR_NAME_IOAPI_FORMATTED}"
# replace the IOAPI global attr VAR-LIST with new datavar name
NCATTED_VAR_LIST_STRING="VAR-LIST,global,m,c,${OUTPUT_VAR_NAME_IOAPI_FORMATTED}"
DIM_RECORD="TSTEP" # name of the record dimension
JUNK_SPECIE_NAME='ACROLEIN' # any will do. how to just "get one"?

# Following is only required to make NCO happy:
# NCO requires datavars with attribute=missing_value to also have attribute=_FillValue
# TODO: find out how to get this programmatically!
VAR_MISSING_VALUE_NAME='missing_value'
VAR_MISSING_VALUE_VAL='-9.999e+36'
VAR_MISSING_VALUE_PREC='float'

# input data from EPIC via computeCropSum.sh
EPIC_DIR="${THIS_DIR}"
EPIC_INPUT_FN="5yravg.${INPUT_VAR_NAME}windowed.nc"
EPIC_INPUT_FP="${EPIC_DIR}/${EPIC_INPUT_FN}"
# the ZERO-BASED index of the layer containing the integrated EPIC emissions
# TODO: either get last layer index from ${EPIC_INPUT_FN}, or get this from computeCropSum.sh
let EPIC_DATA_LAYER_INDEX=43

# Windowing bounds:
WINDOWING_FN="windowingConstants.sh"
WINDOWING_FP="${EPIC_DIR}/${WINDOWING_FN}"
source "${WINDOWING_FP}"
#echo -e "M3WNDW_INPUT_FP='${M3WNDW_INPUT_FP}'"

# bash utilities
BASH_UTILS_FN="bashUtilities.sh"
BASH_UTILS_FP="${EPIC_DIR}/${BASH_UTILS_FN}"
source "${BASH_UTILS_FP}"

# input raw CMAQ emissions data
# path setup for infinity, terrae: other users must change!
CMAQ_EMISSIONS_DIR="${THIS_DIR}/data/emis/raw"
# TODO: get dates from CCTM run script
CMAQ_EMISSIONS_DATE_START="20060719"
CMAQ_EMISSIONS_DATE_END="20060731"
CMAQ_EMISSIONS_FN_TEMPLATE="emis_mole_all_%DATE%_12US1_cmaq_cb05_tx_C25_2006am.ncf"
# output cooked CMAQ emissions data
TEST_EMISSIONS_FN_TEMPLATE="emis_mole_plus${OUTPUT_VAR_NAME}_%DATE%_windowed.ncf"
# path setup for infinity, terrae: other users must change!
TEST_EMISSIONS_DIR="${THIS_DIR}/data/emis/cooked"
# holder for EPIC emissions for *every* date/hour
HOUR_EMISSIONS_FN="emis_mole_only${OUTPUT_VAR_NAME}_windowed.ncf"
HOUR_EMISSIONS_FP="${TEST_EMISSIONS_DIR}/${HOUR_EMISSIONS_FN}"

#---------------------------------------------------------------------

# windows CMAQ emissions to subdomain
WINDOW_CMAQ_SCRIPT_FN="windowCMAQemissions.r" # or reuse windowEmissions.r?
WINDOW_CMAQ_SCRIPT_FP="${EPIC_DIR}/${WINDOW_CMAQ_SCRIPT_FN}"
# fixes created layers, and global attributes that must reflect them
FIX_LAYERS_SCRIPT_FN="processLayers.r"
FIX_LAYERS_SCRIPT_FP="${EPIC_DIR}/${FIX_LAYERS_SCRIPT_FN}"
# writes EPIC data to CMAQ
EPIC_TO_CMAQ_SCRIPT_FN="writeEPICdata.r"
EPIC_TO_CMAQ_SCRIPT_FP="${EPIC_DIR}/${EPIC_TO_CMAQ_SCRIPT_FN}"

# functions-----------------------------------------------------------

# TODO: test for resources, reuse if available
# * m3wndw redirect file
# * container for EPIC hourly emissions
function setup {
  setupPaths
} # end function setup

# Window the set of CMAQ-5 emissions files.
function windowCMAQemissions {
  # TODO: make loop increment dates, not just integers
  for (( I=${CMAQ_EMISSIONS_DATE_START}; I<=${CMAQ_EMISSIONS_DATE_END}; I++ )) ; do
#    echo -e "date='${I}'"
    # single-quotes around the sed operator fail
    CMAQ_EMISSIONS_FN="$(echo -e ${CMAQ_EMISSIONS_FN_TEMPLATE} | sed -e s/%DATE%/${I}/)"
    TEST_EMISSIONS_FN="$(echo -e ${TEST_EMISSIONS_FN_TEMPLATE} | sed -e s/%DATE%/${I}/)"
#    echo -e "CMAQ_EMISSIONS_FN='${CMAQ_EMISSIONS_FN}'"
#    echo -e "TEST_EMISSIONS_FN='${TEST_EMISSIONS_FN}'"
    CMAQ_EMISSIONS_FP="${CMAQ_EMISSIONS_DIR}/${CMAQ_EMISSIONS_FN}"
    TEST_EMISSIONS_FP="${TEST_EMISSIONS_DIR}/${TEST_EMISSIONS_FN}"
    if [[ -n "${CMAQ_EMISSIONS_FP}" ]] ; then
      if [[ -n "${TEST_EMISSIONS_FP}" ]] ; then
        if [[ ! -r "${TEST_EMISSIONS_FP}" ]] ; then
          if [[ -n "${M3WNDW_INPUT_FP}" && -r "${M3WNDW_INPUT_FP}" ]] ; then
            if [[ -r "${CMAQ_EMISSIONS_FP}" ]] ; then
              # process the file
              # TODO: add M3WNDW_INPUT_FP, test it
              for CMD in \
                "windowCMAQemissionsFile ${CMAQ_EMISSIONS_FP} ${TEST_EMISSIONS_FP} ${M3WNDW_INPUT_FP}" \
              ; do
                echo -e "$ ${CMD}"
                eval "${CMD}"
              done
            else
              echo -e "ERROR: windowCMAQemissions: cannot read CMAQ emissions file='${CMAQ_EMISSIONS_FP}'"
              exit 1
            fi # end testing -r "${CMAQ_EMISSIONS_FP}"
          else
            echo -e "ERROR: windowCMAQemissions: m3wndw input file='${M3WNDW_INPUT_FP}' not found"
            exit 2
          fi
        else
          echo -e "error? windowCMAQemissions: output emissions file='${TEST_EMISSIONS_FP}' exists, will not recreate"
#          exit 3
        fi # end testing ! -r "${TEST_EMISSIONS_FP}"
      else
        echo -e 'ERROR: windowCMAQemissions: output emissions file path not defined'
        exit 4
      fi # end testing -n "${TEST_EMISSIONS_FP}"
    else
      echo -e 'ERROR: windowCMAQemissions: CMAQ emissions file path not defined'
      exit 5
    fi # end testing -n "${CMAQ_EMISSIONS_FP}"
  done # end incrementing dates
} # end function windowCMAQemissions

# Window a single CMAQ-5 emissions file.
# Called by windowCMAQemissions, not top-level.
# TODO: test for arguments
function windowCMAQemissionsFile {
  # EMPIRICAL NOTE:
  # m3wndw (perhaps all of m3tools) truncate envvars @ length=16!
  # e.g., "M3WNDW_INPUT_FILE" -> "M3WNDW_INPUT_FIL", which fails lookup.
  # ASSERT: good arguments, must be tested by caller
  CMAQ_EMISSIONS_FP="$1"
  TEST_EMISSIONS_FP="$2"
  M3WNDW_INPUT_FP="$3"
  export INFP="${CMAQ_EMISSIONS_FP}"
  export OUFP="${TEST_EMISSIONS_FP}"
  # INFP, OUFP are handles for `m3wndw`: don't substitute in shell!

  for CMD in \
    "ls -alt ${INFP} ${OUFP}" \
    "m3wndw INFP OUFP < ${M3WNDW_INPUT_FP}" \
    "ncdump -h ${OUFP} | head -n 20" \
  ; do
    echo -e "$ ${CMD}"
    eval "${CMD}"
  done
} # end function windowCMAQemissionsFile

# Create datavar in windowed formerly-CMAQ-5 emissions to
# contain EPIC emissions, and name the specie appropriately.
# Since all CMAQ emissions datetimes will be getting the same EPIC input--
# --we currently lack N2O diurnality and seasonality--
# only create this one "container" for the data we'll write, and reuse it.
# Requires creation of at least one windowCMAQemissionsFile.
function createEPICdatavar {
  if [[ -r "${HOUR_EMISSIONS_FP}" ]] ; then
    # use it, but test first
    echo -e "error? createEPICdatavar: hourly emissions container file='${HOUR_EMISSIONS_FP}' exists, will not recreate"
    for CMD in \
      "ls -alt ${HOUR_EMISSIONS_FP}" \
      "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${INPUT_VAR_NAME}'" \
      "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${OUTPUT_VAR_NAME}'" \
    ; do
      echo -e "$ ${CMD}"
      eval "${CMD}"
    done
  else # can't read ${HOUR_EMISSIONS_FP}
    HOUR_EMISSIONS_FN_STUB="${TEST_EMISSIONS_FN_TEMPLATE%_%DATE*}"
#    echo -e "${HOUR_EMISSIONS_FN_STUB}"
    if [[ -d "${TEST_EMISSIONS_DIR}" ]] ; then
      # use newest as source
      HOUR_EMISSIONS_SOURCE_FP="$(ls -1t ${TEST_EMISSIONS_DIR}/${HOUR_EMISSIONS_FN_STUB}* | head -n 1)"
#      echo -e "${HOUR_EMISSIONS_SOURCE_FP}"
      if [[ -n "${HOUR_EMISSIONS_SOURCE_FP}" ]] ; then

        # Use that to create container file for hourly emissions.
        for CMD in \
          "ls -alt ${HOUR_EMISSIONS_SOURCE_FP} ${HOUR_EMISSIONS_FP}" \
          "cp ${HOUR_EMISSIONS_SOURCE_FP} ${HOUR_EMISSIONS_FP}" \
          "ls -alt ${HOUR_EMISSIONS_SOURCE_FP} ${HOUR_EMISSIONS_FP}" \
        ; do
          echo -e "$ ${CMD}"
          eval "${CMD}"
        done
        if [[ -w "${HOUR_EMISSIONS_FP}" ]] ; then

          # add EPIC emissions datavar (with to-be-processed data) to container file
          for CMD in \
            "ncks -O -v ${INPUT_VAR_NAME} ${EPIC_INPUT_FP} ${HOUR_EMISSIONS_FP}" \
            "ncrename -O -v ${INPUT_VAR_NAME},${OUTPUT_VAR_NAME} ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncatted -O -a '${NCATTED_LONG_NAME_STRING}' ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncatted -O -a '${NCATTED_VAR_LIST_STRING}' ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncks -O -H -d LAY,${EPIC_DATA_LAYER_INDEX} ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${INPUT_VAR_NAME}'" \
            "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${OUTPUT_VAR_NAME}'" \
            "ncdump -h ${HOUR_EMISSIONS_FP} | head -n 14" \
            "ls -alt ${HOUR_EMISSIONS_SOURCE_FP} ${HOUR_EMISSIONS_FP}" \
          ; do
            echo -e "$ ${CMD}"
            eval "${CMD}"
          done

        else # ! -w "${HOUR_EMISSIONS_FP}"
          echo -e "ERROR: createEPICdatavar: copied file='${HOUR_EMISSIONS_FP}' from which to create hourly emissions container, but it is not writable"
          exit 6
        fi # end testing -w "${HOUR_EMISSIONS_FP}"
      else # -z "${HOUR_EMISSIONS_SOURCE_FP}"
        echo -e 'ERROR: createEPICdatavar: path to file from which to create hourly emissions container not defined'
        exit 7
      fi # end testing -n "${HOUR_EMISSIONS_SOURCE_FP}"
    else
      echo -e 'ERROR: createEPICdatavar: folder for windowed CMAQ emissions not found'
      exit 8
    fi # end testing -d "${TEST_EMISSIONS_DIR}"
  fi # end testing -r "${HOUR_EMISSIONS_FP}"
  export M3STAT_FILE="${HOUR_EMISSIONS_FP}"
} # end function createEPICdatavar

function teardown {
  # run m3tools/m3stat on the output: default input==rep('\n', 4)
  m3stat M3STAT_FILE <<EOF




EOF
} # end function teardown

# script--------------------------------------------------------------

# TODO: create `ncks`able intermediate NetCDF:
# 1 input *CMAQ emissions*
# 2 *copy* one datavar to new file (the `ncks`able intermediate NetCDF):
#   use NCO:ncks
#   output will already have the desired number of layers and tsteps (and rows and cols)
# 3 rename datavar->N2O: use NCO:ncrename
# 4 write converted values from computeCropSum.sh output
# *THEN*
# 5 `ncks` that back into the (local) CMAQ emissions
# 6 fiddle
# * datavar=TFLAG:
# * global attributes=NVARS,VAR-LIST

#  "setup" \
#  "windowCMAQemissions" \
#  "createEPICdatavar" \
#  "writeEPICdata" \
#  "teardown" \
# should always
# * begin with `setup` to setup paths, other resources
#   function=setupPaths in ${BASH_UTILS_FP}
# * end with `teardown` to do output testing
for CMD in \
  "setup" \
  "windowCMAQemissions" \
  "createEPICdatavar" \
; do
  echo -e "\n$ ${CMD}"
  eval "${CMD}"
  # start debugging
  # show
  # * newest netCDF file
  # * whether it contains the desired attribute
  ATTR_NAME='missing_value'
  if [[ "$(find ${EPIC_DIR} -type f -name '*.nc' | wc -l)" -gt 0 ]] ; then
    NEWEST_NC_FP="$(ls -1t ${EPIC_DIR}/*.nc | head -n 1)"
    if [[ -n "${NEWEST_NC_FP}" ]] ; then
      if [[ -r "${NEWEST_NC_FP}" ]] ; then
        for CMD in \
          "ls -alh ${NEWEST_NC_FP}" \
          "findAttributeInFile '${ATTR_NAME}' '${NEWEST_NC_FP}' | wc -l" \
          "findAttributeInFile '${ATTR_NAME}' '${NEWEST_NC_FP}'" \
        ; do
          echo -e "$ ${CMD}"
          eval "${CMD}"
        done
      else
        echo -e "ERROR: ${THIS_FN}: NEWEST_NC_FP='${NEWEST_NC_FP}' not readable"
      fi
    else
      echo -e "ERROR: ${THIS_FN}: NEWEST_NC_FP not defined"
    fi
  fi
  #   end debugging
done

# debugging-----------------------------------------------------------
