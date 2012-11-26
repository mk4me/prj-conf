# przygotowanie do szukania
FIND_INIT(SQLITE sqlite3)

# szukanie
FIND_SHARED(SQLITE "sqlite3" "sqlite3")

# skopiowanie
FIND_FINISH(SQLITE)
