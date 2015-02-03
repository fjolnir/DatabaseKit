@import DatabaseKit;

@interface TEModel : DBModel
@property NSString *name, *info;
@end

@interface TEWebSite : DBModel
@property NSURL *url;
@end

@DBRelatable(TEAnimal) : DBModel
@property NSString *species, *name;
@end

@interface TEPerson : DBModel
@property NSString *name;
@property TEAnimal *pet;

@property NSSet<TEAnimal> *pets;
@end
