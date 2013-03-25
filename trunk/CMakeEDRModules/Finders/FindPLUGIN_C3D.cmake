# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(PLUGIN_C3D vdf ${EDR_INCLUDE_ROOT} ${EDR_BUILD_ROOT})

# szukanie
FIND_SHARED(PLUGIN_C3D "plugin_c3d" "plugin_c3d")

# skopiowanie
FIND_FINISH(PLUGIN_C3D)
