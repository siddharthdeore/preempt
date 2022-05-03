cmake_minimum_required(VERSION 3.14)
project(ThreadExamples)

include_directories(../include)

add_executable(cpu_affinity cpu_affinity.cpp )
target_link_libraries(cpu_affinity ThreadWrapper)

add_executable(cpu_affinity_array cpu_affinity_array.cpp )
target_link_libraries(cpu_affinity_array ThreadWrapper)

add_executable(thread_priority thread_priority.cpp )
target_link_libraries(thread_priority ThreadWrapper)

add_executable(rt_thread rt_thread.cpp )
target_link_libraries(rt_thread ThreadWrapper)

add_executable(periodic_thread periodic_thread.cpp )
target_link_libraries(periodic_thread ThreadWrapper)