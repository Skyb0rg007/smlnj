# CMake configuration for the memory-management library
#
# COPYRIGHT (c) 2026 The Fellowship of SML/NJ (https://smlnj.org)
# All rights reserved.
#
# The mmap version is the only memory subsystem that is supported
# (mem-mach.c is for Mach systems).
#

add_library(smlnj-mem STATIC mem-mmap.c)
target_include_directories(smlnj-mem PRIVATE ${SMLNJ_RUNTIME_SOURCE_DIR}/gc)
target_link_libraries(smlnj-mem PRIVATE smlnj-runtime-common)
