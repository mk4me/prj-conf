# przygotowanie do szukania
set(FIND_DISABLE_INCLUDES ON)
FIND_INIT(BTK btk)

FIND_SHARED_EXT(BTK_IO "BTKIO" "BTKIO" "BTKIO" "BTKIO")
FIND_SHARED_EXT(BTK_Common "BTKCommon" "BTKCommon" "BTKCommon" "BTKCommon")
FIND_SHARED_EXT(BTK_Filters "BTKBasicFilters" "BTKBasicFilters" "BTKBasicFilters" "BTKBasicFilters")

# koniec
FIND_FINISH(BTK)

if (BTK_IO_FOUND AND BTK_Common_FOUND AND BTK_Filters_FOUND)

	# szukanie
	set(BTK_Config_DIR "${FIND_LIBRARIES_INCLUDE_ROOT}/btk/" CACHE PATH "Location of BTK config headers.")
	set(BTK_IO_INCLUDE_DIR "${BTK_Config_DIR}/IO" CACHE PATH "Location of BTK IO headers.")
	set(BTK_Common_INCLUDE_DIR "${BTK_Config_DIR}/Common" CACHE PATH "Location of BTK Common headers.")
	set(BTK_Filters_INCLUDE_DIR "${BTK_Config_DIR}/BasicFilters" CACHE PATH "Location of BTK Filters headers.")
	# set(BTK_Utilities_INCLUDE_DIR "${BTK_Config_DIR}/Utilities" CACHE PATH "Location of BTK Utilities headers.")
	

	set(BTK_INCLUDE_DIR 
		#"${BTK_IO_INCLUDE_DIR};${BTK_Common_INCLUDE_DIR};${BTK_Filters_INCLUDE_DIR};${BTK_Utilities_INCLUDE_DIR};${BTK_Config_DIR}"
		"${BTK_IO_INCLUDE_DIR};${BTK_Common_INCLUDE_DIR};${BTK_Filters_INCLUDE_DIR};${BTK_Config_DIR}"
		CACHE PATH "Location of BTK include headers.")

	if (NOT EIGEN3_FOUND)
		message("BTK jest zale¿ne od Eigen3, biblioteka ta nie zosta³a jednak znaleziona.")
		set(BTK_FOUND 0)
	else()
		set(BTK_FOUND 1)
	endif()
	
	LIST(APPEND BTK_INCLUDE_DIR "${EIGEN3_INCLUDE_DIR}")
	set(BTK_COMPILER_DEFINITIONS EIGEN2_SUPPORT)
else()
	set(BTK_FOUND 0)
endif()
