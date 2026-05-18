
add_custom_command(
    OUTPUT ml_pathconf.h
    COMMAND
        ${CMAKE_COMMAND} -E env
            VERSION=${RUNTIME_VERSION}
            "CPP=${CMAKE_C_COMPILER} -E"
            ${CMAKE_CURRENT_SOURCE_DIR}/../../config/gen-posix-names.sh
                _PC_ ml_pathconf.h
    VERBATIM
)

add_library(posix-filesys STATIC
    ${CMAKE_CURRENT_BINARY_DIR}/ml_pathconf.h
    posix-filesys-lib.c
    osval.c
    chdir.c
    getcwd.c
    openf.c
    umask.c
    link.c
    rename.c
    symlink.c
    mkdir.c
    mkfifo.c
    unlink.c
    rmdir.c
    readlink.c
    stat.c
    access.c
    chmod.c
    fchmod.c
    chown.c
    fchown.c
    ftruncate.c
    utime.c
    opendir.c
    readdir.c
    rewinddir.c
    closedir.c
    pathconf.c
)
target_link_libraries(posix-filesys PRIVATE runtime-common clibs-common)
target_include_directories(posix-filesys PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
