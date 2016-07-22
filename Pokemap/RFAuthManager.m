//
//  RFAuthManager.m
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFAuthManager.h"
#import "RFNetworkManager.h"
#import <UICKeyChainStore/UICKeyChainStore.h>

#define ACCESS_TOKEN_KEY @"access_token"
#define API_URL_KEY @"api_url"

@implementation RFAuthManager

+ (instancetype)instance {
    static RFAuthManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

#pragma mark - Private

- (NSString *)accessToken {
    return [[UICKeyChainStore keyChainStore] stringForKey:ACCESS_TOKEN_KEY];
}

- (void)setAccessToken:(NSString *)accessToken {
    [[UICKeyChainStore keyChainStore] setString:accessToken forKey:ACCESS_TOKEN_KEY];
}

- (NSString *)apiUrl {
    NSString *savedUrl = [[UICKeyChainStore keyChainStore] stringForKey:API_URL_KEY];
    
    if (savedUrl) {
        return savedUrl;
    } else {
        return nil;
    }
}

- (void)setApiUrl:(NSString *)apiUrl {
    [[UICKeyChainStore keyChainStore] setString:apiUrl forKey:API_URL_KEY];
}

#pragma mark - Public

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                onSuccess:(RFAuthManagerSuccessCompletion)successBlock
                onFailure:(RFAuthManagerFailureCompletion)failureBlock {
    [[RFNetworkManager instance] loginWithUsername:username
                                          password:password
                                         onSuccess:^(NSString *access_token) {
                                             self.accessToken = access_token;
                                             
                                             [[RFNetworkManager instance]
                                              getApiUrlOnSuccess:^(NSString *api_url) {
                                                  self.apiUrl = [NSString stringWithFormat:@"https://%@/rpc", api_url];
                                                  NSLog(@"received url %@",self.apiUrl);
                                                  successBlock();
                                              }
                                              onFailure:^(NSString *description){
                                                  failureBlock(description);
                                              }];
                                         }
                                         onFailure:^(NSString *description) {
                                             failureBlock(description);
                                         }];
    
}

@end