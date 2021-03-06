## -*- mode:cmake; coding:utf-8; -*-
# Copyright (c) 2012 Thomas Ludwig <moonmaker@gmx.de>
# Based on UploadPPA.cmake from Daniel Pfeifer <daniel@pfeifer-mail.de>
# and Rüdiger Sonderfeld <ruediger@c-plusplus.de>
#
# CreateDEB.cmake is free software and is based on UploadPPA.cmake. 
# It comes without any warranty, to the extent permitted by applicable law. 
# You can redistribute it and/or modify it under the terms of the Do 
# What The Fuck You Want To Public License, Version 2, as published by 
# Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING for more details.
#
##
# Documentation
#
# This CMake module uploads a project to a PPA.  It creates all the files
# necessary (similar to CPack) to create the
# package and upload it to a PPA.  A PPA is a Personal Package Archive and can
# be used by Debian/Ubuntu or other apt/deb based distributions to install and
# update packages from a remote repository.
# Canonicals Launchpad (http://launchpad.net) is usually used to host PPAs.
# See https://help.launchpad.net/Packaging/PPA for further information
# about PPAs.
#
# CreateDEB.cmake uses similar settings to CPack and the CPack DEB Generator.
# Additionally the following variables are used
#
# CPACK_DEBIAN_PACKAGE_BUILD_DEPENDS to specify build dependencies
# (cmake is added as default)
# CPACK_DEBIAN_RESOURCE_FILE_CHANGELOG should point to a file containing the
# changelog in debian format.  If not set it checks whether a file
# debian/changelog exists in the source directory or creates a simply changelog
# file.
# CPACK_DEBIAN_UPDATE_CHANGELOG if set to True then UploadPPA.cmake adds a new
# entry to the changelog with the current version number and distribution name
# (lsb_release -c is used).  This can be useful because debuild uses the latest
# version number from the changelog and the version number set in
# CPACK_PACKAGE_VERSION.  If they mismatch the creation of the package fails.
#
##

# Strip "-dirty" flag from package version.
# It can be added by, e.g., git describe but it causes trouble with debuild etc.
string(REPLACE "-dirty" "" CPACK_PACKAGE_VERSION ${CPACK_PACKAGE_VERSION})

# Important - Debian Source Dir!
set(DEBIAN_SOURCE_DIR "${CMAKE_SOURCE_DIR}/debian")
set(DEBIAN_TPL_DIR "${CPACK_DEBIAN_INSTALLER_DIR}/tpls/")
set(debian_rules ${DEBIAN_SOURCE_DIR}/rules)

# Variables from extern
# CPACK_PACKAGE_LICENSE
# BUILD_TYPE

# DEBIAN/control
# debian policy enforce lower case for package name
# Package: (mandatory)
IF(NOT CPACK_DEBIAN_PACKAGE_NAME)
  STRING(TOLOWER "${CPACK_PACKAGE_NAME}" CPACK_DEBIAN_PACKAGE_NAME)
ENDIF(NOT CPACK_DEBIAN_PACKAGE_NAME)

# Section: (recommended)
IF(NOT CPACK_DEBIAN_PACKAGE_SECTION)
  SET(CPACK_DEBIAN_PACKAGE_SECTION "devel")
ENDIF(NOT CPACK_DEBIAN_PACKAGE_SECTION)

# Priority: (recommended)
IF(NOT CPACK_DEBIAN_PACKAGE_PRIORITY)
  SET(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
ENDIF(NOT CPACK_DEBIAN_PACKAGE_PRIORITY)

if(NOT CPACK_DEBIAN_PACKAGE_MAINTAINER)
  set(CPACK_DEBIAN_PACKAGE_MAINTAINER ${CPACK_PACKAGE_CONTACT})
endif()

if(NOT CPACK_PACKAGE_DESCRIPTION AND EXISTS ${CPACK_PACKAGE_DESCRIPTION_FILE})
  file(STRINGS ${CPACK_PACKAGE_DESCRIPTION_FILE} DESC_LINES)
  foreach(LINE ${DESC_LINES})
    set(deb_long_description "${deb_long_description} ${LINE}\n")
  endforeach(LINE ${DESC_LINES})
else()
  set(deb_long_description " ${CPACK_PACKAGE_DESCRIPTION}")
endif()

# VCS - SVN, GIT, BRZ and Browser
if (CPACK_PACKAGE_SOURCE_Vcs_SVN)
	set (deb_VCS_SVN "Vcs-Svn: ${CPACK_PACKAGE_SOURCE_Vcs_SVN}\n")
endif()
if (CPACK_PACKAGE_SOURCE_Vcs_BZR)
	set (deb_VCS_BRZ "Vcs-Bzr: ${CPACK_PACKAGE_SOURCE_Vcs_BZR}\n")
endif()
if (CPACK_PACKAGE_SOURCE_Vcs_GIT)
	set (deb_VCS_GIT "Vcs-Git: ${CPACK_PACKAGE_SOURCE_Vcs_GIT}\n")
endif()
if (CPACK_PACKAGE_SOURCE_Vcs_BROWSER)
	set (deb_VCS_BROWSER "Vcs-Browser: ${CPACK_PACKAGE_SOURCE_Vcs_BROWSER}\n")
endif()
set (deb_VCS "${deb_VCS_SVN}${deb_VCS_BZR}${deb_VCS_GIT}${deb_VCS_BROWSER}")


##############################################################################
# debian/control
set(debian_control ${DEBIAN_SOURCE_DIR}/control)
list(SORT CPACK_DEBIAN_PACKAGE_BUILD_DEPENDS)
string(REPLACE ";" ", " build_depends "${CPACK_DEBIAN_PACKAGE_BUILD_DEPENDS}")
file(WRITE ${debian_control}
  "Source: ${CPACK_DEBIAN_PACKAGE_NAME}\n"
  "Section: ${CPACK_DEBIAN_PACKAGE_SECTION}\n"
  "Priority: ${CPACK_DEBIAN_PACKAGE_PRIORITY}\n"
  "Maintainer: ${CPACK_DEBIAN_PACKAGE_MAINTAINER}\n"
  "Build-Depends: ${build_depends}\n"
  "Standards-Version: 3.9.2\n"
  "DM-Upload-Allowed: yes\n"
  "Homepage: ${CPACK_DEBIAN_PACKAGE_HOMEPAGE}\n"
  "${deb_VCS}\n"
  "Package: ${CPACK_DEBIAN_PACKAGE_NAME}\n"
  "Depends: ${CPACK_DEBIAN_PACKAGE_DEPENDS}\n"
  "Priority: ${CPACK_DEBIAN_PACKAGE_PRIORITY}\n"
  "Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}\n"
  "Homepage: ${CPACK_DEBIAN_PACKAGE_HOMEPAGE}\n"
  "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}\n"
  "${deb_long_description}"
  )

foreach(COMPONENT ${CPACK_COMPONENTS_ALL})
  string(TOUPPER ${COMPONENT} UPPER_COMPONENT)
  set(DEPENDS "${CPACK_DEBIAN_PACKAGE_NAME}")
  foreach(DEP ${CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS})
    set(DEPENDS "${DEPENDS}, ${CPACK_DEBIAN_PACKAGE_NAME}-${DEP}")
  endforeach(DEP ${CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS})
  file(APPEND ${debian_control} "\n"
    "Package: ${CPACK_DEBIAN_PACKAGE_NAME}-${COMPONENT}\n"
    "Architecture: ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}\n"
    "Depends: ${DEPENDS}\n"
    "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}"
    ": ${CPACK_COMPONENT_${UPPER_COMPONENT}_DISPLAY_NAME}\n"
    "${deb_long_description}"
    " .\n"
    " ${CPACK_COMPONENT_${UPPER_COMPONENT}_DESCRIPTION}\n"
    )
endforeach(COMPONENT ${CPACK_COMPONENTS_ALL})

##############################################################################
# debian/copyright
set(debian_copyright ${DEBIAN_SOURCE_DIR}/copyright)
configure_file(${CPACK_RESOURCE_FILE_LICENSE} ${debian_copyright} COPYONLY)

##############################################################################
# debian/rules
file(READ "${DEBIAN_TPL_DIR}/rules.ex" FILE_RULES)
message (${BUILD_TYPE})
STRING(REPLACE "CREATEDEB_BUILD_TYPE" ${BUILD_TYPE} FILE_RULES ${FILE_RULES})
file(WRITE "${debian_rules}" "${FILE_RULES}")


#file(WRITE 
#  "#!/usr/bin/make -f\n"
#  "\n"
#  "DEBUG = debug_build\n"
#  "RELEASE = release_build\n"
#  "CFLAGS =\n"
#  "CPPFLAGS =\n"
#  "CXXFLAGS =\n"
#  "FFLAGS =\n"
#  "LDFLAGS =\n"
#  "\n"
#  "configure-debug:\n"
#  "\tcmake -E make_directory $(DEBUG)\n"
#  "\tcd $(DEBUG); cmake -DCMAKE_BUILD_TYPE=Debug ..\n"
#  "\ttouch configure-debug\n"
#  "\n"
#  "configure-release:\n"
#  "\tcmake -E make_directory $(RELEASE)\n"
#  "\tcd $(RELEASE); cmake -DCMAKE_BUILD_TYPE=Release ..\n"
#  "\ttouch configure-release\n"
#  "\n"
#  "build: build-arch\n" # build-indep
#  "\n"
#  "build-arch: configure-release\n" # configure-debug
#  "\t$(MAKE) --no-print-directory -C $(RELEASE) preinstall\n"
#  "\ttouch build-arch\n"
#  "\n"
#  "build-indep: configure-release\n"
#  "\t$(MAKE) --no-print-directory -C $(RELEASE) documentation\n"
#  "\ttouch build-indep\n"
#  "\n"
#  "binary: binary-arch binary-indep\n"
#  "\n"
#  "binary-arch: build-arch\n"
#  "\tcd $(DEBUG); cmake -DCOMPONENT=Unspecified -DCMAKE_INSTALL_PREFIX=../debian/tmp/usr -P cmake_install.cmake\n"
#  "\tcd ${BUILD_TYPE}; cmake -DCOMPONENT=Unspecified -DCMAKE_INSTALL_PREFIX=../debian/tmp/usr -P cmake_install.cmake\n"
#  "\tcmake -E make_directory debian/tmp/DEBIAN\n"
#  "\tdpkg-gencontrol -p${CPACK_DEBIAN_PACKAGE_NAME} -Pdebian/tmp\n"
#  "\tdpkg --build debian/tmp ..\n"
#  )

#foreach(component ${CPACK_COMPONENTS_ALL})
#  string(TOUPPER "${component}" COMPONENT)
#  if(NOT CPACK_COMPONENT_${COMPONENT}_BINARY_INDEP)
#    set(path debian/${component})
#    file(APPEND ${debian_rules}
#      "\tcd ${BUILD_TYPE}; cmake -DCOMPONENT=${component} -DCMAKE_INSTALL_PREFIX=../${path}/usr -P cmake_install.cmake\n"
#      "\tcmake -E make_directory ${path}/DEBIAN\n"
#      "\tdpkg-gencontrol -p${CPACK_COMPONENT_${COMPONENT}_DEB_PACKAGE} -P${path}\n"
#      "\tdpkg --build ${path} ..\n"
#      )
#  endif(NOT CPACK_COMPONENT_${COMPONENT}_BINARY_INDEP)
#endforeach(component)

#file(APPEND ${debian_rules}
#  "\n"
#  "binary-indep: build-indep\n"
#  )

#foreach(component ${CPACK_COMPONENTS_ALL})
#  string(TOUPPER "${component}" COMPONENT)
#  if(CPACK_COMPONENT_${COMPONENT}_BINARY_INDEP)
#    set(path debian/${component})
#    file(APPEND ${debian_rules}
#      "\tcd $(RELEASE); cmake -DCOMPONENT=${component} -DCMAKE_INSTALL_PREFIX=../${path}/usr -P cmake_install.cmake\n"
#      "\tcmake -E make_directory ${path}/DEBIAN\n"
#      "\tdpkg-gencontrol -p${CPACK_COMPONENT_${COMPONENT}_DEB_PACKAGE} -P${path}\n"
#      "\tdpkg --build ${path} ..\n"
#      )
#  endif(CPACK_COMPONENT_${COMPONENT}_BINARY_INDEP)
#endforeach(component)

#file(APPEND ${debian_rules}
#  "\n"
#  "clean:\n"
#  "\tcmake -E remove_directory $(DEBUG)\n"
#  "\tcmake -E remove_directory $(RELEASE)\n"
#  "\tcmake -E remove configure-debug configure-release build-arch build-indep\n"
#  "\n"
#  ".PHONY: binary binary-arch binary-indep clean\n"
#  )
execute_process(COMMAND chmod +x ${debian_rules})

##############################################################################
# New variables DATE_TIME and DISTRI
execute_process(
	COMMAND date -R
		OUTPUT_VARIABLE DATE_TIME
		OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
	COMMAND date +%Y
		OUTPUT_VARIABLE DATE_YEAR
		OUTPUT_STRIP_TRAILING_WHITESPACE
)
execute_process(
	COMMAND lsb_release -cs
		OUTPUT_VARIABLE DISTRI
		OUTPUT_STRIP_TRAILING_WHITESPACE
)


##############################################################################
# debian/copyright
file(READ "${DEBIAN_TPL_DIR}/copyright_${CPACK_PACKAGE_LICENSE}.ex" FILE_COPYRIGHT)
STRING(REPLACE "CPACK_DEBIAN_PACKAGE_MAINTAINER" ${CPACK_DEBIAN_PACKAGE_MAINTAINER} FILE_COPYRIGHT ${FILE_COPYRIGHT})
STRING(REPLACE "CPACK_DEBIAN_PACKAGE_UPSTREAM_AUTHORS" ${CPACK_DEBIAN_PACKAGE_MAINTAINER} FILE_COPYRIGHT "${FILE_COPYRIGHT}")
STRING(REPLACE "CPACK_DEBIAN_PACKAGE_DOWNLOADEDFROM" ${CPACK_PACKAGE_SOURCE_DOWNLOADFROM} FILE_COPYRIGHT "${FILE_COPYRIGHT}")
STRING(REPLACE "CPACK_DEBIAN_PACKAGE_DATEYEAR" ${DATE_YEAR} FILE_COPYRIGHT "${FILE_COPYRIGHT}")
file(WRITE "${DEBIAN_SOURCE_DIR}/copyright" "${FILE_COPYRIGHT}")

##############################################################################
# debian/compat
file(WRITE ${DEBIAN_SOURCE_DIR}/compat "7")

##############################################################################
# debian/source/format
file(WRITE ${DEBIAN_SOURCE_DIR}/source/format "3.0 (native)")

##############################################################################
# debian/docs
file(WRITE ${DEBIAN_SOURCE_DIR}/docs "README")

##############################################################################
# debian/README.source
file(WRITE ${DEBIAN_SOURCE_DIR}/README.source 
	"${PROJECT_NAME} for Debian\n"
	"--------------------\n"
	"\n"
	"<this file describes information about the source package, see Debian policy\n"
	"manual section 4.14. You WILL either need to modify or delete this file>"
)

##############################################################################
# debian/README.Debian
file(WRITE ${DEBIAN_SOURCE_DIR}/README.Debian 
	"${PROJECT_NAME} for Debian\n"
	"--------------------\n"
	"\n"
	"<possible notes regarding this package - if none, delete this file>\n"
	"\n"
	" -- ${CPACK_DEBIAN_PACKAGE_MAINTAINER}  ${DATE_TIME}\n"
)

##############################################################################
# debian/changelog
set(debian_changelog ${DEBIAN_SOURCE_DIR}/changelog)
#if(NOT CPACK_DEBIAN_RESOURCE_FILE_CHANGELOG)
  set(CPACK_DEBIAN_RESOURCE_FILE_CHANGELOG ${CMAKE_SOURCE_DIR}/debian/changelog)
#endif()

#if(EXISTS ${CPACK_DEBIAN_RESOURCE_FILE_CHANGELOG})
#  configure_file(${CPACK_DEBIAN_RESOURCE_FILE_CHANGELOG} ${debian_changelog} COPYONLY)

#  if(CPACK_DEBIAN_UPDATE_CHANGELOG)
#    file(READ ${debian_changelog} debian_changelog_content)
#    execute_process(
#      COMMAND date -R
#      OUTPUT_VARIABLE DATE_TIME
#      OUTPUT_STRIP_TRAILING_WHITESPACE)
#    execute_process(
#      COMMAND lsb_release -cs
#      OUTPUT_VARIABLE DISTRI
#      OUTPUT_STRIP_TRAILING_WHITESPACE)
#    file(WRITE ${debian_changelog}
#      "${CPACK_DEBIAN_PACKAGE_NAME} (${CPACK_PACKAGE_VERSION}) ${DISTRI}; urgency=low\n\n"
#      "  * Package created with CMake\n\n"
#      " -- ${CPACK_DEBIAN_PACKAGE_MAINTAINER}  ${DATE_TIME}\n"
#      )
#    file(APPEND ${debian_changelog} ${debian_changelog_content})
#  endif()

#else()
  file(WRITE ${debian_changelog}
    "${CPACK_DEBIAN_PACKAGE_NAME} (${CPACK_PACKAGE_VERSION}) ${DISTRI}; urgency=low\n\n"
    "  * Package built with CMake\n\n"
    " -- ${CPACK_DEBIAN_PACKAGE_MAINTAINER}  ${DATE_TIME}\n"
    )
#endif()

##########################################################################
# .orig.tar.gz
#execute_process(COMMAND date +%y%m%d
#  OUTPUT_VARIABLE day_suffix
#  OUTPUT_STRIP_TRAILING_WHITESPACE
#  )

set(package_file_name "${CPACK_DEBIAN_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}")

#file(WRITE "${DEBIAN_SOURCE_DIR}/cpack.cmake"
#  "set(CPACK_GENERATOR TBZ2)\n"
#  "set(CPACK_PACKAGE_NAME \"${CPACK_DEBIAN_PACKAGE_NAME}\")\n"
#  "set(CPACK_PACKAGE_VERSION \"${CPACK_PACKAGE_VERSION}\")\n"
#  "set(CPACK_PACKAGE_FILE_NAME \"${package_file_name}.orig\")\n"
#  "set(CPACK_PACKAGE_DESCRIPTION \"${CPACK_PACKAGE_NAME} Source\")\n"
#  "set(CPACK_IGNORE_FILES \"${CPACK_SOURCE_IGNORE_FILES}\")\n"
#  "set(CPACK_INSTALLED_DIRECTORIES \"${CPACK_SOURCE_INSTALLED_DIRECTORIES}\")\n"
#  )

#set(orig_file "${DEBIAN_SOURCE_DIR}/${package_file_name}.orig.tar.bz2")
#add_custom_command(OUTPUT "${orig_file}"
#  COMMAND cpack --config ./cpack.cmake
#  WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/Debian"
#  )

##############################################################################
# debuild -S
set( DEB_SOURCE_CHANGES "${CPACK_DEBIAN_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_source.changes" )

#add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/debian/${DEB_SOURCE_CHANGES}
#  COMMAND ${DEBUILD_EXECUTABLE} -S
#  WORKING_DIRECTORY ${DEBIAN_SOURCE_DIR}
#  DEPENDS "${orig_file}"
#)

