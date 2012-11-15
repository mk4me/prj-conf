# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(ACQUSITION_LIB acqlib ${MIS_INCLUDE_ROOT}/acqlib ${MIS_BUILD_ROOT})

# szukanie
FIND_STATIC(ACQUSITION_LIB "acqlib")

# skopiowanie
FIND_FINISH(ACQUSITION_LIB)