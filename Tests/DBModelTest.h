@import DatabaseKit;

@interface TEModel : DBModel
@property NSString *name, *info;
@end

@class TEAnimal;
@interface TEPerson : DBModel
@property NSString *name;
@property TEAnimal *pet;
@end

@interface TEWebSite : DBModel
@property NSURL *url;
@end

@interface TEAnimal : DBModel
@property NSString *species, *name;
@end
