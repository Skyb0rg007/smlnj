# CMakeLists.txt
#
# COPYRIGHT (c) 2025 The SML/NJ Fellowship
#
# Exports the 'smlnj-runtime-config' target
# This library is depended on by the other libraries
# It contains architecture-specific rules such as header generation
# and compiler flags settings
#

# ml-sizes.h - Configure a header with platform-specific size information
# TODO: The project should probably migrate to <stdint.h>
block(SCOPE_FOR VARIABLES)
    include(CheckTypeSize)

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(WORD_SZB 8)
        set(BITS_PER_WORD 64)
        set(LOG_BITS_PER_WORD 6)
        set(LOG_BYTES_PER_WORD 3)
    else()
        set(WORD_SZB 4)
        set(BITS_PER_WORD 32)
        set(LOG_BITS_PER_WORD 5)
        set(LOG_BYTES_PER_WORD 2)
    endif()
    check_type_size("double" REALD_SZB BUILTIN_TYPES_ONLY LANGUAGE C)
    check_type_size("short" SHORT_SZB BUILTIN_TYPES_ONLY LANGUAGE C)
    check_type_size("int" INT_SZB BUILTIN_TYPES_ONLY LANGUAGE C)
    check_type_size("long" LONG_SZB BUILTIN_TYPES_ONLY LANGUAGE C)
    check_type_size("long long" LONG_LONG_SZB BUILTIN_TYPES_ONLY LANGUAGE C)

    if(SHORT_SZB EQUAL 2)
        set(I16 "short")
    else()
        message(FATAL_ERROR "No 16-bit integer type")
    endif()

    if(INT_SZB EQUAL 4)
        set(I32 "int")
    elseif(LONG_SZB EQUAL 4)
        set(I32 "long")
    else()
        message(FATAL_ERROR "No 32-bit integer type")
    endif()

    if(LONG_SZB EQUAL 8)
        set(I64 "long")
    elseif(LONG_LONG_SZB EQUAL 4)
        set(I64 "long long")
    else()
        message(FATAL_ERROR "No 64-bit integer type")
    endif()

    if(CMAKE_C_BYTE_ORDER STREQUAL LITTLE_ENDIAN)
        set(BYTE_ORDER "LITTLE")
    elseif(CMAKE_C_BYTE_ORDER STREQUAL BIG_ENDIAN)
        set(BYTE_ORDER "BIG")
    else()
        message(FATAL_ERROR "Unable to determine endianess")
    endif()

    configure_file(
        ml-sizes.h.in
        ${CMAKE_CURRENT_BINARY_DIR}/include/ml-sizes.h
    )
endblock()

# Common utilities for generated files
add_library(smlnj-gen-common OBJECT
    gen.h
    gen-common.c
)
target_include_directories(smlnj-gen-common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)

## mlstate-offsets.h
add_executable(smlnj-gen-offsets
    ${CMAKE_CURRENT_BINARY_DIR}/include/ml-sizes.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/system-signals.h
    gen-offsets.c
)
target_link_libraries(smlnj-gen-offsets PRIVATE
    smlnj-gen-common
)
target_include_directories(smlnj-gen-offsets PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}/include
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/include/mlstate-offsets.h
    COMMAND smlnj-gen-offsets
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include
    DEPENDS smlnj-gen-offsets
)

## Used by system-signals.h and unix-sigtbl.c
add_library(smlnj-gen-unix-signals-common OBJECT
    unix-signals.c
)
target_link_libraries(smlnj-gen-unix-signals-common PRIVATE
    smlnj-gen-common
)

## system-signals.h
add_executable(smlnj-gen-unix-signals
    gen-unix-signals.h
    gen-unix-signals.c
)
target_link_libraries(smlnj-gen-unix-signals PRIVATE
    smlnj-gen-common
    smlnj-gen-unix-signals-common
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/include/system-signals.h
    COMMAND smlnj-gen-unix-signals
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include
    DEPENDS smlnj-gen-unix-signals
)

## unix-sigtbl.c
add_executable(smlnj-gen-unix-sigtbl
    gen-unix-signals.h
    gen-unix-sigtbl.c
)
target_link_libraries(smlnj-gen-unix-sigtbl PRIVATE
    smlnj-gen-common
    smlnj-gen-unix-signals-common
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/include/unix-sigtbl.c
    COMMAND smlnj-gen-unix-sigtbl
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include
    DEPENDS smlnj-gen-unix-sigtbl
)

# This file shouldn't be compiled by itself
set_source_files_properties(
    ${CMAKE_CURRENT_BINARY_DIR}/include/unix-sigtbl.c
    PROPERTIES
    HEADER_FILE_ONLY TRUE
)

## smlnj-runtime-config
add_library(smlnj-runtime-config INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/include/ml-sizes.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/system-signals.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/mlstate-offsets.h
    ${CMAKE_CURRENT_BINARY_DIR}/include/unix-sigtbl.c
)
target_include_directories(smlnj-runtime-config INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)
target_compile_definitions(smlnj-runtime-config INTERFACE
    SIZE_64
    ARCH_AMD64
    OPSYS_UNIX
    OPSYS_LINUX
    _GNU_SOURCE
    GNU_ASSEMBLER
    DLOPEN
    INDIRECT_CFUNC
    $<$<COMPILE_LANGUAGE:ASM>:_ASM_>
)
target_compile_options(smlnj-runtime-config INTERFACE
    $<$<COMPILE_LANGUAGE:ASM>:-x$<SEMICOLON>assembler-with-cpp>
)
