cmake_minimum_required(VERSION 3.13 FATAL_ERROR)
project(SMLNJ
    VERSION "2025.1"
    DESCRIPTION "Standard ML of New Jersey is a compiler for Standard ML"
    HOMEPAGE_URL "https://smlnj.org"
    LANGUAGES C CXX ASM
)

set(CMAKE_CXX_FLAGS "-Werror ${CMAKE_CXX_FLAGS}")
set(CMAKE_C_FLAGS "-Werror ${CMAKE_C_FLAGS}")

add_subdirectory(runtime)
