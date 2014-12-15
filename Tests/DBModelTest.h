#import <DatabaseKit/DatabaseKit.h>

@interface TEModel : DBModel
@property(readwrite, strong) NSString *name, *info;
@end

@interface TEPerson : DBModel
@property(readwrite, weak) NSString *userName, *realName;
@end

@interface TEWebSite : DBModel
@property(readwrite, strong) NSURL *url;
@end

@interface TEAnimal : DBModel
@property(nonatomic, strong) NSString *species, *nickname;
@end
