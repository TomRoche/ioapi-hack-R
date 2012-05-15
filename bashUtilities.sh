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
