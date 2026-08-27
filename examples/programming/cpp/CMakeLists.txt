cmake_minimum_required(VERSION 3.25)
project(cpp-http-server VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

enable_testing()

add_executable(cpp-http-server src/main.cpp)

add_test(NAME cpp-http-server TEST cpp-http-server)

if(APPVEYOR OR CI)
    set(CMAKE_BUILD_TYPE Release)
endif()