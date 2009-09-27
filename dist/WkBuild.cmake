# 
# Copyright (c) 2009, Asmodehn's Corp.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#	    this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#		notice, this list of conditions and the following disclaimer in the 
#	    documentation and/or other materials provided with the distribution.
#     * Neither the name of the Asmodehn's Corp. nor the names of its 
#	    contributors may be used to endorse or promote products derived
#	    from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.
#

if ( CMAKE_BACKWARDS_COMPATIBILITY LESS 2.6 )
	message ( FATAL_ERROR " CMAKE MINIMUM BACKWARD COMPATIBILITY REQUIRED : 2.6 !" )
endif( CMAKE_BACKWARDS_COMPATIBILITY LESS 2.6 )

# using useful Macros
include ( CMake/WkUtils.cmake )

#To setup the compiler
include ( CMake/WkCompilerSetup.cmake )

macro(WKProject project_name_arg)
CMAKE_POLICY(PUSH)
CMAKE_POLICY(VERSION 2.6)
	project(${project_name_arg} ${ARGN})
	WkCompilerSetup( )
	#preparing and cleaning internal build variables
	set( ${PROJECT_NAME}_INCLUDE_DIRS CACHE INTERNAL " Includes directories for ${PROJECT_NAME} ")
	set( ${project_name_arg}_LIBRARIES CACHE INTERNAL " libraries needed for ${target_name} " )
	set( ${project_name_arg}_RUN_LIBRARIES CACHE INTERNAL " libraries needed to run ${target_name} " )
CMAKE_POLICY(POP)
endmacro(WKProject PROJECT_NAME)

#
# Generate a config file for the project.
#
# Automatically called after WkBuild
#

macro ( WkGenConfig )
	#Exporting targets
	export(TARGETS ${PROJECT_NAME} ${${PROJECT_NAME}_source_depends} FILE ${PROJECT_NAME}Export.cmake)
	
	#Generating config file
	file( WRITE ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake "### Config file for ${PROJECT_NAME} auto generated by WkCmake ###

### First section : Main target ###
IF("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" LESS 2.5)
   MESSAGE(FATAL_ERROR "CMake >= 2.6.0 required")
ENDIF("${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}" LESS 2.5)
CMAKE_POLICY(PUSH)
CMAKE_POLICY(VERSION 2.6)
	
get_filename_component(SELF_DIR \"\${CMAKE_CURRENT_LIST_FILE}\" PATH)
#all required target should be defined there... no need to specify all targets in ${PROJECT_NAME}_LIBRARIES, they will be linked automatically
include(\${SELF_DIR}/${PROJECT_NAME}Export.cmake)
get_filename_component(${PROJECT_NAME}_INCLUDE_DIR "\${SELF_DIR}/include/" ABSOLUTE)
set(${PROJECT_NAME}_INCLUDE_DIRS \${${PROJECT_NAME}_INCLUDE_DIR})
	")
	
	file( APPEND ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake "
#however we still want to have ${PROJECT_NAME}_LIBRARIES available
set(${PROJECT_NAME}_LIBRARY ${PROJECT_NAME} )
set(${PROJECT_NAME}_LIBRARIES \${${PROJECT_NAME}_LIBRARY})
	" )
	
	get_target_property(${PROJECT_NAME}_LOCATION ${PROJECT_NAME} LOCATION)
	get_target_property(${PROJECT_NAME}_TYPE ${PROJECT_NAME} TYPE)
	if ( ${${PROJECT_NAME}_TYPE} STREQUAL "SHARED_LIBRARY" OR ${${PROJECT_NAME}_TYPE} STREQUAL "MODULE_LIBRARY")
		file( APPEND ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake "
		
#On windows we need to copy the dlls as running dependencies along with the project's executable(s)
if ( WIN32 )
	get_target_property(${PROJECT_NAME}_LOCATION ${PROJECT_NAME} LOCATION)
	set(${PROJECT_NAME}_RUN_LIBRARIES \${${PROJECT_NAME}_RUN_LIBRARIES} \${${PROJECT_NAME}_LOCATION})
endif ( WIN32)

		")
	endif ( ${${PROJECT_NAME}_TYPE} STREQUAL "SHARED_LIBRARY" OR ${${PROJECT_NAME}_TYPE} STREQUAL "MODULE_LIBRARY")
	
	file( APPEND ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake "
set(${PROJECT_NAME}_FOUND TRUE)
	")	
	
	file( APPEND ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake "
CMAKE_POLICY(POP)")
	
endmacro ( WkGenConfig )


#
# Configure and Build process based on well-known hierarchy
# You need include and src in your hierarchy at least for this to work correctly
# You also need MergeLists.txt 
#

#WkBuild( target_name EXECUTABLE | LIBRARY [ STATIC|SHARED|MODULE ]  )

macro (WkBuild project_type )
CMAKE_POLICY(PUSH)
CMAKE_POLICY(VERSION 2.6)

	if ( ${ARGC} GREATER 1 )
		set(${PROJECT_NAME}_load_type ${ARGV1} )
	endif ( ${ARGC} GREATER 1 )

	message ( STATUS "Configuring ${PROJECT_NAME} as ${project_type} ${${PROJECT_NAME}_load_type}" )	
		
	# testing type
	if (NOT ${project_type} STREQUAL "EXECUTABLE" AND NOT ${project_type} STREQUAL "LIBRARY" )
		message ( FATAL_ERROR " Project type ${project_type} is not valid. Project type can be either EXECUTABLE or LIBRARY")
	endif (NOT ${project_type} STREQUAL "EXECUTABLE" AND NOT ${project_type} STREQUAL "LIBRARY" )
	if ( ${project_type} STREQUAL "LIBRARY" 
					AND NOT ${${PROJECT_NAME}_load_type} STREQUAL "STATIC"
					AND NOT ${${PROJECT_NAME}_load_type} STREQUAL "SHARED"
					AND NOT ${${PROJECT_NAME}_load_type} STREQUAL "MODULE"
		)
		message ( FATAL_ERROR " Project Load type ${${PROJECT_NAME}_load_type} is not valid. Project Load type can be either STATIC, SHARED or MODULE")
	endif  ( ${project_type} STREQUAL "LIBRARY" 
					AND NOT ${${PROJECT_NAME}_load_type} STREQUAL "STATIC"
					AND NOT ${${PROJECT_NAME}_load_type} STREQUAL "SHARED"
					AND NOT ${${PROJECT_NAME}_load_type} STREQUAL "MODULE"
		)
		
	#Verbose Makefile if not release build. Making them internal not to confuse user by appearing with values used only for one project.
	if (${${PROJECT_NAME}_BUILD_TYPE} STREQUAL Release)
		set(CMAKE_VERBOSE_MAKEFILE OFF CACHE INTERNAL "Verbose build commands disabled for Release build." FORCE)
		set(CMAKE_USE_RELATIVE_PATHS OFF CACHE INTERNAL "Absolute paths used in makefiles and projects for Release build." FORCE)
	else (${${PROJECT_NAME}_BUILD_TYPE} STREQUAL Release)
		message( STATUS "Non Release build detected : enabling verbose makefile" )
		# To get the actual commands used
		set(CMAKE_VERBOSE_MAKEFILE ON CACHE INTERNAL "Verbose build commands enabled for Non Release build." FORCE)
				#VLD
		set(CHECK_MEM_LEAKS OFF CACHE BOOL "On to check memory with VLD (must be installed)")
		if(CHECK_MEM_LEAKS)
			add_definitions(-DVLD)
		endif(CHECK_MEM_LEAKS)
	endif (${${PROJECT_NAME}_BUILD_TYPE} STREQUAL Release)

	#Defining target
	
	#VS workaround to display headers
	FILE(GLOB_RECURSE HEADERS RELATIVE ${PROJECT_SOURCE_DIR} include/*.h include/*.hh include/*.hpp)
	FILE(GLOB_RECURSE SOURCES RELATIVE ${PROJECT_SOURCE_DIR} src/*.c src/*.cpp src/*.cc)

	set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/CMake/Modules/")
	FIND_PACKAGE(AStyle)
	IF ( ASTYLE_FOUND )
		option (${PROJECT_NAME}_CODE_FORMAT "Enable Code Formatting" ON)
		IF ( ${PROJECT_NAME}_CODE_FORMAT )
			set(${PROJECT_NAME}_CODE_FORMAT_STYLE "ansi" CACHE STRING "Format Style for AStyle")
		ENDIF ( ${PROJECT_NAME}_CODE_FORMAT )
		WkWhitespaceSplit( HEADERS HEADERS_PARAM )
		WkWhitespaceSplit( SOURCES SOURCES_PARAM )
		#message ( "Sources :  ${HEADERS_PARAM} ${SOURCES_PARAM}" )
		set ( cmdline " ${ASTYLE_EXECUTABLE} --style=${${PROJECT_NAME}_CODE_FORMAT_STYLE} ${HEADERS_PARAM} ${SOURCES_PARAM}" )
		#message ( "CMD : ${cmdline} " )
		ADD_CUSTOM_TARGET(format ALL sh -c ${cmdline} WORKING_DIRECTORY ${PROJECT_SOURCE_DIR} VERBATIM )
	ENDIF ( ASTYLE_FOUND )

	#Including configured headers (
	#	-binary_dir for the configured header,  (useful ? )
	#	-Cmake for Wk headers
	#	-include for the unmodified ones, 
	#	-and in source/src for internal ones)
	include_directories( ${PROJECT_SOURCE_DIR}/CMake ${PROJECT_SOURCE_DIR}/include )
	#internal headers ( non visible by outside project )
	include_directories(${PROJECT_SOURCE_DIR}/src)

	#TODO : find a simpler way than this complex merge...
	MERGE("${HEADERS}" "${SOURCES}" SOURCES)
	#MESSAGE ( STATUS "Sources : ${SOURCES}" )
	
	#
	# Handling my own build config
	#
	
	if(${project_type} STREQUAL "LIBRARY")
		add_library(${PROJECT_NAME} ${${PROJECT_NAME}_load_type} ${SOURCES})
		set( ${PROJECT_NAME}_LIBRARIES ${PROJECT_NAME} CACHE INTERNAL " libraries needed for ${target_name} " )
		if ( ${PROJECT_NAME}_load_type )
		if(${${PROJECT_NAME}_load_type} STREQUAL "SHARED")
			set_target_properties(${PROJECT_NAME} PROPERTIES DEFINE_SYMBOL "WK_SHAREDLIB_BUILD")
			get_target_property(${PROJECT_NAME}_LOCATION ${PROJECT_NAME} LOCATION)
			set( ${PROJECT_NAME}_RUN_LIBRARIES ${${PROJECT_NAME}_LOCATION} CACHE INTERNAL " libraries needed to run ${target_name} " )
		endif(${${PROJECT_NAME}_load_type} STREQUAL "SHARED")
		endif (${PROJECT_NAME}_load_type)		
	elseif (${project_type} STREQUAL "EXECUTABLE")
		add_executable(${PROJECT_NAME} ${SOURCES})
	else (${project_type} STREQUAL "LIBRARY")
		message( FATAL_ERROR " Project Type can only be EXECUTABLE or LIBRARY " )
	endif(${project_type} STREQUAL "LIBRARY")
	
	if( ASTYLE_FOUND )
		add_dependencies(${PROJECT_NAME} format)
	endif( ASTYLE_FOUND )

	#
	# Defining where to put what has been built
	#
	
	SET(${PROJECT_NAME}_LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib CACHE PATH "Ouput directory for ${Project} libraries." )
	mark_as_advanced(FORCE ${PROJECT_NAME}_LIBRARY_OUTPUT_PATH)
	SET(LIBRARY_OUTPUT_PATH "${${PROJECT_NAME}_LIBRARY_OUTPUT_PATH}" CACHE INTERNAL "Internal CMake libraries output directory. Do not edit." FORCE)
	
	SET(${PROJECT_NAME}_EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin CACHE PATH "Ouput directory for ${Project} executables." )
	mark_as_advanced(FORCE ${PROJECT_NAME}_EXECUTABLE_OUTPUT_PATH)
	SET(EXECUTABLE_OUTPUT_PATH "${${PROJECT_NAME}_EXECUTABLE_OUTPUT_PATH}" CACHE INTERNAL "Internal CMake executables output directory. Do not edit." FORCE)

	#
	# Copying include directory if needed after build ( for  use by another project later )
	# for library (and modules ? )
	#
	
	if(${project_type} STREQUAL "LIBRARY") 
		ADD_CUSTOM_COMMAND( TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} ARGS -E copy_directory ${PROJECT_SOURCE_DIR}/include ${PROJECT_BINARY_DIR}/include COMMENT "Copying ${PROJECT_SOURCE_DIR}/include to ${PROJECT_BINARY_DIR}" )
	endif(${project_type} STREQUAL "LIBRARY") 
	

	#
	# Generating configuration cmake file
	#
	
	WkGenConfig( )
		
CMAKE_POLICY(POP)
endmacro (WkBuild)


#
# Find a dependency built in an external WK hierarchy
# Different than for a package because this dependency hasnt been installed yet.
#
# WkBinDepends( dependency_name [QUIET / REQUIRED] )

macro (WkDependsInclude package_name)
CMAKE_POLICY(PUSH)
CMAKE_POLICY(VERSION 2.6)
	
	#
	# First check if the package is installed already , quietly
	#
	
	# if possible by using WkFind modules
	# maybe belongs somewhere else
	set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/CMake/Modules/")
	
	find_package( ${package_name} ${ARGN} )
	SetPackageVarName( package_var_name ${package_name} )
	#message ( "${package_name} -> ${package_var_name}" )

	if ( ${package_var_name}_FOUND )

		# to handle cmake moule who dont have exactly the same standard as WkModules
		if ( NOT ${package_var_name}_INCLUDE_DIRS )
			set ( ${package_var_name}_INCLUDE_DIRS ${${package_var_name}_INCLUDE_DIR})
		endif ( NOT ${package_var_name}_INCLUDE_DIRS )

		add_definitions(-D WK_${package_var_name}_FOUND)

		include_directories(${${package_var_name}_INCLUDE_DIRS})
		message ( STATUS "Binary Dependency ${package_name} include : ${${package_var_name}_INCLUDE_DIRS} OK !")
		
	else ( ${package_var_name}_FOUND )	
		message ( STATUS "Binary Dependency ${package_name} : FAILED ! " )
	endif ( ${package_var_name}_FOUND )
	
CMAKE_POLICY(POP)
endmacro (WkDependsInclude package_name)

macro(WkDependsLink package_name)
CMAKE_POLICY(PUSH)
CMAKE_POLICY(VERSION 2.6)
	
	SetPackageVarName( package_var_name ${package_name} )
	#message ( "${package_name} -> ${package_var_name}" )

	if ( ${package_var_name}_FOUND )

		# to handle cmake moule who dont have exactly the same standard as WkModules
		if ( NOT ${package_var_name}_LIBRARIES )
			set ( ${package_var_name}_LIBRARIES ${${package_var_name}_LIBRARY})
		endif ( NOT ${package_var_name}_LIBRARIES )
		#todo : maybe we need a complete layer over that, Wk Modules handling Wk fetures such as run_libraries and correct variable name...

		target_link_libraries(${PROJECT_NAME} ${${package_var_name}_LIBRARIES})
		message ( STATUS "Binary Dependency ${package_name} libs : ${${package_var_name}_LIBRARIES} OK !")
		#if the find module also defines the runtime libraries ( Wk find module standard  NOT CMAKE itself !)
		set( ${PROJECT_NAME}_RUN_LIBRARIES ${${PROJECT_NAME}_RUN_LIBRARIES} ${${package_var_name}_RUN_LIBRARIES} CACHE INTERNAL " libraries needed to run ${PROJECT_NAME} " )
		IF ( WIN32 )
			message ( STATUS "Binary Dependency ${package_name} runlibs : ${${package_var_name}_RUN_LIBRARIES} OK !")
		ENDIF ( WIN32 )
		#once the project is built with it the dependency becomes mandatory
		# we append to the config cmake script
		file( APPEND ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake "

### External Dependency ${package_name} ###
CMAKE_POLICY(PUSH)
CMAKE_POLICY(VERSION 2.6)
		
find_package( ${package_name} REQUIRED )
if ( ${package_var_name}_FOUND )
	set(${PROJECT_NAME}_INCLUDE_DIRS \${${PROJECT_NAME}_INCLUDE_DIRS} ${${package_var_name}_INCLUDE_DIRS} )
	set(${PROJECT_NAME}_LIBRARIES \${${PROJECT_NAME}_LIBRARIES} ${${package_var_name}_LIBRARIES} )
	set(${PROJECT_NAME}_RUN_LIBRARIES \${${PROJECT_NAME}_RUN_LIBRARIES} ${${package_var_name}_RUN_LIBRARIES} )
endif ( ${package_var_name}_FOUND )
	
CMAKE_POLICY(POP)
	
		")
		
	else ( ${package_var_name}_FOUND )	
		message ( STATUS "Binary Dependency ${package_name} : FAILED ! " )
	endif ( ${package_var_name}_FOUND )
	
CMAKE_POLICY(POP)
endmacro(WkDependsLink package_name)
