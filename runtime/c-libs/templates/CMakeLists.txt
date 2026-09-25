# CMake configuration for the <<name>> C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# This is a template: copy it into the library's directory, replace the
# fields in <<>>, and add the directory name to SMLNJ_C_LIBRARIES in
# runtime/c-libs/CMakeLists.txt.
#

add_library(smlnj-clib-<<name>> STATIC
  <<name>>-lib.c
  <<source files>>
)
target_link_libraries(smlnj-clib-<<name>> PRIVATE smlnj-clib-common)
