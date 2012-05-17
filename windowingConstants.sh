# description---------------------------------------------------------

# Source me for windowing constants for top-level drivers in github project=ioapi-hack-R

# code----------------------------------------------------------------

# constants-----------------------------------------------------------

# Windowing bounds:
# * order follows m3wndw input convention
# * all values signed decimal (i.e., S,W are negative)
let WEST_LON=-96
let EAST_LON=-90
let SOUTH_LAT=39
let NORTH_LAT=45
# input file for driving m3wndw:
# file populated (with ioapi grid indices) by windowEmissions.r
#M3WNDW_INPUT_FP="$(mktemp)"
M3WNDW_INPUT_DIR="$(pwd)" # allow recovery for reuse
M3WNDW_INPUT_FN="m3wndw_input.txt"
M3WNDW_INPUT_FP="${M3WNDW_INPUT_DIR}/${M3WNDW_INPUT_FN}"
