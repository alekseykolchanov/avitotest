//
//  AKNetworkServer.h
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface AKNetworkServer : NSObject

+(AKNetworkServer *)share;

-(void)getUsersSinceUserId:(NSNumber*)lastAvailableUserId withCompletion:(void (^) (BOOL isLast, NSArray *usersJsonArray, NSError *error))completion;

-(void)getImageAtUrl:(NSString*)imageUrlString withCompletion:(void (^) (UIImage *image, NSError *error))completion;

@end
