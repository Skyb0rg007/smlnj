
llvm_map_components_to_libnames(LLVM_LIBS ${LLVM_TARGETS_TO_BUILD} passes runtimedyld)

add_custom_command(
    OUTPUT prim.S
    COMMAND
    ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_CURRENT_SOURCE_DIR}/../mach-dep/${SMLNJ_ARCH}.prim.asm
        ${CMAKE_CURRENT_BINARY_DIR}/${SMLNJ_ARCH}.prim.S
)

set_source_files_properties(
    ${CMAKE_CURRENT_BINARY_DIR}/${SMLNJ_ARCH}.prim.S
    PROPERTIES
    COMPILE_DEFINITIONS _ASM_
    INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/../mach-dep
)

add_executable(interactive-run
    main.c
    ../c-libs/c-libraries.c
    ../c-libs/unix-raise-syserr.c
    ml-options.c
    boot.c
    load-ml.c
    run-ml.c
    globals.c
    ml-state.c
    error.c
    timers.c
    unix-timers.c
    qualify-name.c
    swap-bytes.c
    ../mach-dep/unix-fault.c
    ../mach-dep/signal-util.c
    ../mach-dep/unix-signal.c
    ../mach-dep/unix-prof.c
    ${CMAKE_CURRENT_BINARY_DIR}/${SMLNJ_ARCH}.prim.S
)
target_link_libraries(interactive-run
    PRIVATE

    # CLIBS
    posix-os
    smlnj-runt
    smlnj-sig
    smlnj-prof
    smlnj-sock
    smlnj-time
    smlnj-date
    smlnj-math
    posix-process
    posix-procenv
    posix-filesys
    posix-io
    posix-sysdb
    posix-signal
    posix-tty
    posix-error
    smlnj-codegen

    # GC
    gc

    # MEM
    memory

    # XLIBS
    unix-dynload

    # Other deps
    runtime-common
    CFGCodeGen
    ${LLVM_LIBS}
)

string(TOLOWER "${SMLNJ_ARCH}" smlnj_arch_lc)
string(TOLOWER "${SMLNJ_OPSYS}" smlnj_opsys_lc)
set_target_properties(interactive-run PROPERTIES
    OUTPUT_NAME "run.${smlnj_arch_lc}-${smlnj_opsys_lc}"
)

install(TARGETS interactive-run
    RUNTIME DESTINATION
        "${CMAKE_INSTALL_BINDIR}/.run"
)
