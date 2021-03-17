cmake_minimum_required(VERSION 3.17)

project(point_detect C)

set(CMAKE_C_STANDARD 11)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -DNDEBUG -DSMALL_INT -Wall -Wpedantic -Wextra")

add_library(point_detect point_detect.c)