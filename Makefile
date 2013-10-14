CC = clang

PREFIX = /usr/local
PRODUCT_NAME = libdatabasekit.so

CFLAGS  = -fblocks -fobjc-nonfragile-abi -fno-constant-cfstrings -I. -Wall -g -O0 -I/usr/local/include -Idependencies -DDEBUG_TRACE -Wno-trigraphs -Wno-shorten-64-to-32

LIB_CFLAGS = -fPIC
LDFLAGS=-L/usr/local/lib -lobjc -lpthread -ldispatch `gnustep-config --base-libs` -lpq

SRC       = Source/DB.m \
            Source/DBModel.m \
            Source/DBModel+CustomSelectors.m \
            Source/DBModel+KeyAndSelectorParsers.m \
            Source/Connections/DBConnection.m \
            Source/Connections/DBConnectionPool.m \
            Source/Connections/DBPostgresConnection.m \
            Source/Connections/DBSQLiteConnection.m \
            Source/Connections/DBQuery.m \
            Source/Connections/DBTable.m \
            Source/Relationships/DBRelationship.m \
            Source/Relationships/DBRelationshipBelongsTo.m \
            Source/Relationships/DBRelationshipColumn.m \
            Source/Relationships/DBRelationshipHABTM.m \
            Source/Relationships/DBRelationshipHasMany.m \
            Source/Relationships/DBRelationshipHasManyThrough.m \
            Source/Relationships/DBRelationshipHasOne.m \
            Source/Utilities/Base64Extensions.m \
            Source/Utilities/NSArray+DBAdditions.m \
            Source/Utilities/NSString+DBAdditions.m \
            Source/Utilities/DBInflector/DBInflector.m

SRC_NOARC = 

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
