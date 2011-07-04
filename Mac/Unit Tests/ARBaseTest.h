//
//  ARBaseTest.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import <GHUnit/GHUnit.h>
#import <ActiveRecord/ActiveRecord.h>

@class TEAnimal;
@class TEPerson;

@interface TEModel : ARBase {
  
}
@property(readwrite, retain) NSString *name, *info;
@end
@interface TEModel (Accessors)
- (NSArray *)people;
- (void)setPeople:(NSArray *)people;
- (void)addPerson:(TEPerson *)person;
- (TEAnimal *)animal;
- (void)setAnimal:(TEAnimal *)animal;
- (NSArray *)belgians;
@end

@interface TEPerson : ARBase {
  
}
@property(readwrite, assign) NSString *userName, *realName;
@end
@interface TEPerson (Accessors)
- (NSArray *)animals;
- (TEModel *)model;
- (NSArray *)belgians;
@end

@interface TEBelgian : ARBase {
  
}
@end
@interface TEBelgian (Accessors)
- (TEPerson *)person;
@end


@interface TEAnimal : ARBase {
  
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


@interface ARBaseTest : GHTestCase {
}

@end
