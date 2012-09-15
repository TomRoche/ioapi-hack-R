#!/usr/bin/env bash

# description---------------------------------------------------------

# A top-level driver for github project=ioapi-hack-R. See ./README
# https://github.com/TomRoche/ioapi-hack-R/blob/master/README

# code----------------------------------------------------------------

# from http://wiki.bash-hackers.org/scripting/debuggingtips
# note single quotes in original!
export PS4='ERROR: $+${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}: }'

# constants-----------------------------------------------------------

# TODO: take switches for help, debugging, no/eval, target drive
THIS="$0"
THIS_FN="$(basename $0)"
THIS_DIR="$(dirname $0)"

# length of "field" in IOAPI global attr=VAR-LIST
let VAR_LIST_FIELD_LENGTH=16
# length of datavar attr=var_desc
let VAR_DESC_FIELD_LENGTH=80

# name of the EPIC datavar
EPIC_INPUT_VAR_NAME='DN2'
# EPIC specie/datavar units
INPUT_VAR_UNITS_IOAPI_FORMATTED='kg/ha           ' # field length=${VAR_LIST_FIELD_LENGTH}
INPUT_VAR_UNITS="${INPUT_VAR_UNITS_IOAPI_FORMATTED%% *}"
# name of specie/datavar to be created in CMAQ-5 emissions
OUTPUT_VAR_NAME_IOAPI_FORMATTED='N2O             ' # field length=${VAR_LIST_FIELD_LENGTH}
OUTPUT_VAR_NAME="${OUTPUT_VAR_NAME_IOAPI_FORMATTED%% *}"
# CMAQ specie/datavar units
OUTPUT_VAR_UNITS_IOAPI_FORMATTED='moles/s         ' # field length=${VAR_LIST_FIELD_LENGTH}
OUTPUT_VAR_UNITS="${OUTPUT_VAR_UNITS_IOAPI_FORMATTED%% *}"

# input data from EPIC via computeCropSum.sh
EPIC_INPUT_DIR="${THIS_DIR}/data/epic/raw"
EPIC_INPUT_FN="5yravg.${EPIC_INPUT_VAR_NAME}windowed.nc"
EPIC_INPUT_FP="${EPIC_INPUT_DIR}/${EPIC_INPUT_FN}"
# the ZERO-BASED index of the layer containing the integrated EPIC emissions
# TODO: either get last layer index from ${EPIC_INPUT_FN}, or get this from computeCropSum.sh
let EPIC_DATA_LAYER_INDEX=44

EPIC_OUTPUT_DIR="${THIS_DIR}/data/epic/cooked"

# Windowing bounds:
WINDOWING_FN="windowingConstants.sh"
WINDOWING_FP="${THIS_DIR}/${WINDOWING_FN}"
source "${WINDOWING_FP}"
#echo -e "M3WNDW_INPUT_FP='${M3WNDW_INPUT_FP}'"

# bash utilities
BASH_UTILS_FN="bashUtilities.sh"
BASH_UTILS_FP="${THIS_DIR}/${BASH_UTILS_FN}"
source "${BASH_UTILS_FP}"

# input raw CMAQ eval emissions data
# path setup for infinity, terrae: other users must change!
RAW_CMAQ_EMIS_DIR="${THIS_DIR}/data/emis/raw"
# CMAQ uses 8-digit dates
# TODO: get dates from CCTM run script
CMAQ_EMIS_DATE8_START="20060719"
CMAQ_EMIS_DATE8_END="20060731"
RAW_CMAQ_EMIS_FN_PREFIX='emis_mole_all'
RAW_CMAQ_EMIS_FN_SUFFIX='12US1_cmaq_cb05_tx_C25_2006am.ncf'
RAW_CMAQ_EMIS_FN_TEMPLATE="${RAW_CMAQ_EMIS_FN_PREFIX}_%DATE8%_${RAW_CMAQ_EMIS_FN_SUFFIX}"

# for outputs of variously processed CMAQ eval emissions data
# path setup for infinity, terrae: other users must change!
COOKED_CMAQ_EMIS_DIR="${THIS_DIR}/data/emis/cooked"
WINDOWED_CMAQ_EMIS_DIR="${COOKED_CMAQ_EMIS_DIR}"
WINDOWED_CMAQ_EMIS_FN_PREFIX="${RAW_CMAQ_EMIS_FN_PREFIX}"
WINDOWED_CMAQ_EMIS_FN_SUFFIX='windowed.ncf'
WINDOWED_CMAQ_EMIS_FN_TEMPLATE="${WINDOWED_CMAQ_EMIS_FN_PREFIX}_%DATE8%_${WINDOWED_CMAQ_EMIS_FN_SUFFIX}"
# output/target data: windowed CMAQ eval emissions, plus target specie/datavar
COOKED_CMAQ_EMIS_FN_PREFIX="emis_mole_plus${OUTPUT_VAR_NAME}"
COOKED_CMAQ_EMIS_FN_SUFFIX="${WINDOWED_CMAQ_EMIS_FN_SUFFIX}"
COOKED_CMAQ_EMIS_FN_TEMPLATE="${COOKED_CMAQ_EMIS_FN_PREFIX}_%DATE8%_${COOKED_CMAQ_EMIS_FN_SUFFIX}"

# name of the MCIP datavar
MCIP_INPUT_VAR_NAME='MSFX2'
# MCIP uses 6-digit dates
MCIP_FN_TEMPLATE="GRIDCRO2D_%DATE6%"
MCIP_DATE6_START="${CMAQ_EMIS_DATE8_START:2}"
MCIP_DATE6_END="${CMAQ_EMIS_DATE8_END:2}"
# use start date, assume all have same map scale factors (MSFs)
MCIP_FN="GRIDCRO2D_${MCIP_DATE6_START}"
MCIP_DIR="${THIS_DIR}/data/mcip/raw"
MCIP_FP="${MCIP_DIR}/${MCIP_FN}"
# TODO: MSFs of what? ID the underlying map, windowing
MSF_FN="MSFs_${MCIP_FN}.nc"
MSF_DIR="${THIS_DIR}/data/mcip/cooked"
MSF_FP="${MSF_DIR}/${MSF_FN}"

# UC==unit conversion: EPIC (kg/ha/y) -> CMAQ (mol/s)
# UC file is a copy/mod of a windowed CMAQ emissions file
# (chosen @ runtime, since we don't know the dates
# UCD==UC datavar
UCD_FN="emis_unit_conversion_epic_to_cmaq.ncf"
UCD_DIR="${EPIC_OUTPUT_DIR}"
UCD_FP="${UCD_DIR}/${UCD_FN}"

UCD_INPUT_VAR_NAME='ACROLEIN' # a junk specie name: any will do.
# TODO: NCO: how to just "get one" datavar name? (easy with R)
UCD_VAR_NAME='unit_conversion' # should (must?) have length <= ${VAR_LIST_FIELD_LENGTH}
# conversion units
UCD_VAR_UNITS_IOAPI_FORMATTED='mol ha y kg-1 s-1' # field length=${VAR_LIST_FIELD_LENGTH}
UCD_VAR_UNITS="${UCD_VAR_UNITS_IOAPI_FORMATTED}"
UCD_VAR_DESC_IOAPI_FORMATTED='factor converting EPIC emissions to CMAQ emissions                              ' # field length=${VAR_DESC_FIELD_LENGTH}
UCD_VAR_DESC="${UCD_VAR_DESC_IOAPI_FORMATTED%%  *}" # note '%%' with *2* spaces

# name of specie/datavar to be created in CMAQ-5 emissions
OUTPUT_VAR_NAME_IOAPI_FORMATTED='N2O             ' # field length=${VAR_LIST_FIELD_LENGTH}
OUTPUT_VAR_NAME="${OUTPUT_VAR_NAME_IOAPI_FORMATTED%% *}"
# CMAQ specie/datavar units
OUTPUT_VAR_UNITS_IOAPI_FORMATTED='moles/s         ' # field length=${VAR_LIST_FIELD_LENGTH}
OUTPUT_VAR_UNITS="${OUTPUT_VAR_UNITS_IOAPI_FORMATTED%% *}"

#---------------------------------------------------------------------

# holder for EPIC emissions for *every* date/hour
HOUR_EMISSIONS_FN="emis_mole_only${OUTPUT_VAR_NAME}_windowed.ncf"
HOUR_EMISSIONS_FP="${COOKED_CMAQ_EMIS_DIR}/${HOUR_EMISSIONS_FN}"

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

# writes EPIC data to CMAQ
EPIC_TO_CMAQ_SCRIPT_FN="writeEPICtoCMAQ.r"
EPIC_TO_CMAQ_SCRIPT_FP="${THIS_DIR}/${EPIC_TO_CMAQ_SCRIPT_FN}"

# functions-----------------------------------------------------------

# TODO: test for resources, reuse if available
# * m3wndw redirect file
function setup {
#  export _DEBUG='on'
  for CMD in \
    "setupPaths" \
    "stopOnFindingOutputs" \
    "stopOnMissingInputs" \
   ; do
     if [[ -n "$(declare -f ${CMD})" ]] ; then
       echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
       eval "${CMD}"
     else
       echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD}' not defined, stopping"
       exit 1
     fi
  done
#  export _DEBUG=''

#   # create needed resources
#   set -xv
#   if [[ ! -d "${COOKED_CMAQ_EMIS_DIR}" ]] ; then
#     mkdir -p "${COOKED_CMAQ_EMIS_DIR}"
#   fi
#   set +xv
} # end function setup

# Stop (and warn user) if we can find the output datavars in the output files.
function stopOnFindingOutputs {
  if [[ -z "${COOKED_CMAQ_EMIS_DIR}" ]] ; then
    echo -e 'ERROR: stopOnFindingOutputs: output directory not defined'
    exit 1
  else
    if [[ -d "${COOKED_CMAQ_EMIS_DIR}" ]] ; then

      # look for each file, stop if any found
      # TODO: make loop increment dates, not just integers
      for (( I=${CMAQ_EMIS_DATE8_START}; I<=${CMAQ_EMIS_DATE8_END}; I++ )) ; do
        DEBUG echo -e "date='${I}'"
        # single-quotes around the sed operator fail
        COOKED_CMAQ_EMIS_FN="$(echo -e ${COOKED_CMAQ_EMIS_FN_TEMPLATE} | sed -e s/%DATE8%/${I}/)"
        DEBUG echo -e "COOKED_CMAQ_EMIS_FN='${COOKED_CMAQ_EMIS_FN}'"
        COOKED_CMAQ_EMIS_FP="${COOKED_CMAQ_EMIS_DIR}/${COOKED_CMAQ_EMIS_FN}"
        if [[ -n "${COOKED_CMAQ_EMIS_FP}" ]] ; then
          if [[ -r "${COOKED_CMAQ_EMIS_FP}" ]] ; then
            echo -e "ERROR? stopOnFindingOutputs: found output file='${COOKED_CMAQ_EMIS_FP}', stopping" 1>&2
            exit 2
          fi # end testing -r "${COOKED_CMAQ_EMIS_FP}"
        else
          echo -e 'ERROR: stopOnFindingOutputs: output file path not defined' 1>&2
          exit 3
        fi # end testing -n "${COOKED_CMAQ_EMIS_FP}"
      done # end incrementing dates

    fi # end testing -d "${COOKED_CMAQ_EMIS_DIR}"
  fi # end testing -z "${COOKED_CMAQ_EMIS_DIR}"
} # end function stopOnFindingOutputs

# Stop (and warn user) if we cannot find needed inputs
function stopOnMissingInputs {
  for CMD in \
    "findEPICDatavar" \
    "findMCIPDatavar" \
    "findCMAQdata" \
   ; do
     if [[ -n "$(declare -f ${CMD})" ]] ; then
       echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
       eval "${CMD}"
     else
       echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD}' not defined, stopping"
       exit 1
     fi
  done
} # end function stopOnMissingInputs

# TODO: factor out common logic with find*Datavar, findCMAQdata
# Stop if can't find input EPIC emissions folder, files, target datavar
function findEPICDatavar {
  if [[ -r "${EPIC_INPUT_FP}" ]] ; then
    # does it have the wanted datavar? else exit
    # should just be `exitIfDatavarNotFound ${EPIC_INPUT_VAR_NAME}`, rest is kludge
    exitIfDatavarNotFound "${EPIC_INPUT_FP}" "${EPIC_INPUT_VAR_NAME}" 'units' 'kg/ha           '
  else
    echo -e "ERROR: findEPICDatavar: cannot find EPIC input file='${EPIC_INPUT_FP}'" 1>&2
    exit 1
  fi # end testing -r "${EPIC_INPUT_FP}"
} # end function findEPICDatavar

# TODO: factor out common logic with find*Datavar, findCMAQdata
# Stop if can't find input MCIP folder, files, target datavar
function findMCIPDatavar {
  if [[ -r "${MCIP_FP}" ]] ; then
    # does it have the wanted datavar? else exit
    # should just be `exitIfDatavarNotFound ${MCIP_INPUT_VAR_NAME}`, rest is kludge
    exitIfDatavarNotFound "${MCIP_FP}" "${MCIP_INPUT_VAR_NAME}" 'units' '(M/M)**2        '
  else
    echo -e "ERROR: findMCIPDatavar: cannot find MCIP input file='${MCIP_FP}'" 1>&2
    exit 1
  fi # end testing -r "${MCIP_FP}"
} # end function findMCIPDatavar

# TODO: factor out common logic with find*Datavar
# stop if can't find raw CMAQ eval emissions folder, files
function findCMAQdata {
  if [[ ! -d "${RAW_CMAQ_EMIS_DIR}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: cannot find raw CMAQ eval emissions dir='${RAW_CMAQ_EMIS_DIR}'" 1>&2
    exit 1
  else
    # does it have the wanted files?
    # TODO: make loop increment dates, not just integers
    for (( I=${CMAQ_EMIS_DATE8_START}; I<=${CMAQ_EMIS_DATE8_END}; I++ )) ; do
#       DEBUG echo -e "date='${I}'"
      # single-quotes around the sed operator fail
      RAW_CMAQ_EMIS_FN="$(echo -e ${RAW_CMAQ_EMIS_FN_TEMPLATE} | sed -e s/%DATE8%/${I}/)"
      RAW_CMAQ_EMIS_FP="${RAW_CMAQ_EMIS_DIR}/${RAW_CMAQ_EMIS_FN}"
#       DEBUG echo -e "RAW_CMAQ_EMIS_FP='${RAW_CMAQ_EMIS_FP}'"
      if [[ -n "${RAW_CMAQ_EMIS_FP}" ]] ; then
        if [[ -r "${RAW_CMAQ_EMIS_FP}" ]] ; then
          DEBUG echo -e "${FUNCNAME[0]}: found CMAQ emissions file='${RAW_CMAQ_EMIS_FP}'" 1>&2
        else
          echo -e "ERROR: ${FUNCNAME[0]}: cannot read CMAQ emissions file='${RAW_CMAQ_EMIS_FP}'" 1>&2
          exit 1
        fi # end testing -r "${RAW_CMAQ_EMIS_FP}"
      else
        echo -e "ERROR: ${FUNCNAME[0]}: CMAQ emissions file path not defined" 1>&2
        exit 5
      fi # end testing -n "${RAW_CMAQ_EMIS_FP}"
    done # end incrementing dates
  fi # end testing -d "${RAW_CMAQ_EMIS_DIR}"
} # end function findCMAQdata

# Get the windowed file containing map scale factors (MSFs)
# Create it if not found.
function getMSFFile {
  if [[ -n "${MSF_FP}" ]] ; then
    if [[ ! -r "${MSF_FP}" ]] ; then
      createMSFFile
    fi # end testing ! -r "${MSF_FP}"
    if [[ -r "${MSF_FP}" ]] ; then
  #    export _DEBUG='on'
      DEBUGx testMSFFile
  #    export _DEBUG=''
    else
      echo -e "ERROR: ${FUNCNAME[0]}: cannot read MSF file='${MSF_FP}'" 1>&2
      exit 1
    fi # end testing -r "${MSF_FP}"
  else
    echo -e "ERROR: ${FUNCNAME[0]}: MSF file path not defined" 1>&2
    exit 2
  fi # end testing -r "${MSF_FP}"
} # end function getMSFFile

function testMSFFile {
  for CMD in \
    "ls -alt ${MSF_FP}" \
    "ncdump -h ${MSF_FP} | fgrep -e '${MCIP_INPUT_VAR_NAME}'" \
  ; do
    echo -e "$ ${CMD}"
    eval "${CMD}"
  done
} # end function testMSFFile

# Isolate map scale factors (MSFs) datavar in windowed MCIP file.
# Since MSFs are unchanging at our timescale, only do one.
# CONTRACT: will overwrite existing MSF file
function createMSFFile {
  # get first MCIP file: presume all have same MSFs
  if [[ -n "${MCIP_FP}" ]] ; then
    if [[ -n "${MSF_FP}" ]] ; then
        if [[ -n "${M3WNDW_INPUT_FP}" && -r "${M3WNDW_INPUT_FP}" ]] ; then
          if [[ -r "${MCIP_FP}" ]] ; then
            # TODO: window the MCIP file??? but it's sparse?
#              "windowFile ${MCIP_FP} ${MSF_FP} ${M3WNDW_INPUT_FP}" \
            for CMD in \
              "stripOtherDatavars ${MCIP_INPUT_VAR_NAME} ${MCIP_FP} ${MSF_FP}" \
            ; do
              # but only if the first word is a command
              if [[ -n "$(declare -f ${CMD%% *})" ]] ; then
                echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
                eval "${CMD}"
              else
                echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD%% *}' not defined, stopping"
                exit 1
              fi
            done
          else
            echo -e "ERROR: ${FUNCNAME[0]}: cannot read MCIP file='${MCIP_FP}'" 1>&2
            exit 1
          fi # end testing -r "${MCIP_FP}"
        else
          # TODO: {! -r M3WNDW_INPUT_FP} -> run windowEmissions.r
          echo -e "ERROR: ${FUNCNAME[0]}: m3wndw input file='${M3WNDW_INPUT_FP}' not found" 1>&2
          exit 2
        fi # end testing -n && -r "${M3WNDW_INPUT_FP}"
    else
      echo -e "ERROR: ${FUNCNAME[0]}: output MSF file path not defined" 1>&2
      exit 4
    fi # end testing -n "${MSF_FP}"
  else
    echo -e "ERROR: ${FUNCNAME[0]}: input MCIP file path not defined" 1>&2
    exit 5
  fi # end testing -n "${MCIP_FP}"
  export M3STAT_FILE="${MSF_FP}"
} # end function createMSFFile

# Create windowed CMAQ emissions, if they don't already exist.
# CONTRACT: inputs (target dir, unwindowed/"raw" CMAQ emissions) already created/found.
# TODO: factor out common logic with other get* functions.
function getWCEFiles {
  if [[ ! -d "${COOKED_CMAQ_EMIS_DIR}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: cannot find folder for windowed CMAQ eval emissions='${COOKED_CMAQ_EMIS_DIR}'" 1>&2
    exit 1
  else
    # does it have the wanted files? with the correct dimensions?
    # TODO: make loop increment dates, not just integers
    for (( I=${CMAQ_EMIS_DATE8_START}; I<=${CMAQ_EMIS_DATE8_END}; I++ )) ; do
      # single-quotes around the sed operator fail
      WINDOWED_CMAQ_EMIS_FN="$(echo -e ${WINDOWED_CMAQ_EMIS_FN_TEMPLATE} | sed -e s/%DATE8%/${I}/)"
      WINDOWED_CMAQ_EMIS_FP="${COOKED_CMAQ_EMIS_DIR}/${WINDOWED_CMAQ_EMIS_FN}"
      DEBUG echo -e "WINDOWED_CMAQ_EMIS_FP='${WINDOWED_CMAQ_EMIS_FP}'"
      if [[ -n "${WINDOWED_CMAQ_EMIS_FP}" ]] ; then
        if [[ -r "${WINDOWED_CMAQ_EMIS_FP}" ]] ; then
          DEBUG echo -e "${FUNCNAME[0]}: found CMAQ emissions file='${WINDOWED_CMAQ_EMIS_FP}'" 1>&2
          # TODO: check its dimensions: is it actually windowed?
        else
          # Create the windowed file ...
          for CMD in \
            "createWCEFile ${I} ${WINDOWED_CMAQ_EMIS_FP}" \
          ; do
            # but only if the first word is a command
            if [[ -n "$(declare -f ${CMD%% *})" ]] ; then
              echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
              eval "${CMD}"
            else
              echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD}' not defined, stopping"
              exit 2
            fi
          done # end for CMD
          # ... and check it's actually created
          if [[ ! -r "${WINDOWED_CMAQ_EMIS_FP}" ]] ; then
            echo -e "ERROR: ${FUNCNAME[0]}: cannot read windowed CMAQ emissions file='${WINDOWED_CMAQ_EMIS_FP}'" 1>&2
            exit 3
          fi # end post-create testing -r "${WINDOWED_CMAQ_EMIS_FP}"
        fi # end testing -r "${WINDOWED_CMAQ_EMIS_FP}"
      else
        echo -e "ERROR: ${FUNCNAME[0]}: path for windowed CMAQ emissions file not defined" 1>&2
        exit 4
      fi # end testing -n "${WINDOWED_CMAQ_EMIS_FP}"
    done # end incrementing dates
  fi # end testing -d "${COOKED_CMAQ_EMIS_DIR}"
} # end function getWCEFiles

# Window a CMAQ-5 emissions file.
# CONTRACT: arguments tested by caller
function createWCEFile {
#  export _DEBUG='on'
  DATE8="$1" # date for CMAQ emissions filenames (cooked and raw)
  OUTPUT_FP="$2"
  # Since we didn't previously cache the raw emissions filenames, recreate.
  # TODO: create dictionary with date, raw filename, windowed FN, etc
  INPUT_FN="$(echo -e ${RAW_CMAQ_EMIS_FN_TEMPLATE} | sed -e s/%DATE8%/${DATE8}/)"
  INPUT_FP="${RAW_CMAQ_EMIS_DIR}/${INPUT_FN}"
  DEBUG echo -e "${FUNCNAME[0]}: INPUT_FP='${INPUT_FP}'"
  if [[ -n "${INPUT_FP}" ]] ; then
    if [[ -r "${INPUT_FP}" ]] ; then
      if [[ -n "${M3WNDW_INPUT_FP}" && -r "${M3WNDW_INPUT_FP}" ]] ; then
        # process the file
        for CMD in \
          "windowFile ${INPUT_FP} ${OUTPUT_FP} ${M3WNDW_INPUT_FP}" \
        ; do
          # but only if the first word is a command
          if [[ -n "$(declare -f ${CMD%% *})" ]] ; then
            echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
            eval "${CMD}"
          else
            echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD}' not defined, stopping"
            exit 1
          fi
        done # end for CMD
      else
        # TODO: {! -r M3WNDW_INPUT_FP} -> run windowEmissions.r
        echo -e "ERROR: ${FUNCNAME[0]}: m3wndw input file='${M3WNDW_INPUT_FP}' not found" 1>&2
        exit 2
      fi # end testing -n "${M3WNDW_INPUT_FP}" && -r "${M3WNDW_INPUT_FP}"
    else
      echo -e "ERROR: ${FUNCNAME[0]}: cannot read input CMAQ emissions file='${INPUT_FP}'" 1>&2
      exit 3
    fi # end testing -r "${INPUT_FP}"
  else
    echo -e "ERROR: ${FUNCNAME[0]}: CMAQ emissions file path not defined" 1>&2
    exit 4
  fi # end testing -n "${INPUT_FP}"
#  export _DEBUG=''
} # end function createWCEFile

# TODO: factor out common logic with find*Datavar, findCMAQdata
# Stop if can't find input unit conversion datavar, file
function getUCDatavar {
  if [[ -n "${UCD_FP}" ]] ; then
    if [[ ! -r "${UCD_FP}" ]] ; then
      if [[ -z "${UCD_INPUT_VAR_NAME}" ]] ; then
        echo -e "ERROR: ${FUNCNAME[0]}: name of proto-UCD datavar not defined" 1>&2
        exit 2
      fi # end testing -z "${UCD_INPUT_VAR_NAME}"
      for CMD in \
        "createUCD" \
        "fixUCD" \
        "fillinUCD" \
      ; do
        # but only if the first word is a command
        if [[ -n "$(declare -f ${CMD%% *})" ]] ; then
          echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
          eval "${CMD}"
        else
          echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD}' not defined, stopping"
          exit 1
        fi # end testing declaration
      done # end for CMD
    fi # end testing ! -r "${UCD_FP}"
    # We now (hopefully) have the UCD file, but does it have the UCD datavar?
    DEBUGx testUCDFile
  else
    echo -e "ERROR: ${FUNCNAME[0]}: UCD file path not defined" 1>&2
    exit 1
  fi # end testing -n "${UCD_FP}"
} # end function getUCDatavar

function testUCDFile {
  if [[ -z "${UCD_FP}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD file path not defined" 1>&2
    exit 1
  fi # end testing -z "${UCD_VAR_NAME}"
  if [[ -z "${UCD_VAR_NAME}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD datavar name not defined" 1>&2
    exit 2
  fi # end testing -z "${UCD_VAR_NAME}"
  if [[ -z "${UCD_VAR_UNITS}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD datavar units not defined" 1>&2
    exit 3
  fi # end testing -z "${UCD_VAR_UNITS}"
  if [[ -r "${UCD_FP}" ]] ; then
    # TODO: test not only the datavar name, but the datavar *contents*
    exitIfDatavarNotFound "${UCD_FP}" "${UCD_VAR_NAME}" 'units' "${UCD_VAR_UNITS}"
    # TODO: test datavar attr=var_desc
  else
    echo -e "ERROR: ${FUNCNAME[0]}: cannot read UCD file='${UCD_FP}'" 1>&2
    exit 4
  fi # end testing -r "${UCD_FP}"
} # end function testUCDFile

# Isolate unit conversions (UCs) datavar in windowed CMAQ file:
# we want same grid, to hold the factors.
function createUCD {
  if [[ -z "${UCD_FP}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD file path not defined" 1>&2
    exit 1
  fi # end testing -z "${UCD_FP}"
  if [[ -r "${UCD_FP}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD file path='${UCD_FP}' found, will not overwrite" 1>&2
    exit 2
  fi # end testing -z "${UCD_FP}"
  if [[ -z "${UCD_INPUT_VAR_NAME}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: name of datavar from which to create UCD not defined" 1>&2
    exit 3
  fi # end testing -z "${UCD_INPUT_VAR_NAME}"
  if [[ -z "${UCD_VAR_NAME}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: name of UCD not defined" 1>&2
    exit 4
  fi # end testing -z "${UCD_VAR_NAME}"

  # Create the UCD file from an input windowed CMAQ file
  if [[ -z "${WINDOWED_CMAQ_EMIS_DIR}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: name of folder containing WCE files not defined" 1>&2
    exit 5
  fi # end testing -z "${WINDOWED_CMAQ_EMIS_DIR}"
  if [[ ! -d "${WINDOWED_CMAQ_EMIS_DIR}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: path to folder containing WCE files='${WINDOWED_CMAQ_EMIS_DIR}' not found" 1>&2
    exit 6
  fi # end testing ! -d "${WINDOWED_CMAQ_EMIS_DIR}"
  if [[ -z "${WINDOWED_CMAQ_EMIS_FN_PREFIX}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: prefix of WCE file names not defined" 1>&2
    exit 7
  fi # end testing -z "${WINDOWED_CMAQ_EMIS_FN_PREFIX}"

  DEBUG echo -e "WINDOWED_CMAQ_EMIS_DIR='${WINDOWED_CMAQ_EMIS_DIR}'"
  DEBUG echo -e "WINDOWED_CMAQ_EMIS_FN_PREFIX='${WINDOWED_CMAQ_EMIS_FN_PREFIX}'"
  DEBUG find ${WINDOWED_CMAQ_EMIS_DIR}/ -type f -name "${WINDOWED_CMAQ_EMIS_FN_PREFIX}*" | wc -l

  # ${WINDOWED_CMAQ_EMIS_DIR} is a symlink, so don't omit trailing slash!
  # and don't single-quote the -name!
  if [[ "$(find ${WINDOWED_CMAQ_EMIS_DIR}/ -type f -name ${WINDOWED_CMAQ_EMIS_FN_PREFIX}* | wc -l)" -gt 0 ]] ; then
    UCD_INPUT_FP="$(ls -1t ${WINDOWED_CMAQ_EMIS_DIR}/${WINDOWED_CMAQ_EMIS_FN_PREFIX}* | head -n 1)"
    DEBUG echo -e "UCD_INPUT_FP='${UCD_INPUT_FP}'"
  fi # end looking for newest windowed CMAQ file
  if [[ -z "${UCD_INPUT_FP}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD file input path not defined" 1>&2
    exit 8
  fi # end testing -z "${UCD_INPUT_FP}"
  if [[ ! -r "${UCD_INPUT_FP}" ]] ; then
    echo -e "ERROR: ${FUNCNAME[0]}: UCD file input path='${UCD_INPUT_FP}' not found" 1>&2
    exit 9
  fi # end testing -z "${UCD_INPUT_FP}"

  for CMD in \
    "stripOtherDatavars ${UCD_INPUT_VAR_NAME} ${UCD_INPUT_FP} ${UCD_FP}" \
    "renameDatavar ${UCD_INPUT_VAR_NAME} ${UCD_VAR_NAME} ${UCD_FP}" \
  ; do
    # but only if the first word is a command
    if [[ -n "$(declare -f ${CMD%% *})" ]] ; then
      echo -e "$ ${FUNCNAME[0]}:${CMD}" 1>&2
      eval "${CMD}"
    else
      echo -e "ERROR: ${FUNCNAME[0]}: function='${CMD%% *}' not defined, stopping"
      exit 10
    fi
  done
  export M3STAT_FILE="${UCD_FP}"
} # end function createUCD

# Fix various parts of the UCD, mostly IOAPI-related
# * var attr=long_name
# * var attr=units
# * var attr=var_desc
# * remove unneeded TSTEP: "25 currently", only need 1
# function fixUCD {
# } # end function fixUCD

# ----------------------------------------------------------------------
# ----------------------------------------------------------------------

# Create datavar in windowed formerly-CMAQ-5 emissions to
# contain EPIC emissions, and name the specie appropriately.
# Since all CMAQ emissions datetimes will be getting the same EPIC input--
# --we currently lack N2O diurnality and seasonality--
# only create this one "container" for the data we'll write, and reuse it.
function createEPICdatavar {
  if [[ -r "${HOUR_EMISSIONS_FP}" ]] ; then
    # use it, but test first
    echo -e "error? createEPICdatavar: hourly emissions container file='${HOUR_EMISSIONS_FP}' exists, will not recreate"
    for CMD in \
      "ls -alt ${HOUR_EMISSIONS_FP}" \
      "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${EPIC_INPUT_VAR_NAME}'" \
      "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${OUTPUT_VAR_NAME}'" \
    ; do
      echo -e "$ ${CMD}"
      eval "${CMD}"
    done
  else # can't read ${HOUR_EMISSIONS_FP}
    HOUR_EMISSIONS_FN_STUB="${COOKED_CMAQ_EMIS_FN_TEMPLATE%_%DATE8*}"
#    echo -e "${HOUR_EMISSIONS_FN_STUB}"
    if [[ -d "${COOKED_CMAQ_EMIS_DIR}" ]] ; then
      # use newest as source
      HOUR_EMISSIONS_SOURCE_FP="$(ls -1t ${COOKED_CMAQ_EMIS_DIR}/${HOUR_EMISSIONS_FN_STUB}* | head -n 1)"
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
            "ncks -O -v ${EPIC_INPUT_VAR_NAME} ${EPIC_INPUT_FP} ${HOUR_EMISSIONS_FP}" \
            "ncrename -O -v ${EPIC_INPUT_VAR_NAME},${OUTPUT_VAR_NAME} ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncatted -O -a '${NCATTED_LONG_NAME_STRING}' ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncatted -O -a '${NCATTED_VAR_LIST_STRING}' ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncks -O -H -d LAY,${EPIC_DATA_LAYER_INDEX} ${HOUR_EMISSIONS_FP} ${HOUR_EMISSIONS_FP}" \
            "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${EPIC_INPUT_VAR_NAME}'" \
            "ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e '${OUTPUT_VAR_NAME}'" \
            "ncdump -h ${HOUR_EMISSIONS_FP} | head -n 14" \
            "ls -alt ${HOUR_EMISSIONS_SOURCE_FP} ${HOUR_EMISSIONS_FP}" \
          ; do
            echo -e "$ ${CMD}"
            eval "${CMD}"
          done
          export M3STAT_FILE="${HOUR_EMISSIONS_FP}"

        else # ! -w "${HOUR_EMISSIONS_FP}"
          echo -e "ERROR: createEPICdatavar: copied file='${HOUR_EMISSIONS_FP}' from which to create hourly emissions container, but it is not writable" 1>&2
          exit 6
        fi # end testing -w "${HOUR_EMISSIONS_FP}"
      else # -z "${HOUR_EMISSIONS_SOURCE_FP}"
        echo -e 'ERROR: createEPICdatavar: path to file from which to create hourly emissions container not defined' 1>&2
        exit 7
      fi # end testing -n "${HOUR_EMISSIONS_SOURCE_FP}"
    else
      echo -e 'ERROR: createEPICdatavar: folder for windowed CMAQ emissions not found' 1>&2
      exit 8
    fi # end testing -d "${COOKED_CMAQ_EMIS_DIR}"
  fi # end testing -r "${HOUR_EMISSIONS_FP}"
  export M3STAT_FILE="${HOUR_EMISSIONS_FP}"
} # end function createEPICdatavar

# _Almost_ convert data in EPIC integration file (separated in function=createEPICdatavar)
# from its original units (kg/ha/yr) to those of the CMAQ emissions (mole/sec/gridcell) ...
# but not quite. The problem is, the CMAQ units are mole
# integrated over one hour (the timestep of the CMAQ emissions).
function convertEPICunits {
  if [[ -n "${HOUR_EMISSIONS_FP}" ]] ; then
    if [[ -w "${HOUR_EMISSIONS_FP}" ]] ; then
      # use ${HOUR_EMISSIONS_FP} if units appear correct
      # `ncap2 -v -O -s 'print(N2O@var_desc, "%f")' /tmp/emis_mole_onlyN2O_windowed.ncf`
      if [[ "$(ncdump -h ${HOUR_EMISSIONS_FP} | fgrep -e ${OUTPUT_VAR_NAME}:units)" =~ "${OUTPUT_VAR_UNITS}" ]] ; then
        # use ${HOUR_EMISSIONS_FP} if units appear correct
        echo -e "error? convertEPICunits: hourly emissions container file='${HOUR_EMISSIONS_FP}' exists, has units='${OUTPUT_VAR_UNITS}', will not convert"
        export M3STAT_FILE="${HOUR_EMISSIONS_FP}"
      else

        # Convert units/values in ${HOUR_EMISSIONS_FP}:
        # 
        for CMD in \
          "gotta write R to convert units/values in ${HOUR_EMISSIONS_FP}" \
        ; do
          echo -e "$ ${CMD}"
#         eval "${CMD}"
        done

      fi # end testing if ${HOUR_EMISSIONS_FP} units appear correct
    else
      echo -e "ERROR: convertEPICunits: hourly emissions container file='${HOUR_EMISSIONS_FP}' is not writable" 1>&2
      exit 9
    fi # end testing -w "${HOUR_EMISSIONS_FP}"
  else
    echo -e "ERROR: convertEPICunits: path to hourly emissions container is not defined" 1>&2
    exit 10
  fi # end testing -n "${HOUR_EMISSIONS_FP}"
} # end function convertEPICunits

function teardown {
  # run m3tools/m3stat on the output: default input==rep('\n', 4)
  m3stat M3STAT_FILE <<EOF




EOF
} # end function teardown

# show
# * newest netCDF file
# * whether it contains the desired attribute
function findAttribute {
  ATTR_NAME="$1"
  if [[ -n "${ATTR_NAME}" ]] ; then
    if [[ "$(find ${EPIC_OUTPUT_DIR} -type f -name '*.nc' | wc -l)" -gt 0 ]] ; then
      NEWEST_NC_FP="$(ls -1t ${EPIC_OUTPUT_DIR}/*.nc | head -n 1)"
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
          echo -e "ERROR: findAttribute: NEWEST_NC_FP='${NEWEST_NC_FP}' not readable" 1>&2
        fi
      else
        echo -e 'ERROR: findAttribute: NEWEST_NC_FP not defined' 1>&2
        exit 1
      fi # end testing -n "${NEWEST_NC_FP}"
    fi # end looking for newest EPIC output
  else
    echo -e 'ERROR: findAttribute: ATTR_NAME not defined' 1>&2
    exit 1
  fi # end testing -n "${ATTR_NAME}"
} # end function findAttribute

# script--------------------------------------------------------------

# TODO: create `ncks`able intermediate NetCDF:
# 4 write converted values from computeCropSum.sh output
# *THEN*
# 5 `ncks` that back into the (local) CMAQ emissions
# 6 fiddle
# * datavar=TFLAG:
# * global attributes=NVARS,VAR-LIST

#  "setup" \
#  "createMSFFile" \
#  "createWCEFile" \
#  "createEPICdatavar" \
#  "cacheHourlyEPIC" \
#  "writeHourlyEPICtoCMAQ" \
#  "teardown" \
# should always
# * begin with `setup` to setup paths, other resources
#   function=setupPaths in ${BASH_UTILS_FP}
# * end with `teardown` to do output testing
for CMD in \
  "setup" \
  "getMSFFile" \
  "getWCEFiles" \
  "getUCDatavar" \
  "createEPICdatavar" \
 ; do
   if [[ -n "$(declare -f ${CMD})" ]] ; then
     echo -e "\n$ ${CMD}" 1>&2
     eval "${CMD}"
     DEBUGx findAttribute 'missing_value'
   else
     echo -e "ERROR: mergeWithCmaqEmissions.sh: function='${CMD}' not defined, stopping"
     exit 1
   fi
done

# debugging-----------------------------------------------------------
