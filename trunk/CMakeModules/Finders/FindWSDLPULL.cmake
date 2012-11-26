# przygotowanie do szukania
FIND_INIT(WSDLPULL wsdlpull)

# szukanie
FIND_SHARED(WSDLPULL "wsdlpull" "wsdlpull")

# skopiowanie
FIND_FINISH(WSDLPULL)

if(WSDLPULL_FOUND)
	if(WIN32)
		FIND_DEPENDENCIES(WSDLPULL WSDLPULL_FOUND "CURL")
	elseif(UNIX)
		FIND_PREREQUISITES(WSDLPULL WSDLPULL_FOUND "CURL")
	endif()
endif()