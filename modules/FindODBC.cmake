# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindODBC
# --------
#
# Find the ODBC library
#

### Windows SDK ###############################################################
if(WIN32)
  # Guess what architecture targets will end up being built
  if("${CMAKE_GENERATOR}" MATCHES "(Win64|IA64)")
    set(arch_hint "x64")
  elseif("${CMAKE_GENERATOR_PLATFORM}" MATCHES "ARM64")
    set(arch_hint "arm64")
  elseif("${CMAKE_GENERATOR}" MATCHES "ARM")
    set(arch_hint "arm")
  elseif("$ENV{LIB}" MATCHES "(amd64|ia64)")
    set(arch_hint "x64")
  elseif("${CMAKE_SIZEOF_VOID_P}" STREQUAL "8")
    set(arch_hint "x64")
  endif()

  if(NOT arch_hint)
    set(arch_hint "x86")
  endif()

  # Find the Windows 10 SDKs directories.
  get_filename_component(_windows10_kits_root_dir
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots;KitsRoot10]"
    ABSOLUTE)
  file(GLOB _windows10_kits_dirs LIST_DIRECTORIES TRUE
    "${_windows10_kits_root_dir}/include/*/um")
  unset(_windows10_kits_root_dir)
  # Poor-man ordering of 10.0.NNNNNN.0 folders from newest to oldest
  list(SORT _windows10_kits_dirs)
  list(REVERSE _windows10_kits_dirs)
  list(APPEND _odbc_include_hints ${_windows10_kits_dirs})
  unset(_windows10_kits_root_dir)

  # Determine "c:\Program Files" location of SDKs with ODBC development files
  if("$ENV{ProgramW6432}" STREQUAL "$ENV{ProgramFiles}")
    set(_program_files "ProgramFiles(x86)")
  else()
    set(_program_files "ProgramFiles")
  endif()
  file(TO_CMAKE_PATH "$ENV{${_program_files}}" _program_files)
  # Ordered to search kits from newest to oldest
  set(_odbc_include_paths
    "${_program_files}/Windows Kits/10/include/10.0.17134.0/um"
    "${_program_files}/Windows Kits/10/include/10.0.16299.0/um"
    "${_program_files}/Windows Kits/10/include/*/um"
    "${_program_files}/Windows Kits/8.1/include/um"
    "${_program_files}/Windows Kits/8.0/include/um"
    "${_program_files}/Windows Kits/*/include/um"
    "${_program_files}/Microsoft SDKs/Windows/v7.1A/include"
    "${_program_files}/Microsoft SDKs/Windows/v7.0A/include"
    "${_program_files}/Microsoft SDKs/Windows/v6.0A/include"
    "${_program_files}/Microsoft SDKs/Windows/*/include"
  )
  unset(_program_files)
endif()

### ODBC_INCLUDE_DIR ##########################################################
find_path(ODBC_INCLUDE_DIR
  NAMES sql.h
  HINTS ${_odbc_include_hints}
  PATHS ${_odbc_include_paths}
)
unset(_odbc_include_hints)
unset(_odbc_include_paths)

### ODBC_LIBRARIES ############################################################
if(WIN32 AND ODBC_INCLUDE_DIR)
  string(REGEX REPLACE "[Ii]nclude" "lib" _odbc_lib_paths ${ODBC_INCLUDE_DIR})
  string(APPEND _odbc_lib_paths "/${arch_hint}")
  file(TO_CMAKE_PATH "${_odbc_lib_paths}" _odbc_lib_paths)
endif()

find_library(_odbc32_lib_path
  NAMES odbc32
  PATHS ${_odbc_lib_paths}
)
unset(_odbc_lib_paths)

if(_odbc32_lib_path)
  set(ODBC_LIBRARIES ${_odbc32_lib_path})
endif()
unset(_odbc32_lib_path)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ODBC
  DEFAULT_MSG ODBC_LIBRARIES ODBC_INCLUDE_DIR
)

mark_as_advanced(ODBC_LIBRARIES ODBC_INCLUDE_DIR)

### ODBC targets ##############################################################
# TODO