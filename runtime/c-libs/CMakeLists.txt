
# Adds the current directory to the include path
# XXX: Is this needed?
add_library(clibs-common INTERFACE)
target_include_directories(clibs-common INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory(posix-os)
add_subdirectory(smlnj-runtime)
add_subdirectory(smlnj-signals)
add_subdirectory(smlnj-sockets)
add_subdirectory(smlnj-prof)
add_subdirectory(smlnj-time)
add_subdirectory(smlnj-date)
add_subdirectory(smlnj-math)
add_subdirectory(posix-error)
add_subdirectory(posix-filesys)
add_subdirectory(posix-io)
add_subdirectory(posix-procenv)
add_subdirectory(posix-process)
add_subdirectory(posix-signal)
add_subdirectory(posix-sysdb)
add_subdirectory(posix-tty)
add_subdirectory(codegen)
add_subdirectory(dl)
