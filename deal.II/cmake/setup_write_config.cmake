## ---------------------------------------------------------------------
## $Id$
##
## Copyright (C) 2012 - 2013 by the deal.II authors
##
## This file is part of the deal.II library.
##
## The deal.II library is free software; you can use it, redistribute
## it, and/or modify it under the terms of the GNU Lesser General
## Public License as published by the Free Software Foundation; either
## version 2.1 of the License, or (at your option) any later version.
## The full text of the license can be found in the file LICENSE at
## the top level of the deal.II distribution.
##
## ---------------------------------------------------------------------


########################################################################
#                                                                      #
#              Write a nice configuration summary to file:             #
#                                                                      #
########################################################################

SET(_log_detailed "${CMAKE_BINARY_DIR}/detailed.log")
SET(_log_summary  "${CMAKE_BINARY_DIR}/summary.log")
FILE(REMOVE ${_log_detailed} ${_log_summary})

MACRO(_both)
  # Write to both log files:
  FILE(APPEND ${_log_detailed} "${ARGN}")
  FILE(APPEND ${_log_summary} "${ARGN}")
ENDMACRO()
MACRO(_detailed)
  # Only write to detailed.log:
  FILE(APPEND ${_log_detailed} "${ARGN}")
ENDMACRO()
MACRO(_summary)
  # Only write to summary.log:
  FILE(APPEND ${_log_summary} "${ARGN}")
ENDMACRO()

_both(
"###
#
#  ${DEAL_II_PACKAGE_NAME} configuration:
#        CMAKE_BUILD_TYPE:       ${CMAKE_BUILD_TYPE}
#        BUILD_SHARED_LIBS:      ${BUILD_SHARED_LIBS}
#        CMAKE_INSTALL_PREFIX:   ${CMAKE_INSTALL_PREFIX}
#        CMAKE_SOURCE_DIR:       ${CMAKE_SOURCE_DIR} (Version ${DEAL_II_PACKAGE_VERSION})
#        CMAKE_BINARY_DIR:       ${CMAKE_BINARY_DIR}
#        CMAKE_CXX_COMPILER:     ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION} on platform ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}
#                                ${CMAKE_CXX_COMPILER}
"
  )

IF(CMAKE_C_COMPILER_WORKS)
  _detailed("#        CMAKE_C_COMPILER:       ${CMAKE_C_COMPILER}\n")
ENDIF()
IF(CMAKE_Fortran_COMPILER_WORKS)
  _detailed("#        CMAKE_Fortran_COMPILER: ${CMAKE_Fortran_COMPILER}\n")
ENDIF()
_detailed("#        CMAKE_GENERATOR:        ${CMAKE_GENERATOR}\n")

IF(CMAKE_CROSSCOMPILING)
  _both(
    "#\n#        CROSSCOMPILING!\n"
    )
ENDIF()

IF(DEAL_II_STATIC_EXECUTABLE)
  _both(
    "#\n#        STATIC LINKAGE!\n"
    )
ENDIF()

_both("#\n")

_detailed(
"#  Compiler flags used for this build:
#        DEAL_II_CXX_FLAGS:            ${DEAL_II_CXX_FLAGS}
"
  )
IF(CMAKE_BUILD_TYPE MATCHES "Release")
  _detailed("#        DEAL_II_CXX_FLAGS_RELEASE:    ${DEAL_II_CXX_FLAGS_RELEASE}\n")
ENDIF()
IF(CMAKE_BUILD_TYPE MATCHES "Debug")
  _detailed("#        DEAL_II_CXX_FLAGS_DEBUG:      ${DEAL_II_CXX_FLAGS_DEBUG}\n")
ENDIF()

_detailed("#        DEAL_II_LINKER_FLAGS:         ${DEAL_II_LINKER_FLAGS}\n")
IF(CMAKE_BUILD_TYPE MATCHES "Release")
  _detailed("#        DEAL_II_LINKER_FLAGS_RELEASE: ${DEAL_II_LINKER_FLAGS_RELEASE}\n")
ENDIF()
IF(CMAKE_BUILD_TYPE MATCHES "Debug")
  _detailed("#        DEAL_II_LINKER_FLAGS_DEBUG:   ${DEAL_II_LINKER_FLAGS_DEBUG}\n")
ENDIF()

_detailed("#        DEAL_II_DEFINITIONS:          ${DEAL_II_DEFINITIONS}\n")
IF(CMAKE_BUILD_TYPE MATCHES "Release")
  _detailed("#        DEAL_II_DEFINITIONS_RELEASE:  ${DEAL_II_DEFINITIONS_RELEASE}\n")
ENDIF()
IF(CMAKE_BUILD_TYPE MATCHES "Debug")
  _detailed("#        DEAL_II_DEFINITIONS_DEBUG:    ${DEAL_II_DEFINITIONS_DEBUG}\n")
ENDIF()

_detailed("#\n")

IF(NOT DEAL_II_SETUP_DEFAULT_COMPILER_FLAGS)
  _both("#  WARNING: DEAL_II_SETUP_DEFAULT_COMPILER_FLAGS is set to OFF\n")
ENDIF()
_both("#  Configured Features (")
IF(DEFINED DEAL_II_ALLOW_BUNDLED)
  _both("DEAL_II_ALLOW_BUNDLED = ${DEAL_II_ALLOW_BUNDLED}, ")
ENDIF()
IF(DEAL_II_FORCE_AUTODETECTION)
  _both("!!! DEAL_II_FORCE_AUTODETECTION=ON !!!, ")
ENDIF()
_both("DEAL_II_ALLOW_AUTODETECTION = ${DEAL_II_ALLOW_AUTODETECTION}):\n")


#
# Cache for quicker access to avoid the O(n^2) complexity of a loop over
# _all_ defined variables.
#

GET_CMAKE_PROPERTY(_variables VARIABLES)
FOREACH(_var ${_variables})
  IF(_var MATCHES "DEAL_II_WITH")
    LIST(APPEND _features "${_var}")
  ELSEIF(_var MATCHES "DEAL_II_COMPONENT")
    LIST(APPEND _components "${_var}")
  ENDIF()
ENDFOREACH()

FOREACH(_var ${_features})
  IF(${${_var}})
    # FEATURE is enabled
    STRING(REGEX REPLACE "^DEAL_II_WITH_" "" _feature ${_var})
    IF(FEATURE_${_feature}_EXTERNAL_CONFIGURED)
      _both("#        ${_var} set up with external dependencies\n")

      #
      # Print out version number:
      #
      IF(DEFINED ${_feature}_VERSION)
        _detailed("#            ${_feature}_VERSION = ${${_feature}_VERSION}\n")
      ENDIF()

      #
      # Special version numbers:
      #
      IF(_feature MATCHES "THREADS" AND DEFINED TBB_VERSION)
        _detailed("#            TBB_VERSION = ${TBB_VERSION}\n")
      ENDIF()
      IF(_feature MATCHES "MPI" AND DEFINED OMPI_VERSION)
        _detailed("#            OMPI_VERSION = ${OMPI_VERSION}\n")
      ENDIF()

      #
      # Print out ${_feature}_DIR:
      #
      IF(NOT "${${_feature}_DIR}" STREQUAL "")
        _detailed("#            ${_feature}_DIR = ${${_feature}_DIR}\n")
      ENDIF()

      #
      # Print the feature configuration:
      #
      FOREACH(_var2
          CXX_COMPILER C_COMPILER Fortran_COMPILER LIBRARIES INCLUDE_DIRS
          USER_INCLUDE_DIRS DEFINITIONS USER_DEFINITIONS CXX_FLAGS
          LINKER_FLAGS
        )
        IF(DEFINED ${_feature}_${_var2})
          _detailed("#            ${_feature}_${_var2} = ${${_feature}_${_var2}}\n")
        ENDIF()
      ENDFOREACH()

    ELSEIF(FEATURE_${_feature}_BUNDLED_CONFIGURED)

      IF(DEAL_II_FORCE_BUNDLED_${_feature})
        _both("#        ${_var} set up with bundled packages (forced)\n")
      ELSE()
        _both("#        ${_var} set up with bundled packages\n")
      ENDIF()
    ELSE()
     _both("#        ${_var} = ${${_var}}\n")
    ENDIF()
  ELSE()
    # FEATURE is disabled
    _both("#      ( ${_var} = ${${_var}} )\n")
  ENDIF()
ENDFOREACH()

_both(
  "#\n#  Component configuration:\n"
  )
FOREACH(_var ${_components})
  IF(_var MATCHES "DEAL_II_COMPONENT")
    IF(${${_var}})
      _both("#        ${_var}\n")
      STRING(REPLACE "DEAL_II_COMPONENT_" "" _component ${_var})
      LIST(APPEND _components ${_component})
    ELSE()
      _both("#      ( ${_var} = ${${_var}} )\n")
    ENDIF()
  ENDIF()
ENDFOREACH()

_summary(
"#\n#  Detailed information (compiler flags, feature configuration) can be found in detailed.log
#\n#  Run  $ "
  )
IF(CMAKE_GENERATOR MATCHES "Ninja")
  _summary("ninja info")
ELSE()
_summary("make help")
ENDIF()
_summary("  to print a help message with a list of top level targets\n")

_both("#\n###")


########################################################################
#                                                                      #
#                    Dump the cache into config.cmake:                 #
#                                                                      #
########################################################################

SET(_config_cmake "${CMAKE_BINARY_DIR}/config.cmake")
FILE(WRITE ${_config_cmake}
"#
# This is a raw CMake cache dump of this build directory suitable as an
# initial cache file: Use this file to preseed a CMake cache in an empty
# build directory by (note that it is still necessary to declare a source
# directory):
#   $ cmake -C [...]/config.cmake ../deal.II
#
# If you want to have a clean configuration file have a look at
# doc/users/config.sample
#\n"
  )

FUNCTION(_config _var)
  # It is absolutely beyond my comprehension why on earth there is
  # hardcoded logic built into CMake to throw an error if one uses
  # uppercase variants of FindPACKAGE call variables...
  IF(NOT _var MATCHES "BOOST_DIR")
    UNSET(${_var})
  ENDIF()
  #
  # We have to get down to the raw entry in the cache, therefore clear the
  # current value (and do it in a function to get private scope):
  #
  FILE(APPEND ${_config_cmake}
    "SET(${_var} \"${${_var}}\" CACHE STRING \"\")\n"
    )
ENDFUNCTION()

GET_CMAKE_PROPERTY(_variables CACHE_VARIABLES)
FOREACH(_var
    CMAKE_C_COMPILER
    CMAKE_CXX_COMPILER
    CMAKE_Fortran_COMPILER
    ${_variables}
    )
  _config(${_var})
ENDFOREACH()
