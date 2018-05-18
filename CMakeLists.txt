cmake_minimum_required(VERSION 3.11)
project(cmake_modules_test LANGUAGES C)

list(INSERT CMAKE_MODULE_PATH 0 ${CMAKE_CURRENT_LIST_DIR}/modules)

find_package(ODBC)
if(ODBC_FOUND)
  add_executable(use_odbc use_odbc.c)
  target_link_libraries(use_odbc ODBC::ODBC)
endif()

find_package(LZ4 "1.8.0" EXACT)
if(LZ4_FOUND)
  add_executable(use_lz4 use_lz4.c)
  target_link_libraries(use_lz4 LZ4::LZ4)

  message(STATUS "LZ4_VERSION=${LZ4_VERSION}")
  message(STATUS "LZ4_LIBRARIES=${LZ4_LIBRARIES}")
  message(STATUS "LZ4_INCLUDE_DIRS=${LZ4_INCLUDE_DIRS}")
endif()
