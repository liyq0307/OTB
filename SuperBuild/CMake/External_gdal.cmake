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
#

INCLUDE_ONCE_MACRO(GDAL)

SETUP_SUPERBUILD(GDAL)

ADDTO_DEPENDENCIES_IF_NOT_SYSTEM(GDAL CURL OPENJPEG TIFF GEOTIFF PNG JPEG SQLITE GEOS ZLIB EXPAT HDF5 NETCDF HDF4 PROJ)

set(GDAL_URL "https://github.com/OSGeo/gdal/releases/download/v3.9.0/gdal-3.9.0.tar.gz")
set(GDAL_MD5 d3780907608f381a4f662cb1480c7f97)

# avoid use of system SPATIALITE which can use other libproj which cause conflict
list(APPEND GDAL_CONFIG_LIBS
            -DGDAL_USE_EXPAT:BOOL=ON
            -DGDAL_USE_EXTERNAL_LIBS:BOOL=ON
            -DGDAL_USE_GEOS:BOOL=ON
            -DGDAL_USE_GEOTIFF:BOOL=ON
            -DGDAL_USE_TIFF:BOOL=ON
            -DGDAL_USE_JPEG:BOOL=ON
            -DGDAL_USE_SQLITE3:BOOL=ON
            -DGDAL_USE_NETCDF:BOOL=ON
            -DGDAL_USE_ZLIB:BOOL=ON
            -DGDAL_USE_INTERNAL_LIBS:STRING=WHEN_NO_EXTERNAL
            -DGDAL_USE_HDF4:BOOL=ON
            -DGDAL_USE_HDF5:BOOL=ON
            -DGDAL_USE_PNG:BOOL=ON
            -DGDAL_USE_SPATIALITE:BOOL=OFF
            -DGDAL_USE_JSONC_INTERNAL:BOOL=ON
            -DGDAL_USE_LERC:BOOL=ON)

if (WIN32)
   list(APPEND GDAL_CONFIG_LIBS -DGDAL_USE_OPENSSL:BOOL=OFF)
else() # real OS does support OpenSSL
   list(APPEND GDAL_CONFIG_LIBS -DGDAL_USE_OPENSSL:BOOL=ON)
endif()

if(WIN32)
   # HDF4 debug libraries carry a _D suffix (dfalt_D.lib / mfhdfalt_D.lib),
   # which GDAL's FindHDF4 does not probe (it looks for dfaltd / mfhdfaltd /
   # dfalt / mfhdf).  Pre-seed its per-config cache variables with a generator
   # expression.  Both _DEBUG and _RELEASE get the SAME genex so that, once it
   # is resolved per configuration, select_library_configurations() sees two
   # equal paths, skips the "optimized;...;debug;..." multi-config form, and
   # yields a single plain path for IMPORTED_LOCATION (which cannot carry the
   # optimized/debug keywords).
   list(APPEND GDAL_CONFIG_LIBS
     -DHDF4_df_LIBRARY_DEBUG:FILEPATH=$<IF:$<CONFIG:Debug>,${SB_INSTALL_PREFIX}/lib/dfalt_D.lib,${SB_INSTALL_PREFIX}/lib/dfalt.lib>
     -DHDF4_df_LIBRARY_RELEASE:FILEPATH=$<IF:$<CONFIG:Debug>,${SB_INSTALL_PREFIX}/lib/dfalt_D.lib,${SB_INSTALL_PREFIX}/lib/dfalt.lib>
     -DHDF4_mfhdf_LIBRARY_DEBUG:FILEPATH=$<IF:$<CONFIG:Debug>,${SB_INSTALL_PREFIX}/lib/mfhdfalt_D.lib,${SB_INSTALL_PREFIX}/lib/mfhdfalt.lib>
     -DHDF4_mfhdf_LIBRARY_RELEASE:FILEPATH=$<IF:$<CONFIG:Debug>,${SB_INSTALL_PREFIX}/lib/mfhdfalt_D.lib,${SB_INSTALL_PREFIX}/lib/mfhdfalt.lib>)
endif()

ExternalProject_Add(GDAL
   PREFIX GDAL
   DEPENDS ${GDAL_DEPENDENCIES}
   URL ${GDAL_URL}
   URL_MD5 ${GDAL_MD5}
   SOURCE_DIR ${GDAL_SB_SRC}
   BINARY_DIR ${GDAL_SB_BUILD_DIR}
   INSTALL_DIR ${SB_INSTALL_PREFIX}
   DOWNLOAD_DIR ${DOWNLOAD_LOCATION}
   CMAKE_CACHE_ARGS
   ${SB_CMAKE_CACHE_ARGS}
   ${GDAL_CONFIG_LIBS}
   -DBUILD_APPS:BOOL=ON
   -DBUILD_CSHARP_BINDINGS:BOOL=OFF
   -DBUILD_JAVA_BINDINGS:BOOL=OFF
   -DBUILD_PYTHON_BINDINGS:BOOL=OFF
   -DBUILD_SHARED_LIBS:BOOL=ON
   -DBUILD_TESTING:BOOL=ON
   -DSQLite3_HAS_RTREE:BOOL=ON 
   -DSQLite3_HAS_COLUMN_METADATA:BOOL=ON
   -DSQLite3_HAS_MUTEX_ALLOC:BOOL=ON
   -DCMAKE_INSTALL_LIBDIR:STRING=lib
   CMAKE_COMMAND ${SB_CMAKE_COMMAND}
   LOG_DOWNLOAD 1
   LOG_CONFIGURE 1
   LOG_BUILD 1
   LOG_INSTALL 1
)
