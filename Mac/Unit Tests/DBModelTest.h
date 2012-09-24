//
//  DBModelTest.h
//  DatabaseKit
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 Fjölnir Ásgeirsson. All rights reserved.
//

#import <GHUnit/GHUnit.h>
#import <DatabaseKit/DatabaseKit.h>

@class TEAnimal;
@class TEPerson;

@interface TEModel : DBModel {
  
}
@property(readwrite, strong) NSString *name, *info;
@end
@interface TEModel (Accessors)
- (NSArray *)people;
- (void)setPeople:(NSArray *)people;
- (void)addPerson:(TEPerson *)person;
- (TEAnimal *)animal;
- (void)setAnimal:(TEAnimal *)animal;
- (NSArray *)belgians;
@end

@interface TEPerson : DBModel {
  
}
@property(readwrite, weak) NSString *userName, *realName;
@end
@interface TEPerson (Accessors)
- (NSArray *)animals;
- (TEModel *)model;
- (NSArray *)belgians;
@end

@interface TEBelgian : DBModel {
  
}
@end
@interface TEBelgian (Accessors)
- (TEPerson *)person;
@end


@interface TEAnimal : DBModel {
  
}
@end
@interface TEAnimal (Accessors)
- (NSString *)species;
- (NSString *)nickname;
- (TEModel *)model;
- (void)setModel:(TEModel *)animal;
- (NSArray *)people;
- (void)addPerson:(TEPerson *)person;
@end


@interface DBModelTest : GHTestCase {
}

@end
