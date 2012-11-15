# przygotowanie do szukania
FIND_INIT(CORE core)
FIND_INCLUDE_PLATFORM_HEADERS(CORE core)

set(CORE_FOUND 1)
list( APPEND FIND_RESULTS CORE)
# skopiowanie
FIND_FINISH(CORE)