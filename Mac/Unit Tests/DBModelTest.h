//
//  DBModelTest.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <DatabaseKit/DatabaseKit.h>

@class TEAnimal;
@class TEPerson;
@class DB;

@interface TEModel : DBModel
@property(readwrite, strong) NSString *name, *info;
@property(nonatomic, strong) NSArray *belgians, *people;
@property(nonatomic, strong) TEAnimal *animal;

@end

@interface TEPerson : DBModel
@property(readwrite, weak) NSString *userName, *realName;
@property(nonatomic, strong) NSArray *animals, *belgians;

@end

@interface TEBelgian : DBModel
@end


@interface TEAnimal : DBModel
@property(nonatomic, strong) NSString *species, *nickname;
@property(nonatomic, strong) NSArray *people;
@property(nonatomic, strong) TEModel *model;
@end

