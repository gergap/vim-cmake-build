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
source .breakpoints.gdb


