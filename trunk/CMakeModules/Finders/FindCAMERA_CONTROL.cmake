# przygotowanie do szukania
FIND_INIT_CUSTOM_MODULE(CAMERA_CONTROL "camera/control/CameraControl" ${MIS_INCLUDE_ROOT} ${MIS_BUILD_ROOT})

# szukanie
FIND_STATIC(CAMERA_CONTROL "CameraControl")

# skopiowanie
FIND_FINISH(CAMERA_CONTROL)