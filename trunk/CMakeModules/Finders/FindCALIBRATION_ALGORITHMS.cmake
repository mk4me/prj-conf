# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(CALIBRATION_ALGORITHMS calibrationAlgorithms ${MIS_INCLUDE_ROOT} ${MIS_BUILD_ROOT})

# szukanie
FIND_STATIC(CALIBRATION_ALGORITHMS "calibrationAlgorithms")

# skopiowanie
FIND_FINISH(CALIBRATION_ALGORITHMS)