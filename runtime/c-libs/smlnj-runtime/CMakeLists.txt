
add_library(smlnj-runt STATIC
    smlnj-runt-lib.c
    argv.c
    raw-argv.c
    shift-argv.c
    cmd-name.c
    blast-in.c
    blast-out.c
    debug.c
    dummy.c
    export-heap.c
    export-fun.c
    gc-counter.c
    gc-ctl.c
    itick.c
    mk-code-obj.c
    mkexec.c
    mkliterals.c
    record1.c
    record-concat.c
    sysinfo.c
    setitimer.c
)
target_link_libraries(smlnj-runt PRIVATE runtime-common clibs-common)
target_include_directories(smlnj-runt PRIVATE ../../gc)

