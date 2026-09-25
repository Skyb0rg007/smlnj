# CMake configuration for the codegen C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-codegen STATIC
  codegen-lib.c
  generate.c
  list-targets.c
  set-target.c
  codegen.cpp
)
target_link_libraries(smlnj-clib-codegen PRIVATE smlnj-clib-common)

# the interface to the LLVM-based code generator (written in C++)
target_compile_options(smlnj-clib-codegen PRIVATE
  $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions -fno-rtti>)
target_link_libraries(smlnj-clib-codegen PRIVATE smlnj-llvm::CFGCodeGen)
