
#### Public targets ####

# Build target for generated files
add_custom_target(generated-files
    DEPENDS
    ${CMAKE_CURRENT_BINARY_DIR}/unix-sigtbl.c
    ${CMAKE_CURRENT_BINARY_DIR}/mlstate-offsets.h
    ${CMAKE_CURRENT_BINARY_DIR}/ml-sizes.h
    ${CMAKE_CURRENT_BINARY_DIR}/system-signals.h
)

# The CMake interface target to depend on the headers + add to include path
add_library(runtime-gen INTERFACE)
add_dependencies(runtime-gen
    generated-files
)
target_include_directories(runtime-gen
    INTERFACE
    ${CMAKE_CURRENT_BINARY_DIR}
)

#### Helpers for gen-* programs ####

add_library(gen-common OBJECT
    gen-common.c
)
target_include_directories(gen-common PUBLIC ../include)
target_link_libraries(gen-common PUBLIC runtime-defs)

add_library(unix-signals OBJECT
    unix-signals.c
)
target_include_directories(unix-signals PRIVATE ../include)
target_link_libraries(unix-signals PRIVATE runtime-defs)

#### ml-sizes.h ####

add_executable(gen-sizes
    gen-sizes.c
)
target_link_libraries(gen-sizes
    PRIVATE
    gen-common
)

add_custom_command(
    OUTPUT ml-sizes.h
    COMMAND gen-sizes
)

#### system-signals.h ####

add_executable(gen-unix-signals
    gen-unix-signals.c
)
target_link_libraries(gen-unix-signals
    PRIVATE
    gen-common unix-signals
)

add_custom_command(
    OUTPUT system-signals.h
    COMMAND gen-unix-signals
)

#### mlstate-offsets.h ####

add_executable(gen-offsets
    gen-offsets.c
    ${CMAKE_CURRENT_BINARY_DIR}/system-signals.h
    ${CMAKE_CURRENT_BINARY_DIR}/ml-sizes.h
)
target_link_libraries(gen-offsets
    PRIVATE
    gen-common
)
target_include_directories(gen-offsets
    PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}
)

add_custom_command(
    OUTPUT mlstate-offsets.h
    COMMAND gen-offsets
)

#### unix-sigtbl.c ####

add_executable(gen-unix-sigtbl
    gen-unix-sigtbl.c
)
target_link_libraries(gen-unix-sigtbl
    PRIVATE
    gen-common unix-signals
)

add_custom_command(
    OUTPUT unix-sigtbl.c
    COMMAND gen-unix-sigtbl
)
# This file is #include'd, so mark it as a header file
set_source_files_properties(
    ${CMAKE_CURRENT_BINARY_DIR}/unix-sigtbl.c
    PROPERTIES
    HEADER_FILE_ONLY ON
    GENERATED ON
)

