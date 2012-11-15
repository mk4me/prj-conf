# przygotowanie do szukania
FIND_INIT(OPENTHREADS openthreads)
FIND_SHARED(OPENTHREADS_SHARED "OpenThreads" "<ot12-,?>OpenThreads")
FIND_FINISH(OPENTHREADS)

# sprawdzenie
if (OPENTHREADS_SHARED_FOUND)
	set(OPENTHREADS_FOUND 1)
else()
	set(OPENTHREADS_FOUND 0)
endif()
