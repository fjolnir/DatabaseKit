#import <Foundation/Foundation.h>

@class DBTable;

@interface DBIndex : NSObject <NSCoding>
@property(readonly) BOOL unique;
@property(readonly) NSString *name;
@property(readonly) NSArray *columns;

+ (instancetype)indexWithName:(NSString *)name onColumns:(NSArray *)columns unique:(BOOL)unique;

- (BOOL)addToTable:(DBTable *)table error:(NSError **)outErr;
@end
