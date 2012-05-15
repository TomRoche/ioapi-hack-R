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
# input file for driving m3wndw 
M3WNDW_INPUT_FP="$(mktemp)"
