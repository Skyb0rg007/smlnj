
add_library(posix-process STATIC
    posix-process-lib.c
    osval.c
    fork.c
    exec.c
    execp.c
    exece.c
    waitpid.c
    exit.c
    kill.c
    alarm.c
    pause.c
    sleep.c
)
target_link_libraries(posix-process PRIVATE runtime-common clibs-common)
