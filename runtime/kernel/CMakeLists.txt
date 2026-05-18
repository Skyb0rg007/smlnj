
llvm_map_components_to_libnames(LLVM_LIBS ${LLVM_TARGETS_TO_BUILD} passes runtimedyld)

add_custom_command(
    OUTPUT prim.s
    COMMAND
        ${CMAKE_C_COMPILER} -E -P -x assembler-with-cpp -D_ASM_
        -I${CMAKE_CURRENT_SOURCE_DIR}/../include
        -I${CMAKE_CURRENT_BINARY_DIR}/../config
        -DGNU_ASSEMBLER
        -DARCH_AMD64
        ${CMAKE_CURRENT_SOURCE_DIR}/../mach-dep/AMD64.prim.asm
            > prim.s
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
    ${CMAKE_CURRENT_BINARY_DIR}/prim.s
)
set_source_files_properties(
    ${CMAKE_CURRENT_BINARY_DIR}/prim.s
    PROPERTIES LANGUAGE ASM
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
