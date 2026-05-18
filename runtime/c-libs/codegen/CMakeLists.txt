add_library(smlnj-codegen STATIC
    codegen-lib.c
    generate.c
    list-targets.c
    set-target.c
    codegen.cpp
)
target_link_libraries(smlnj-codegen
    PRIVATE
        runtime-common
        clibs-common
)
# Pull CFGCodeGen headers without creating a link-order dependency; the
# executable is responsible for placing CFGCodeGen before the LLVM component
# libraries in its own link line.
target_include_directories(smlnj-codegen
    PRIVATE
        $<TARGET_PROPERTY:CFGCodeGen,INTERFACE_INCLUDE_DIRECTORIES>
)
set_source_files_properties(
    codegen.cpp
    PROPERTIES
    # TODO: Configure based on arch
    COMPILE_DEFINITIONS "ENABLE_X86"
)
