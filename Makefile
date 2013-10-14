CC = clang

PREFIX = /usr/local
PRODUCT_NAME = libdatabasekit.so

CFLAGS  = -fblocks -fobjc-nonfragile-abi -fno-constant-cfstrings -I. -Wall -g -O0 -I/usr/local/include -Idependencies -DDEBUG_TRACE -Wno-trigraphs -Wno-shorten-64-to-32

LIB_CFLAGS = -fPIC
LDFLAGS=-L/usr/local/lib -lobjc -lpthread -ldispatch `gnustep-config --base-libs` -lpq

SRC       = DatabaseKit/DB.m \
            DatabaseKit/DBQuery.m \
            DatabaseKit/DBTable.m \
            DatabaseKit/DBModel.m \
            DatabaseKit/DBModel+KeyAndSelectorParsers.m \
            DatabaseKit/Connections/DBConnection.m \
            DatabaseKit/Connections/DBConnectionPool.m \
            DatabaseKit/Connections/DBPostgresConnection.m \
            DatabaseKit/Connections/DBSQLiteConnection.m \
            DatabaseKit/Relationships/DBRelationship.m \
            DatabaseKit/Relationships/DBRelationshipBelongsTo.m \
            DatabaseKit/Relationships/DBRelationshipColumn.m \
            DatabaseKit/Relationships/DBRelationshipHABTM.m \
            DatabaseKit/Relationships/DBRelationshipHasMany.m \
            DatabaseKit/Relationships/DBRelationshipHasManyThrough.m \
            DatabaseKit/Relationships/DBRelationshipHasOne.m \
            DatabaseKit/Utilities/Base64Extensions.m \
            DatabaseKit/Utilities/NSArray+DBAdditions.m \
            DatabaseKit/Utilities/NSString+DBAdditions.m \
            DatabaseKit/Utilities/DBInflector/DBInflector.m

SRC_NOARC = DatabaseKit/DBModel+CustomSelectors.m \
            DatabaseKit/Utilities/ISO8601DateFormatter.m

OBJ       = $(addprefix build/, $(patsubst %.c, %.o, $(SRC:.m=.o)))
OBJ_NOARC = $(addprefix build/, $(patsubst %.c, %.o, $(SRC_NOARC:.m=.o)))

$(OBJ): ARC_CFLAGS := -fobjc-arc

build/%.o: %.m
	@echo "\033[32m * Building $< -> $@\033[0m"
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $(LIB_CFLAGS) $(ARC_CFLAGS) -c $< -o $@

build/%.o: %.c
	@echo "\033[32m * Building $< -> $@\033[0m"
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) $(LIB_CFLAGS) $(ARC_CFLAGS) -c $< -o $@


all: $(OBJ_NOARC) $(OBJ)
	@echo "\033[32m * Linking...\033[0m"
	@$(CC) $(LDFLAGS) $(OBJ) $(OBJ_NOARC) -shared -o build/$(PRODUCT_NAME)

install: all
	@mkdir -p $(PREFIX)/include/DatabaseKit
	@cp DatabaseKit/*.h $(PREFIX)/include/DatabaseKit
	@cp build/$(PRODUCT_NAME) $(PREFIX)/lib/$(PRODUCT_NAME)

clean:
	@rm -rf build
