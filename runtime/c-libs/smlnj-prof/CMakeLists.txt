# CMake configuration for the smlnj-prof C function library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#

add_library(smlnj-clib-smlnj-prof STATIC
  smlnj-prof-lib.c
  getpquantum.c
  setpref.c
  setptimer.c
)
target_link_libraries(smlnj-clib-smlnj-prof PRIVATE smlnj-clib-common)

# these functions access the internals of the garbage collector
target_include_directories(smlnj-clib-smlnj-prof PRIVATE ${SMLNJ_RUNTIME_SOURCE_DIR}/gc)
