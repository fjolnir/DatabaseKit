//
//  ARBaseTest.h
//  ActiveRecord
//
//  Created by Fjölnir Ásgeirsson on 8.8.2007.
//  Copyright 2007 ninja kitten. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <ActiveRecord/ActiveRecord.h>

@class TEAnimal;
@class TEPerson;

@interface TEModel : ARBase {
  
}
@property(readwrite, retain) NSString *name;
@end
@interface TEModel (Accessors)
/*- (NSString *)name;
- (void)setName:(NSString *)name;*/
- (NSString *)info;
- (void)setInfo:(NSString *)info;
- (NSArray *)people;
- (void)setPeople:(NSArray *)people;
- (void)addPerson:(TEPerson *)person;
- (TEAnimal *)animal;
- (void)setAnimal:(TEAnimal *)animal;
- (NSArray *)belgians;
@end

@interface TEPerson : ARBase {
  
}
@end
@interface TEPerson (Accessors)
- (NSString *)realName;
- (NSString *)userName;
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


@interface ARBaseTest : SenTestCase {
}

@end
