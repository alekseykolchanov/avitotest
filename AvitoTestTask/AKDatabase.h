//
//  AKDatabase.h
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "User+AKUser.h"

@interface AKDatabase : NSObject

+(AKDatabase *)share;

-(void)updateUsersSinceUser:(User*)lastAvailableUser withCompletion:(void (^) (BOOL isLastUsers, NSArray *users, NSError *error))completion;

-(void)updateImageForUser:(User*)user withCompletion:(void (^) (UIImage *image, int userId, NSError *error))completion;

@end
