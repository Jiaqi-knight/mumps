# run by:
# ctest -S setup.cmake

# --- Project-specific -Doptions
# these will be used if the project isn't already configured.
set(_opts)

# --- boilerplate follows
message(STATUS "CMake ${CMAKE_VERSION}")
if(CMAKE_VERSION VERSION_LESS 3.15)
  message(FATAL_ERROR "Please update CMake >= 3.15")
endif()

# we use presence of MPIEXEC as a weak assumption that MPI is OK.
find_program(_mpiexec NAMES mpiexec)
if(_mpiexec)
  set(_opts -Dparallel:BOOL=on)
else()
  set(_opts -Dparallel:BOOL=off)
endif(_mpiexec)

# site is OS name
if(NOT DEFINED CTEST_SITE)
  set(CTEST_SITE ${CMAKE_SYSTEM_NAME})
endif()

# test name is Fortran compiler in FC
# Note: ctest scripts cannot read cache variables like CMAKE_Fortran_COMPILER
if(DEFINED ENV{FC})
  set(FC $ENV{FC})
  set(CTEST_BUILD_NAME ${FC})

  if(NOT DEFINED ENV{CC})
    # use same compiler for C and Fortran, which CMake might not do itself
    if(FC STREQUAL ifort)
      if(WIN32)
        set(ENV{CC} icl)
      else()
        set(ENV{CC} icc)
      endif()
    endif()
  endif()
endif()

if(NOT DEFINED CTEST_BUILD_CONFIGURATION)
  set(CTEST_BUILD_CONFIGURATION "Release")
endif()

set(CTEST_SOURCE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR})
if(NOT DEFINED CTEST_BINARY_DIRECTORY)
  set(CTEST_BINARY_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/build)
endif()

# CTEST_CMAKE_GENERATOR must be defined in any case here.
# we ignore CMAKE_GENERATOR environment variable to workaround bugs with CMake.
if(NOT DEFINED CTEST_CMAKE_GENERATOR)
  if(WIN32)
    # Ninja should work with Intel compiler, but there is a CMake bug temporarily preventing this
    set(CTEST_CMAKE_GENERATOR "MinGW Makefiles")
    set(CTEST_BUILD_FLAGS -j)  # not --parallel as this goes to generator directly
  else()
    find_program(_gen NAMES ninja ninja-build samu)
    if(_gen)
      set(CTEST_CMAKE_GENERATOR "Ninja")
    else()
      set(CTEST_CMAKE_GENERATOR "Unix Makefiles")
      set(CTEST_BUILD_FLAGS -j)  # not --parallel as this goes to generator directly
    endif()
  endif()
endif()

# -- build and test
ctest_start("Experimental" ${CTEST_SOURCE_DIRECTORY} ${CTEST_BINARY_DIRECTORY})

if(NOT EXISTS ${CTEST_BINARY_DIRECTORY}/CMakeCache.txt)
  ctest_configure(
    BUILD ${CTEST_BINARY_DIRECTORY}
    SOURCE ${CTEST_SOURCE_DIRECTORY}
    OPTIONS "${_opts}"
    RETURN_VALUE return_code
    CAPTURE_CMAKE_ERROR cmake_err)
endif()

if(return_code EQUAL 0 AND cmake_err EQUAL 0)
  ctest_build(
    BUILD ${CTEST_BINARY_DIRECTORY}
    CONFIGURATION ${CTEST_BUILD_CONFIGURATION}
    RETURN_VALUE return_code
    NUMBER_ERRORS Nerror
    CAPTURE_CMAKE_ERROR cmake_err
    )
endif()

if(return_code EQUAL 0 AND Nerror EQUAL 0 AND cmake_err EQUAL 0)
  ctest_test(
  BUILD ${CTEST_BINARY_DIRECTORY}
  RETURN_VALUE return_code
  CAPTURE_CMAKE_ERROR ctest_err
  )
endif()

ctest_submit()
