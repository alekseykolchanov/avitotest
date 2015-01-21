//
//  AKDatabase.m
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "AKDatabase.h"
#import "AKNetworkServer.h"
#import "AKCoreDataController.h"

NSString *const SYNC_ERROR_DOMAIN = @"Sync with local storage error";

@implementation AKDatabase


+(AKDatabase *)share
{
    static dispatch_once_t once;
    static AKDatabase *sharedInst;
    dispatch_once(&once, ^{
        sharedInst = [[self alloc]init];
    });
    
    return sharedInst;
}


-(void)updateUsersSinceUser:(User*)lastAvailableUser withCompletion:(void (^) (BOOL isLastUsers, NSArray *users, NSError *error))completion
{
    NSNumber *lastAvailableUserId;
    
    if (lastAvailableUser)
        lastAvailableUserId = lastAvailableUser.u_id;
    
    [[AKNetworkServer share]getUsersSinceUserId:lastAvailableUserId withCompletion:^(BOOL isLast, NSArray *usersJsonArray, NSError *error) {
        
        if(!error){
            
            NSError *syncError;
            NSArray *resUsers = [self syncRecievedUsers:usersJsonArray error:&syncError];
            
            if (completion)
                completion(isLast,resUsers,syncError);
            
        }else{
            if (completion)
                completion(NO,nil,error);
        }
        
    }];
}

-(void)updateImageForUser:(User*)user withCompletion:(void (^) (UIImage *image, int userId, NSError *error))completion
{
    if (!user || ![user avatar_url])
    {
        if (completion)
            completion(nil,user?[[user u_id]intValue]:0,nil);
    }
    
    int user_id = [user.u_id intValue];
    
    [[AKNetworkServer share]getImageAtUrl:[user avatar_url] withCompletion:^(UIImage *image, NSError *error) {
        if (!error){
            NSError *err;
            [self syncRecievedImage:image forUserWithId:user_id error:&err];
            
            if (completion)
                completion(image,user_id,nil);
            
        }else{
            if (completion)
                completion(nil,user_id,error);
        }
    }];
}

#pragma mark - syncing
-(NSArray*)syncRecievedUsers:(NSArray*)usersJsonArr error:(NSError**)error
{
    if (!usersJsonArr|| [usersJsonArr count]==0)
        return @[];
    
    NSArray *userIds;
    
    @try {
        userIds = [[usersJsonArr valueForKey:@"id"]sortedArrayUsingSelector:@selector(compare:)];
    }
    @catch (NSException *exception) {
        NSString *errorString = @"Error while syncing";
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString};
        *error = [[NSError alloc] initWithDomain:SYNC_ERROR_DOMAIN
                                            code:401
                                        userInfo:userInfoDict];
        return @[];
    }
    
    if (!userIds)
        userIds = @[];
    
    __block NSMutableArray *resArray = [[NSMutableArray alloc]initWithCapacity:[usersJsonArr count]];
    
    NSManagedObjectContext *objContext = [[AKCoreDataController share]backgroundManagedObjectContext];
    
    [objContext performBlockAndWait:^{
        
        
        NSArray *savedUsers = [self getUsersWithIdFrom:[userIds firstObject] toId:[userIds lastObject] inManagedObjectContext:objContext];
        
        NSDictionary *savedUsersDict = [NSDictionary dictionaryWithObjects:savedUsers forKeys:[savedUsers valueForKey:@"u_id"]];
        
        NSDictionary *serverUsersDict = [NSDictionary dictionaryWithObjects:usersJsonArr forKeys:[usersJsonArr valueForKey:@"id"]];
        
        
        
        
        
        [serverUsersDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSDictionary *userJsonDict, BOOL *stop) {
            
            if ([self validateJSONDict:userJsonDict forClassWithName:@"User"]){
                if (savedUsersDict[key]){
                    [(User*)savedUsersDict[key] updateWithJSONDictionary:userJsonDict];
                    [resArray addObject:savedUsersDict[key]];
                }else{
                    User *nUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:objContext];
                    [nUser updateWithJSONDictionary:userJsonDict];
                    [resArray addObject:nUser];
                }
            }
        }];
        
        
        [savedUsersDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, User *user, BOOL *stop) {
            if (!serverUsersDict[key])
                [objContext deleteObject:user];
        }];
        
        
    }];
    
    
    [[AKCoreDataController share]saveBackgroundContext];
    [[AKCoreDataController share]saveMasterContext];
    
    return resArray;
    
}

-(void)syncRecievedImage:(UIImage*)image forUserWithId:(int)user_id error:(NSError**)error
{
    if (user_id==0)
        return;
    
    NSManagedObjectContext *objContext = [[AKCoreDataController share]backgroundManagedObjectContext];
    NSArray *users = [self getUsersWithIdFrom:@(user_id) toId:@(user_id) inManagedObjectContext:objContext];
    
    if (!users || [users count]==0)
        return;
    
    [objContext performBlockAndWait:^{
        User *u = [users firstObject];
        if (image)
        {
            [u setImage_data:UIImageJPEGRepresentation(image, 0.8f)];
        }else{
            if (!u.image_data)
                [u setImage_data:nil];
        }
        
        NSError *saveError;
        
        if ([objContext hasChanges] && ![objContext save:&saveError]){
            NSLog(@"save core data image error");
        }
        
    }];
}

-(BOOL)validateJSONDict:(NSDictionary*)jsonDict forClassWithName:(NSString*)className
{
    if (!jsonDict || ![jsonDict isKindOfClass:[NSDictionary class]])
        return NO;
    
    if ([className isEqualToString:@"User"])
    {
        if (jsonDict[@"id"]&&[jsonDict[@"id"] isKindOfClass:[NSNumber class]]){
            return YES;
        }
    }
    
    return YES;
}

#pragma mark - fetching
-(NSArray*)getUsersWithIdFrom:(NSNumber*)startId toId:(NSNumber*)lastId inManagedObjectContext:(NSManagedObjectContext*)objContext
{
    if (!objContext)
        return nil;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    
    if (startId || lastId){
        if (startId && lastId){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"u_id>=%d AND u_id<=%d",[startId intValue],[lastId intValue]]];
        }else if (startId){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"u_id>=%d",[startId intValue]]];
        }else if (lastId){
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"u_id<=%d",[lastId intValue]]];
        }
    }
    
    __block NSArray *users;
    
    [objContext performBlockAndWait:^{
        NSError *error;
        users =  [objContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    return users;
}


@end
