#import "DBConnection.h"
#import "DBUtilities.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>

static NSMutableArray *_ConnectionClasses;

@interface DBConnection ()
@property(readwrite, retain) NSURL *URL;
@end

@implementation DBConnection
+ (BOOL)canHandleURL:(NSURL *)URL
{
    return NO;
}
+ (void)registerConnectionClass:(Class)kls
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _ConnectionClasses = [NSMutableArray array];
    });
    [_ConnectionClasses addObject:kls];
}
+ (id)openConnectionWithURL:(NSURL *)URL error:(NSError **)err
{
    if([URL isKindOfClass:[NSString class]])
        URL = [NSURL URLWithString:(NSString *)URL];
    for(Class kls in _ConnectionClasses) {
        if([kls canHandleURL:URL])
            return [[kls alloc] initWithURL:URL error:err];
    }
    if(err)
        *err = [NSError errorWithDomain:DBConnectionErrorDomain
                                   code:0
                               userInfo:@{ NSLocalizedDescriptionKey: @"Unhandled URL type", @"url": URL }];
    return nil;
}
- (instancetype)initWithURL:(NSURL *)URL error:(NSError **)err
{
    if(!(self = [super init]))
        return nil;
    self.URL = URL;
    return self;
}
- (DBResult *)execute:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    DBNotImplemented();
    return nil;
}
- (BOOL)executeUpdate:(NSString *)sql substitutions:(id)substitutions error:(NSError **)outErr
{
    DBNotImplemented();
    return NO;
}
- (BOOL)closeConnection:(NSError **)outErr
{
    DBNotImplemented();
    return NO;
}

- (NSArray *)tableNames
{
    DBNotImplemented();
    return NO;
}

- (BOOL)tableExists:(NSString *)tableName
{
    DBNotImplemented();
    return NO;
}
- (NSDictionary *)columnsForTable:(NSString *)tableName
{
    DBNotImplemented();
    return nil;
}
- (BOOL)beginTransaction:(NSError **)outErr
{
    DBNotImplemented();
    return NO;
}
- (BOOL)rollBack:(NSError **)outErr
{
    DBNotImplemented();
    return NO;
}
- (BOOL)endTransaction:(NSError **)outErr
{
    DBNotImplemented();
    return NO;
}

- (BOOL)transaction:(DBTransactionBlock)aBlock
{
    @try {
        if(![self beginTransaction:NULL])
            return NO;
        switch(aBlock()) {
            case DBTransactionRollBack:
                [self rollBack:NULL];
                return NO;
            case DBTransactionCommit:
                return [self endTransaction:NULL];
        }
    }
    @catch(NSException *e) {
        [self rollBack:NULL];
        [e raise];
        return NO;
    }
    return YES;
}


#pragma mark -

+ (NSString *)sqlForType:(DBType)type
{
    switch(type) {
        case DBTypeInteger:
            return @"INTEGER";
        case DBTypeReal:
            return @"REAL";
        case DBTypeBoolean:
            return @"BOOL";
        case DBTypeText:
            return @"TEXT";
        case DBTypeBlob:
            return @"BLOB";
        case DBTypeDate:
            return @"DATE";
        case DBTypeUUID:
            return @"UUID_BLOB";
        default:
            return nil;
    }
}

+ (DBType)typeForSql:(NSString *)type
{
    type = [type uppercaseString];
    if([type isEqualToString:@"INTEGER"])
        return DBTypeInteger;
    else if([type isEqualToString:@"REAL"])
        return DBTypeReal;
    else if([type isEqualToString:@"BOOL"])
        return DBTypeBoolean;
    else if([type isEqualToString:@"TEXT"])
        return DBTypeText;
    else if([type isEqualToString:@"BLOB"])
        return DBTypeBlob;
    else
        return DBTypeUnknown;
}

+ (DBType)typeForObjCScalarEncoding:(char)encoding
{
    switch(encoding) {
        case _C_CHR:
        case _C_UCHR:
        case _C_SHT:
        case _C_USHT:
        case _C_INT:
        case _C_UINT:
        case _C_LNG:
        case _C_ULNG:
        case _C_LNG_LNG:
        case _C_ULNG_LNG:
            return DBTypeInteger;
        case _C_FLT:
        case _C_DBL:
            return DBTypeReal;
        case _C_BOOL:
            return DBTypeBoolean;
        default:
            return DBTypeUnknown;
    }
}

+ (DBType)typeForClass:(Class)klass
{
    if([klass isSubclassOfClass:[NSUUID class]])
        return DBTypeUUID;
    if([klass isSubclassOfClass:[NSData class]])
        return DBTypeBlob;
    else if([klass isSubclassOfClass:[NSString class]])
        return DBTypeText;
    else if([klass isSubclassOfClass:[NSNumber class]])
        return DBTypeReal;
    else
        return DBTypeUnknown;
}
@end


@implementation DBResult

- (DBResultState)step:(NSError **)outErr
{
    DBNotImplemented();
    return DBResultStateError;
}

- (NSUInteger)columnCount
{
    DBNotImplemented();
    return 0;
}

- (NSString *)nameOfColumnAtIndex:(NSUInteger)idx
{
    DBNotImplemented();
    return nil;
}
- (NSUInteger)indexOfColumnNamed:(NSString *)name
{
    DBNotImplemented();
    return NSNotFound;
}

- (id)valueOfColumnAtIndex:(NSUInteger)idx
{
    DBNotImplemented();
    return nil;
}

- (id)valueOfColumnNamed:(NSString *)columnName
{
    NSUInteger idx = [self indexOfColumnNamed:columnName];
    if(idx != NSNotFound)
        return [self valueOfColumnAtIndex:idx];
    else
        return nil;
}

- (NSArray *)toArray:(NSError **)outErr
{
    NSMutableArray * const array = [NSMutableArray new];
    while([self step:outErr] == DBResultStateNotAtEnd) {
        [array addObject:[self dictionaryForCurrentRow]];
    }
    return array;
}

- (NSDictionary *)dictionaryForCurrentRow
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:self.columnCount];
    for(NSUInteger i = 0; i < self.columnCount; ++i) {
        dict[[self nameOfColumnAtIndex:i]] = [self valueOfColumnAtIndex:i];
    }
    return dict;
}
- (NSArray *)columns
{
    NSUInteger count = self.columnCount;
    NSMutableArray *columns = [NSMutableArray arrayWithCapacity:count];
    for(NSUInteger i = 0; i < count; ++i) {
        [columns addObject:[self nameOfColumnAtIndex:i]];
    }
    return columns;
}

@end
