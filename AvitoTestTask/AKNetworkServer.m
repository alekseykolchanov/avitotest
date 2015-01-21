//
//  AKNetworkServer.m
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "AKNetworkServer.h"

NSString *const SERVER_URL = @"https://api.github.com/";

NSString *const PARSE_ERROR_DOMAIN = @"NetworkServer error";
NSString *const IMAGE_ERROR_DOMAIN = @"ImageProcessing error";

@interface AKNetworkServer ()<NSURLSessionDelegate>

@property (nonatomic,strong) NSURLSession *mainURLSession;


@end


@implementation AKNetworkServer

+(AKNetworkServer *)share
{
    static dispatch_once_t once;
    static AKNetworkServer *sharedInst;
    dispatch_once(&once, ^{
        sharedInst = [[self alloc]init];
    });
    
    return sharedInst;
}


-(NSURLSession *)mainURLSession
{
    if (!_mainURLSession)
    {
        NSURLSessionConfiguration *myConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [myConfiguration setAllowsCellularAccess:YES];
        [myConfiguration setURLCache:nil];
        [myConfiguration setHTTPMaximumConnectionsPerHost:2];
        [myConfiguration setTimeoutIntervalForRequest:15.0f];
        _mainURLSession = [NSURLSession sessionWithConfiguration:myConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    
    return _mainURLSession;
}


#pragma mark - requests

-(void)getUsersSinceUserId:(NSNumber*)lastAvailableUserId withCompletion:(void (^) (BOOL isLast, NSArray *usersJsonArray, NSError *error))completion
{
    NSString *urlString = [SERVER_URL stringByAppendingString:@"users"];
    
    if (lastAvailableUserId)
        urlString = [urlString stringByAppendingFormat:@"?since=%d",[lastAvailableUserId intValue]];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *dTask = [[self mainURLSession] dataTaskWithRequest:req completionHandler:^(NSData *resData, NSURLResponse *response, NSError *error){
        if (!error)
        {
            NSError *parseError;
            NSArray *resItems = [self manageUpdateUsersSinceUserId:lastAvailableUserId resData:resData error:&parseError];
            
            BOOL isLastUserPage = NO;
            
            if (resItems&& [resItems count]<100 && !parseError){
                isLastUserPage = YES;
            }
            
            if (completion)
                completion(isLastUserPage,resItems,parseError);
        }else{
            if (completion)
                completion(NO,nil,error);
        }
    }];
    
    [dTask resume];
}

-(void)getImageAtUrl:(NSString*)imageUrlString withCompletion:(void (^) (UIImage *image, NSError *error))completion
{
    if (!imageUrlString)
    {
        if (completion)
            completion(nil,nil);
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:imageUrlString];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *dTask = [[self mainURLSession] dataTaskWithRequest:req completionHandler:^(NSData *resData, NSURLResponse *response, NSError *error){
        if (!error)
        {
            NSError *imageError;
            UIImage *resImg = [self manageGetImageData:resData error:&imageError];
            
            if (completion)
                completion(resImg,imageError);
            
        }else{
            
            if (completion)
                completion(nil,error);
        }
        
    }];
    
    [dTask resume];
    
    
}

#pragma mark - response manage
-(id)jsonFromData:(NSData*)dataContainer error:(NSError**)error
{
    if (!dataContainer){
        NSString *errorString = @"Received data parse error";
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString};
        *error = [[NSError alloc] initWithDomain:PARSE_ERROR_DOMAIN
                                            code:401
                                        userInfo:userInfoDict];
        return nil;
    }
    
    
    NSError *parseError;
    id d = [NSJSONSerialization JSONObjectWithData:dataContainer
                                                      options:0
                                                        error:&parseError];
    if (parseError)
    {
        NSString *errorString = @"Received data parse error";
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString};
        *error = [[NSError alloc] initWithDomain:PARSE_ERROR_DOMAIN
                                            code:401
                                        userInfo:userInfoDict];
        return nil;
    }
    
    if ([dataContainer length]>0 && !d){
        NSString *errorString = @"Received data parse error";
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString};
        *error = [[NSError alloc] initWithDomain:PARSE_ERROR_DOMAIN
                                            code:401
                                        userInfo:userInfoDict];
        return nil;
    }
    
    return d;
}

-(UIImage*)manageGetImageData:(NSData*)dataContainer error:(NSError**)error
{
    if (!dataContainer)
        return nil;
    
    
    UIImage *resImg;
    
    @try {
        resImg = [UIImage imageWithData:dataContainer];
    }
    @catch (NSException *exception) {
        NSString *errorString = @"Unable to get image from data";
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString};
        *error = [[NSError alloc] initWithDomain:IMAGE_ERROR_DOMAIN
                                            code:401
                                        userInfo:userInfoDict];
    }
    
    
    return resImg;
}

-(NSArray *)manageUpdateUsersSinceUserId:(NSNumber*)lastUserId resData:(NSData*)dataContainer error:(NSError**)error
{
    NSArray *items = [self jsonFromData:dataContainer error:error];
    
    if (!error){
        if (![items isKindOfClass:[NSArray class]]){
            items = nil;
            NSString *errorString = @"Received data parse error";
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString};
            *error = [[NSError alloc] initWithDomain:PARSE_ERROR_DOMAIN
                                                code:402
                                            userInfo:userInfoDict];
        }
    }
    
    return items;
}


#pragma  mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"URLSession:didBecomeInvalidWithError:%@",[error localizedDescription]);
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession:");
}

#pragma mark NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    
}

@end
