#import <DatabaseKit/DatabaseKit.h>

// Note: currently only implements features supported by SQLite's ALTER command
@interface DBAlterQuery : DBWriteQuery <DBTableQuery>
@property(nonatomic, readonly) NSString *nameToRenameTo;
@property(nonatomic, readonly) NSArray *columnsToAppend;

- (instancetype)rename:(NSString *)name;
- (instancetype)appendColumns:(NSArray *)columns;
@end
