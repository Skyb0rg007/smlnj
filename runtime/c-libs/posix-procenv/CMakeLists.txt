
add_custom_command(
    OUTPUT ml_sysconf.h
    COMMAND 
        ${CMAKE_COMMAND} -E env
            VERSION=${RUNTIME_VERSION}
            "CPP=${CMAKE_C_COMPILER} -E"
            ${CMAKE_CURRENT_SOURCE_DIR}/../../config/gen-posix-names.sh
                _SC_ ml_sysconf.h
    VERBATIM
)

add_library(posix-procenv STATIC
    ${CMAKE_CURRENT_BINARY_DIR}/ml_sysconf.h
    posix-procenv-lib.c
    getpid.c
    getppid.c
    getuid.c
    geteuid.c
    getgid.c
    getegid.c
    setuid.c
    setgid.c
    getgroups.c
    getlogin.c
    getpgrp.c
    setsid.c
    setpgid.c
    uname.c
    time.c
    times.c
    getenv.c
    environ.c
    ctermid.c
    ttyname.c
    sysconf.c
    isatty.c
)
target_link_libraries(posix-procenv PRIVATE runtime-common clibs-common)
target_include_directories(posix-procenv PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
