# Eigen3
set(EIGEN3_INCLUDE_DIR "${FIND_LIBRARIES_INCLUDE_ROOT}/eigen3" CACHE PATH "Location(s) of Eigen headers.")
IF(EXISTS "${EIGEN3_INCLUDE_DIR}" AND IS_DIRECTORY "${EIGEN3_INCLUDE_DIR}")
	set(LIBRARY_EIGEN3_FOUND 1)
else()
	set(LIBRARY_EIGEN3_FOUND 0)
endif()


