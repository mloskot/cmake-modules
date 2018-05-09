cmake_minimum_required(VERSION 3.11)
project(cmake_modules_test)

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/modules)

find_package(ODBC REQUIRED)

message(STATUS "ODBC_INCLUDE_DIR=${ODBC_INCLUDE_DIR}")
message(STATUS "ODBC_LIBRARIES=${ODBC_LIBRARIES}")