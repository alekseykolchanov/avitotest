//
//  AKUpdateModelObject.h
//  AvitoTestTask
//
//  Created by Пользователь on 22.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AKUpdateModelObjectProtocol <NSObject>

@required
-(void)updateWithJSONDictionary:(NSDictionary*)jsonDict;

@optional

@end
