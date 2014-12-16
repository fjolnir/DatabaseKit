#import <DatabaseKit/DBQuery.h>

// Note: currently only implements features supported by SQLite's ALTER command
@interface DBAlterTableQuery : DBWriteQuery <DBTableQuery>
@property(readonly) NSString *nameToRenameTo;
@property(readonly) NSArray *columnsToAppend;

- (instancetype)rename:(NSString *)name;
- (instancetype)appendColumns:(NSArray *)columns;
@end
