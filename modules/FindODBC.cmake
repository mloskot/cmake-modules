# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#.rst:
# FindODBC
# --------
#
# Find the ODBC include directory and library.
#
# Use this module by invoking find_package with the form::
#
#   find_package(ODBC
#     [REQUIRED]             # Fail with error if ODBC is not found
#   )
#
# On Windows, this module searches for ODBC library included in
# available Windows SDKs, in order from newest to oldest.
# On Windows 10, default SDK location hint is read from registry.
# On previous versions, list of known locations is searched.
#
# On Unix, this module allows to search for ODBC library provided by
# unixODBC or iODBC implementations of ODBC API.
# This module reads hint about location of the config program:
#
#   ODBC_CONFIG - Location of odbc_config or iodbc-config program
#
# Othwerise, this module tries to find the config program,
# first from unixODBC, then from iODBC.
# If no config program found, this module searches for ODBC header
# and library in list of known locations.
#
# Imported targets
# ^^^^^^^^^^^^^^^^
#
# This module defines the following :prop_tgt:`IMPORTED` targets:
#
# ``ODBC::ODBC``
#   The ODBC library, if found.
#
# Cache variables
# ^^^^^^^^^^^^^^^
#
# ``ODBC_CONFIG``
#   Location to unixODBC or iODBC config program, if found or specified.
# ``ODBC_FOUND``
#   True if ODBC library found.
#
# Limitations
# ^^^^^^^^^^^
#
# On Windows, this module does not search for iODBC.
# On Unix, there is no way to prefer unixODBC over iODBC, or vice versa,
# other than providing the config program location using the ``ODBC_CONFIG``.
# This module does not allow to search for a specific ODBC driver.


### Try Windows Kits ##########################################################
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

  # List names of ODBC libraries on Windows
  set(_odbc_lib_names odbc32;)

  # List additional libraries required to use ODBC library
  if(MSVC OR CMAKE_CXX_COMPILER_ID MATCHES "Intel")set(_odbc_required_libs_names odbccp32;ws2_32)
  elseif(MINGW)
    set(_odbc_required_libs_names odbccp32)
  endif()
endif()

### Try nixODBC or iODBC config program #######################################
if (UNIX AND NOT ODBC_CONFIG)
  find_program(ODBC_CONFIG
    NAMES odbc_config iodbc-config
    DOC "Path to unixODBC or iODBC config program")
endif()

if (UNIX AND ODBC_CONFIG)
  # unixODBC and iODBC accept unified command line options
  execute_process(COMMAND ${ODBC_CONFIG} --cflags
    OUTPUT_VARIABLE _cflags OUTPUT_STRIP_TRAILING_WHITESPACE)
  execute_process(COMMAND ${ODBC_CONFIG} --libs
    OUTPUT_VARIABLE _libs OUTPUT_STRIP_TRAILING_WHITESPACE)

  # Collect paths of include directories from CFLAGS
  string(REGEX MATCHALL "\-I(/[^/ ]+)+" _cflags ${_cflags})
  foreach(_path IN LISTS _cflags)
    string(REGEX REPLACE "\-I(/[^/ ]+)" "\\1" _path ${_path})
    list(APPEND _odbc_include_paths ${_path})
  endforeach()
  unset(_cflags)

  # Collect paths of lib directories from LIBS
  string(REGEX MATCHALL "\-L(/[^/ ]+)+" _lib_paths "${_libs}")
  foreach(_path IN LISTS _lib_paths)
    string(REGEX REPLACE "\-L(/[^/ ]+)" "\\1" _path ${_path})
    list(APPEND _odbc_lib_paths ${_path})
    string(REPLACE "-L${_path}" "" _libs ${_libs})
  endforeach()

  # Collect names of libraries from LIBS
  string(REGEX MATCHALL "\-l[a-zA-Z0-9_-]+" _libs ${_libs})
  set(_z -ldl;-lpthread;)
  foreach(_lib IN LISTS _libs _z)
    string(REGEX REPLACE "-l([a-zA-Z0-9_-]+)" "\\1" _lib ${_lib})
    string(REGEX MATCH "odbc" _is_odbc ${_lib})
    if(_is_odbc)
      list(APPEND _odbc_lib_names ${_lib})
    else()
      list(APPEND _odbc_required_libs_names ${_lib})
    endif()
  endforeach()
  unset(_libs)
endif()

### Try unixODBC or iODBC in include/lib filesystems ##########################
if (UNIX AND NOT ODBC_CONFIG)
  # List names of both ODBC libraries, unixODBC and iODBC
  set(_odbc_lib_names odbc;iodbc;unixodbc;)

  set(_odbc_include_paths
    /usr/include
    /usr/include/odbc
    /usr/local/include
    /usr/local/include/odbc
    /usr/local/odbc/include)

  set(_odbc_lib_paths
    /usr/lib
    /usr/lib/odbc
    /usr/local/lib
    /usr/local/lib/odbc
    /usr/local/odbc/lib)
endif()

# DEBUG
#message("_odbc_include_hints=${_odbc_include_hints}")
#message("_odbc_include_paths=${_odbc_include_paths}")
#message("_odbc_lib_paths=${_odbc_lib_paths}")
#message("_odbc_lib_names=${_odbc_lib_names}")

### Find include directories ##################################################
find_path(_odbc_include_dir
  NAMES sql.h
  HINTS ${_odbc_include_hints}
  PATHS ${_odbc_include_paths})

unset(_odbc_include_hints)
unset(_odbc_include_paths)

### Find libraries ############################################################
if(WIN32 AND _odbc_include_dir)
  string(REGEX REPLACE "[Ii]nclude" "lib" _odbc_lib_paths ${_odbc_include_dir})
  string(APPEND _odbc_lib_paths "/${arch_hint}")
  file(TO_CMAKE_PATH "${_odbc_lib_paths}" _odbc_lib_paths)
endif()

find_library(_odbc_library
  NAMES ${_odbc_lib_names}
  PATHS ${_odbc_lib_paths})

foreach(_lib IN LISTS _odbc_required_libs_names)
  find_library(_lib_path
    NAMES ${_lib}
    PATHS ${_odbc_lib_paths}) # system parths or collected from ODBC_CONFIG
  if (_lib_path)
    list(APPEND _odbc_required_libs_paths ${_lib_path})
  endif()
  unset(_lib_path CACHE)
endforeach()

unset(_odbc_lib_names)
unset(_odbc_lib_paths)
unset(_odbc_required_libs_names)

### Set ODBC_FOUND ############################################################
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ODBC
  DEFAULT_MSG
  _odbc_library _odbc_include_dir)

# NOTE: Private variables must not be removed from cache, may only be hidden
#unset(_odbc_library CACHE)
#unset(_odbc_include_dir CACHE)
mark_as_advanced(FORCE _odbc_library _odbc_include_dir)

if(ODBC_CONFIG)
  mark_as_advanced(FORCE ODBC_CONFIG)
endif()

### Import targets ############################################################
if(ODBC_FOUND)
  if(NOT TARGET ODBC::ODBC)
    add_library(ODBC::ODBC UNKNOWN IMPORTED)
    set_target_properties(ODBC::ODBC
      PROPERTIES
      IMPORTED_LINK_INTERFACE_LANGUAGES "C"
      IMPORTED_LOCATION "${_odbc_library}"
      INTERFACE_INCLUDE_DIRECTORIES "${_odbc_include_dir}"
      INTERFACE_LINK_LIBRARIES "${_odbc_required_libs_paths}")
  endif()
endif()
