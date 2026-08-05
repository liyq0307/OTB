#
# Copyright (C) 2005-2024 Centre National d'Etudes Spatiales (CNES)
#
# This file is part of Orfeo Toolbox
#
#     https://www.orfeo-toolbox.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

add_executable(otbQgisDescriptor otbQgisDescriptor.cxx)
target_link_libraries(otbQgisDescriptor ${OTBQGIS_LIBRARIES})
otb_module_target(otbQgisDescriptor COMPONENT_Core)

add_custom_command(TARGET otbQgisDescriptor PRE_BUILD
  COMMAND "${CMAKE_COMMAND}" "-E" "echo" "Cleaning ${OTB_BINARY_DIR}/${OTB_INSTALL_DATA_DIR}/description/"
  COMMAND "${CMAKE_COMMAND}" "-E" "remove_directory" "${OTB_BINARY_DIR}/${OTB_INSTALL_DATA_DIR}/description/"
  COMMAND "${CMAKE_COMMAND}" "-E" "make_directory"   "${OTB_BINARY_DIR}/${OTB_INSTALL_DATA_DIR}/description/"
  )

file(RELATIVE_PATH app_location ${OTB_BINARY_DIR} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/otb/applications)
# Multi-config generators (Visual Studio) place the application DLLs in a
# per-config subdirectory (e.g. lib/otb/applications/Release). The descriptor
# tool does not append the config itself, so include it in the path.
if(CMAKE_CONFIGURATION_TYPES)
  set(app_location "${app_location}/$<CONFIG>")
endif()

set(app_names ${OTB_APPLICATIONS_NAME_LIST})
list(REMOVE_ITEM app_names "TestApplication")
list(REMOVE_ITEM app_names "ApplicationExample")
list(REMOVE_DUPLICATES app_names)
set(dfiles)
set(generate_descriptor_cmd "$<TARGET_FILE:otbQgisDescriptor>")
#debian does not use RPATH and build is failing
#see gitlab #1593
#if( "${CMAKE_SYSTEM_NAME}"  MATCHES "Linux")
if(CMAKE_SKIP_RPATH AND "${CMAKE_SYSTEM_NAME}"  MATCHES "Linux")
  set(generate_descriptor_cmd "env;LD_LIBRARY_PATH=${OTB_BINARY_DIR}/lib;$<TARGET_FILE:otbQgisDescriptor>")
endif()
# On Windows, the descriptor tool runs as a custom build step whose process
# PATH does not include the superbuild install bin dir (where the runtime
# DLLs of boost/gdal/curl/... live).  Prepend it so the tool can load its
# DLLs (otherwise the step fails with STATUS_DLL_NOT_FOUND, 0xC0000135).
if(WIN32 AND CMAKE_PREFIX_PATH)
  list(GET CMAKE_PREFIX_PATH 0 _sb_prefix)
  set(generate_descriptor_cmd
    "${CMAKE_COMMAND};-E;env;--modify;PATH=path_list_prepend:${_sb_prefix}/bin;$<TARGET_FILE:otbQgisDescriptor>")
endif()
# generate dependency list
# put all app into a file
# same for dfiles
set(QGIS_APP_LIST_FILE "${CMAKE_CURRENT_BINARY_DIR}/qgis_apps_list.txt")
# if file does not exists it does not emit an error
file(REMOVE "${QGIS_APP_LIST_FILE}")
file(TOUCH "${QGIS_APP_LIST_FILE}")
set(QGIS_APP_DESCRIPTOR_PATH "${OTB_BINARY_DIR}/${OTB_INSTALL_DATA_DIR}/description")

foreach(app_name ${app_names})
  add_dependencies(otbQgisDescriptor otbapp_${app_name})
  file(APPEND "${QGIS_APP_LIST_FILE}" "${app_name}\n")
endforeach()

# call otbQgisDescriptor with the app list, the location to create the files 
add_custom_command(OUTPUT "${QGIS_APP_DESCRIPTOR_PATH}/algs.txt"
  COMMAND ${generate_descriptor_cmd}
  "${QGIS_APP_LIST_FILE}" "${app_location}" "./${OTB_INSTALL_DATA_DIR}/description/"
  WORKING_DIRECTORY ${OTB_BINARY_DIR}
  COMMENT "Generate gqis descriptor files"
  VERBATIM)

add_custom_target(generate_descriptors DEPENDS "${QGIS_APP_DESCRIPTOR_PATH}/algs.txt")
add_dependencies(${otb-module}-all generate_descriptors)
