# Patch script: replace Boost 1.82's bundled Boost.Build (tools/build/src)
# with the maintained b2 (https://github.com/bfgroup/b2) build system.
#
# Why: Boost 1.82's msvc.jam only knows MSVC up to 14.3 (VS2022). With a newer
# toolset (e.g. Visual Studio 2026 / MSVC 14.5) the bundled b2 mis-detects the
# compiler as the ancient "msvc-6.0" default (Windows CE target, links
# coredll.lib) and the whole boost build fails. b2's msvc.jam knows 14.5 and
# resolves VS2026 correctly.
#
# Run via ExternalProject_Add(PATCH_COMMAND ...) so it always re-applies
# after download+extract. Idempotent.
#
# Usage: cmake -DBOOST_SRC_DIR=<boost root> -DB2_SRC_DIR=<b2 src> -P script.cmake

if(NOT DEFINED BOOST_SRC_DIR)
  message(FATAL_ERROR "BOOST_SRC_DIR must point to the extracted boost root")
endif()
if(NOT DEFINED B2_SRC_DIR)
  message(FATAL_ERROR "B2_SRC_DIR must point to the b2 src tree (patches/BOOST/b2-src)")
endif()

set(boost_build_dir "${BOOST_SRC_DIR}/tools/build/src")
set(b2_src_dir "${B2_SRC_DIR}")

if(NOT EXISTS "${boost_build_dir}/build-system.jam")
  message(FATAL_ERROR "boost build dir not found: ${boost_build_dir}")
endif()
if(NOT EXISTS "${b2_src_dir}/build-system.jam")
  message(FATAL_ERROR "b2 src dir not found: ${b2_src_dir}")
endif()

# --- Remove the old bundled build system (engine must be rebuilt too) ---
file(REMOVE_RECURSE "${boost_build_dir}")
file(MAKE_DIRECTORY "${boost_build_dir}")

# --- Copy the b2 src tree in its place ---
file(COPY "${b2_src_dir}/" DESTINATION "${boost_build_dir}")

# --- Verify the critical files landed ---
foreach(need build-system.jam tools/msvc.jam engine/config_toolset.bat)
  if(NOT EXISTS "${boost_build_dir}/${need}")
    message(FATAL_ERROR "BOOST: b2 overwrite missing ${need}")
  endif()
endforeach()

# --- Verify the new msvc.jam actually knows MSVC 14.5 (VS2026) ---
file(READ "${boost_build_dir}/tools/msvc.jam" msvc_jam)
string(FIND "${msvc_jam}" "14.5" has_145)
if(has_145 EQUAL -1)
  message(FATAL_ERROR "BOOST: replaced msvc.jam does not support MSVC 14.5")
endif()

message(STATUS "BOOST: replaced bundled Boost.Build with b2 (msvc 14.5 support)")
