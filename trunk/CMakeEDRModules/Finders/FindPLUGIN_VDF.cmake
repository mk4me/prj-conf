# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(PLUGIN_VDF vdf ${EDR_INCLUDE_ROOT} ${EDR_BUILD_ROOT})

# szukanie
FIND_SHARED(PLUGIN_VDF "plugin_newVdf" "plugin_newVdf")

# skopiowanie
FIND_FINISH(PLUGIN_VDF)
