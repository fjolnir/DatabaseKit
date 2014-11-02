#import <DatabaseKit/DBConnection.h>

@class DBTable;

@interface DBIndex : NSObject <NSCoding>
@property(nonatomic, readonly) BOOL unique;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSArray *columns;

+ (instancetype)indexWithName:(NSString *)name onColumns:(NSArray *)columns unique:(BOOL)unique;

- (BOOL)addToTable:(DBTable *)table error:(NSError **)outErr;
@end
