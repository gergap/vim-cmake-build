# save breakpoints macro
define dump_breaks
    set logging file bp.tmp
    set logging overwrite
    set logging redirect on
    set logging on
    info breakpoints
    set logging off
    set logging redirect off
    shell perl -ne "print \"break \$1\n\" if /at\s(.*:\d+)/" bp.tmp > $arg0
end

# autosave on exit
define hook-quit
    dump_breaks .breakpoints.gdb
end

# load saved breakpoints
# this file is created by the vim-cmake-build plugin
source .breakpoints.gdb

# check if custom GDB options file exist and creates it if not
# to avoid an error when sourcing it.
shell touch debug.gdb
source debug.gdb

# start debugging
start

