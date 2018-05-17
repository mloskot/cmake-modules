cmake_minimum_required(VERSION 3.11)
project(cmake_modules_test LANGUAGES C)

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/modules)

find_package(ODBC REQUIRED)

add_executable(use_odbc use_odbc.c)
target_link_libraries(use_odbc ODBC::ODBC)
