//
//  User.h
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * login;
@property (nonatomic, retain) NSNumber * u_id;
@property (nonatomic, retain) NSString * avatar_url;
@property (nonatomic, retain) NSData * image_data;

@end
