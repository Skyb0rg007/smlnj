
llvm_map_components_to_libnames(LLVM_LIBS ${LLVM_TARGETS_TO_BUILD} passes runtimedyld)

set(SMLNJ_ASM_DEFINES
    -D_ASM_
    -DARCH_${SMLNJ_ARCH}
    -DSIZE_64)
if(LINUX)
    list(APPEND SMLNJ_ASM_DEFINES -DOPSYS_UNIX -DOPSYS_LINUX -D_GNU_SOURCE)
elseif(APPLE)
    list(APPEND SMLNJ_ASM_DEFINES -DOPSYS_UNIX -DOPSYS_DARWIN)
elseif(CYGWIN)
    list(APPEND SMLNJ_ASM_DEFINES -DOPSYS_UNIX -DOPSYS_CYGWIN)
elseif(WIN32)
    list(APPEND SMLNJ_ASM_DEFINES -DOPSYS_WIN32)
endif()
if(WIN32 AND NOT CYGWIN)
    list(APPEND SMLNJ_ASM_DEFINES -DMASM_ASSEMBLER)
elseif(NOT (APPLE AND SMLNJ_ARCH STREQUAL "ARM64"))
    list(APPEND SMLNJ_ASM_DEFINES -DGNU_ASSEMBLER)
endif()

# TODO: CMake should support asm-with-c-preprocessor
add_custom_command(
    OUTPUT prim.s
    COMMAND
        ${CMAKE_C_COMPILER} -E -P -x assembler-with-cpp -D_ASM_
        -I${CMAKE_CURRENT_SOURCE_DIR}/../include
        -I${CMAKE_CURRENT_BINARY_DIR}/../config
        ${SMLNJ_ASM_DEFINES}
        ${CMAKE_CURRENT_SOURCE_DIR}/../mach-dep/${SMLNJ_ARCH}.prim.asm
            > prim.s
    DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/../mach-dep/${SMLNJ_ARCH}.prim.asm
        ${CMAKE_CURRENT_BINARY_DIR}/../config/mlstate-offsets.h
        ${CMAKE_CURRENT_BINARY_DIR}/../config/ml-sizes.h
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
