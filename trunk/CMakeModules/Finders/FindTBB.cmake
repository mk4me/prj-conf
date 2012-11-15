# przygotowanie do szukania
FIND_INIT(TBB tbb)

# szukanie
if (WIN32)
	FIND_SHARED(TBB_CORE "<lib,?>tbb<_debug,?>" "<lib,?>tbb<_debug,?>")
	FIND_SHARED(TBB_MALLOC "<lib,?>tbbmalloc<_debug,?>" "<lib,?>tbbmalloc<_debug,?>")
	FIND_SHARED(TBB_MALLOC_PROXY "<lib,?>tbbmalloc_proxy<_debug,?>" "<lib,?>tbbmalloc_proxy<_debug,?>")
else()
	FIND_GLOB(TBB_CORE "libtbb.so.*" "libtbb.so.*")
	FIND_GLOB(TBB_MALLOC "libtbbmalloc.so.*" "libtbbmalloc.so.*")
	FIND_GLOB(TBB_MALLOC_PROXY "libtbbmalloc_proxy.so.*" "libtbbmalloc_proxy.so.*")
endif()
# koniec
FIND_FINISH(TBB)

# sprawdzenie
if (TBB_CORE AND
	TBB_MALLOC AND
	TBB_MALLOC_PROXY)
 set(TBB_FOUND 1)

endif()
