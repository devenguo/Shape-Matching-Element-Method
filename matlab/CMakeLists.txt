cmake_minimum_required (VERSION 3.2)

project (vem_matlab)

set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/../mex )
set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/../mex )
set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/../mex )

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_SOURCE_DIR}/../cpp/cmake)
set(CMAKE_CXX_STANDARD 17)

#Disable OpenMP because I need to use a MATLAB specific setup to get this to work
if (VEM_USE_OPENMP)
	set(VEM_MATLAB_USE_OPENMP ON)
else()
	set(VEM_MATLAB_USE_OPENMP OFF)
endif()

set(VEM_USE_OPENMP OFF CACHE BOOL "Override option" FORCE)

include(${CMAKE_SOURCE_DIR}/../cpp/cmake/vem.cmake)

find_package(Matlab REQUIRED)
include_directories(${vem_INCLUDE_DIR} ${Matlab_INCLUDE_DIRS})

#MATLAB OpenMP directory which is needed to allow openmp usage in MEX files
#It OS specific
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
	set(Matlab_OMP_LIB "${Matlab_ROOT_DIR}/sys/os/glnxa64/libiomp5.so")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
	set(Matlab_OMP_LIB "${Matlab_ROOT_DIR}/sys/os/maci64/libiomp5.dylib")
elseif (${CMAKE_SYSTEM_NAME} MATCHES "Windows")
	set(Matlab_OMP_LIB "${Matlab_ROOT_DIR}/bin/win64/libiomp5md.lib")
endif()

message(${Matlab_OMP_LIB})
file(GLOB vem_MATLAB_SRCS ${CMAKE_SOURCE_DIR}/mex/*.cpp)

#compiler options
if(VEM_MATLAB_USE_OPENMP)
	find_package(OpenMP)
	if(OpenMP_CXX_FOUND)
		
		if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
			#Assuming libomp has been installed via homebrew (brew install libomp)
			include_directories("/usr/local/Cellar/libomp/10.0.0/include")
			set(OpenMP_CXX_FLAGS -Xpreprocessor -fopenmp)
		endif()

		target_compile_definitions(vem INTERFACE -DVEM_USE_OPENMP)

	endif()
endif()


foreach( file ${vem_MATLAB_SRCS})
	get_filename_component(name ${file} NAME_WE)
	
	matlab_add_mex(NAME ${name} 
			SRC ${file}
			LINK_TO ${Matlab_MX_LIBRARY} ${Matlab_MEX_LIBRARY} ${Matlab_OMP_LIB} vem
			OUTPUT_NAME ${name})

	if(VEM_MATLAB_USE_OPENMP)
		target_compile_options(${name} PUBLIC ${OpenMP_CXX_FLAGS})
		target_link_options(${name} PUBLIC ${OpenMP_CXX_FLAGS})

		set(VEM_USE_OPENMP ON CACHE BOOL "Override option" FORCE)
	endif()
	

endforeach( file vem_MATLAB_SRCS )


