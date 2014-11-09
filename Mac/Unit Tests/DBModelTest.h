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

@interface TECar : DBRelationalModel
@property(nonatomic, strong) NSString *brandName;
@property(nonatomic) NSUInteger yearBuilt;
@property(nonatomic, copy) NSSet *doors;
@end

@interface TECarChanged : DBRelationalModel
@property(nonatomic, strong) NSString *color;
@property(nonatomic) NSUInteger yearBuilt;
@property(nonatomic, copy) NSSet *doors;
@end

typedef NS_ENUM(NSUInteger, TEDoorSide) {
    TELeft,
    TERight
};
@interface TEDoor : DBRelationalModel
@property(nonatomic) TECar *car;
@property(nonatomic) TEDoorSide side;
@end