#
# Post-install step for Boost in the OTB SuperBuild (Windows).
#
# Boost's b2 always installs its own headers into
# <prefix>/include/boost-<version> (the --includedir option is ignored for
# boost's own headers) and shared DLLs into <prefix>/lib.  That layout breaks
# consumers that do not use find_package(Boost) (e.g. GDAL's LIBKML driver
# includes <boost/...> headers through the installed libkml headers) and
# forces extra PATH juggling at runtime.  This script normalizes the
# installation:
#
#  1. Copies boost shared DLLs from lib/ into bin/.
#  2. Creates unversioned DLL copies (boost_<lib>.dll) for consumers that
#     link against plain names (OTB modules import e.g. boost_filesystem.dll).
#  3. Syncs headers from include/boost-1_82/boost into include/boost so that
#     plain <boost/...> includes resolve via <prefix>/include.
#  4. Fixes the boost-generated CMake config files that hard-code the
#     versioned include directory (include/boost-1_82).

if(NOT WIN32)
  message(FATAL_ERROR "boost_postinstall.cmake is only meant for Windows")
endif()

if(NOT DEFINED BOOST_LIB_DIR OR NOT DEFINED BOOST_BIN_DIR OR NOT DEFINED BOOST_CMAKE_DIR OR NOT DEFINED BOOST_INCLUDE_DIR)
  message(FATAL_ERROR "BOOST_LIB_DIR, BOOST_BIN_DIR, BOOST_CMAKE_DIR and BOOST_INCLUDE_DIR must be provided")
endif()

# --- 0) Headers: include/boost-1_82/boost -> include/boost -------------------
set(_boost_ver_headers "${BOOST_INCLUDE_DIR}/boost-1_82/boost")
set(_boost_headers "${BOOST_INCLUDE_DIR}/boost")
if(EXISTS "${_boost_ver_headers}")
  if(EXISTS "${_boost_headers}")
    execute_process(COMMAND "${CMAKE_COMMAND}" -E remove_directory "${_boost_headers}")
  endif()
  execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_directory "${_boost_ver_headers}" "${_boost_headers}")
  message(STATUS "boost post-install: synced headers into ${_boost_headers}")
endif()

# --- 1) + 2) DLLs into bin, with unversioned copies --------------------------
file(GLOB boost_dlls "${BOOST_LIB_DIR}/boost_*.dll")
foreach(dll ${boost_dlls})
  get_filename_component(dll_name "${dll}" NAME)
  file(COPY "${dll}" DESTINATION "${BOOST_BIN_DIR}")
  message(STATUS "boost post-install: copied ${dll_name} -> ${BOOST_BIN_DIR}")
  if(dll_name MATCHES "^boost_([^-]+)-.*\\.dll$")
    execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different
      "${dll}" "${BOOST_BIN_DIR}/boost_${CMAKE_MATCH_1}.dll")
    message(STATUS "boost post-install: unversioned copy boost_${CMAKE_MATCH_1}.dll -> ${BOOST_BIN_DIR}")
  endif()
endforeach()

# --- 3) Fix hard-coded versioned include dir in boost CMake configs ----------
file(GLOB_RECURSE boost_configs "${BOOST_CMAKE_DIR}/*.cmake")
foreach(cfg ${boost_configs})
  file(READ "${cfg}" content)
  if(content MATCHES "include/boost-1_82")
    string(REPLACE "include/boost-1_82" "include" content "${content}")
    file(WRITE "${cfg}" "${content}")
    message(STATUS "boost post-install: fixed ${cfg} (include/boost-1_82 -> include)")
  endif()
endforeach()
