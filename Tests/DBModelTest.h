@import DatabaseKit;

@interface TEModel : DBModel
@property NSString *name, *info;
@end

@interface TEPerson : DBModel
@property(weak) NSString *userName, *realName;
@end

@interface TEWebSite : DBModel
@property NSURL *url;
@end

@interface TEAnimal : DBModel
@property NSString *species, *nickname;
@end
