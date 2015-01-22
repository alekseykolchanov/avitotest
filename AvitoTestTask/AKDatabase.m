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

-(void)getImageForUser:(User*)user withCompletion:(void (^) (UIImage *image, int userId, NSError *error))completion
{
    if (!user || ![user avatar_url])
    {
        if (completion)
            completion(nil,user?[[user u_id]intValue]:0,nil);
        
        return;
    }
    
    int user_id = [user.u_id intValue];
    
    Image *savedImg = [self fetchImageWithUrl:user.avatar_url inManagedObjectContext:[[AKCoreDataController share]backgroundManagedObjectContext]];
    
    if (savedImg && [savedImg image_data])
    {
        if (completion)
            completion([UIImage imageWithData:[savedImg image_data]],user_id,nil);
        
        return;
    }
    
    NSString *image_url = [[user avatar_url]copy];
    
    [[AKNetworkServer share]getImageAtUrl:[user avatar_url] withCompletion:^(UIImage *image, NSError *error) {
        if (!error){
            NSError *err;
            [self syncRecievedImage:image forImageUrl:image_url error:&err];
            
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
        if (error != NULL)
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
        
        
        NSArray *savedUsers = [self fetchUsersWithIdFrom:[userIds firstObject] toId:[userIds lastObject] inManagedObjectContext:objContext];
        
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

-(UIImage*)syncRecievedImage:(UIImage*)image forImageUrl:(NSString *)urlString error:(NSError**)error
{
    if (!urlString || !image)
        return image;
    
    NSManagedObjectContext *objContext = [[AKCoreDataController share]backgroundManagedObjectContext];
    Image *savedImg = [self fetchImageWithUrl:urlString inManagedObjectContext:objContext];
    
    [objContext performBlockAndWait:^{
        if (savedImg)
        {
            [savedImg setImage_data:UIImageJPEGRepresentation(image, 0.8f)];
        }else{
            Image *nImage = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:objContext];
            [nImage setUrl:urlString];
            [nImage setImage_data:UIImageJPEGRepresentation(image, 0.8f)];
        }
        
        NSError *saveError;
        
        if ([objContext hasChanges] && ![objContext save:&saveError]){
            NSLog(@"save core data image error");
        }
        
    }];
    
    return image;
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
-(NSArray*)fetchUsersWithIdFrom:(NSNumber*)startId toId:(NSNumber*)lastId inManagedObjectContext:(NSManagedObjectContext*)objContext
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

-(Image *)fetchImageWithUrl:(NSString*)urlString inManagedObjectContext:(NSManagedObjectContext*)objContext
{
    if (!objContext)
        return nil;
    
    if (!urlString)
        return nil;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Image"];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"url=%@",urlString]];
    
    __block NSArray *images;
    
    [objContext performBlockAndWait:^{
        NSError *error;
        images =  [objContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    if (!images || [images count]==0)
        return nil;
    
    __block Image *resImage;
    
    [objContext performBlockAndWait:^{

    if ([images count]>0)
    {
        [images enumerateObjectsUsingBlock:^(Image *img, NSUInteger idx, BOOL *stop) {
            if (idx==0){
                resImage = img;
            }else{
                [objContext deleteObject:img];
            }
        }];
        
        if ([images count]>1)
        {
            NSError *err;
            [objContext save:&err];
        }
    }
        
    }];
    
    return resImage;
}


@end
