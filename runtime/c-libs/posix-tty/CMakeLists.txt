
add_library(posix-tty STATIC
    posix-tty-lib.c
    osval.c
    tcdrain.c
    tcflow.c
    tcflush.c
    tcgetattr.c
    tcgetpgrp.c
    tcsendbreak.c
    tcsetattr.c
    tcsetpgrp.c
    getwinsz.c
)
target_link_libraries(posix-tty PRIVATE runtime-common clibs-common)
