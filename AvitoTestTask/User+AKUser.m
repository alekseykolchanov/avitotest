//
//  User+AKUser.m
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "User+AKUser.h"

@implementation User (AKUser)


-(void)updateWithJSONDictionary:(NSDictionary*)jsonDict
{
    if (!jsonDict)
        return;
    
    if (jsonDict[@"id"] && [jsonDict[@"id"] isKindOfClass:[NSNumber class]])
    {
        if (!self.u_id || [self.u_id compare:jsonDict[@"id"]]!=NSOrderedSame)
        {
            self.u_id = jsonDict[@"id"];
        }
    }else if (jsonDict[@"id"]&&[jsonDict[@"id"]isKindOfClass:[NSNull class]]){
        if (self.u_id)
            self.u_id= nil;
    }
    
    if (jsonDict[@"login"] && [jsonDict[@"login"] isKindOfClass:[NSString class]])
    {
        if (!self.login || [self.login compare:jsonDict[@"login"]]!=NSOrderedSame)
        {
            self.login = jsonDict[@"login"];
        }
    }else if (jsonDict[@"login"]&&[jsonDict[@"login"]isKindOfClass:[NSNull class]]){
        if (self.login)
            self.login= nil;
    }
    
    if (jsonDict[@"avatar_url"] && [jsonDict[@"avatar_url"] isKindOfClass:[NSString class]])
    {
        if (!self.avatar_url || [self.avatar_url compare:jsonDict[@"avatar_url"]]!=NSOrderedSame)
        {
            self.avatar_url = jsonDict[@"avatar_url"];
        }
    }else if (jsonDict[@"avatar_url"]&&[jsonDict[@"avatar_url"]isKindOfClass:[NSNull class]]){
        if (self.avatar_url)
            self.avatar_url= nil;
    }
    
    
}


@end
