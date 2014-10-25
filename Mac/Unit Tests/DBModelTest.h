//
//  DBModelTest.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <DatabaseKit/DatabaseKit.h>

@interface TEModel : DBModel
@property(readwrite, strong) NSString *name, *info;

@end

@interface TEPerson : DBModel
@property(readwrite, weak) NSString *userName, *realName;
@end

@interface TEBelgian : DBModel
@end


@interface TEAnimal : DBModel
@property(nonatomic, strong) NSString *species, *nickname;
@end

@interface TECar : DBModel
@property(nonatomic, copy) NSSet *doors;
@end

@interface TEDoor : DBModel
@end