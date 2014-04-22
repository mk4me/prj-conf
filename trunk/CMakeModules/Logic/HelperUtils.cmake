###############################################################################

# Makro pomocne do definiowania różnych gałęzi logowania

macro(INIT_VERBOSE_OPTION_EXT name comment defaultValue)

	CONFIG_OPTION(${name}_VERBOSE "${comment}" ${defaultValue})

endmacro(INIT_VERBOSE_OPTION_EXT)

###############################################################################

# Makro pomocne do definiowania różnych gałęzi logowania

macro(INIT_VERBOSE_OPTION name comment)

	INIT_VERBOSE_OPTION_EXT("${name}" "${comment}" OFF)

endmacro(INIT_VERBOSE_OPTION)