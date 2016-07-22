//
//  RFNetworkManager.m
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFNetworkManager.h"
#import "RFConstants.h"
#import <DDURLParser.h>
#import "RFLocationManager.h"
#import "RFRPCGetProfileRequest.h"
#import "RFRPCGetMapObjectsRequest.h"

typedef void (^RFNetworkManagerPrepareLoginPTCSuccessCompletion)(NSString *lt, NSString *execution);
typedef void (^RFNetworkManagerPrepareLoginPTCFailureCompletion)(NSString *errorDescription);

typedef void (^RFNetworkManagerGetTicketSuccessCompletion)(NSString *ticket);
typedef void (^RFNetworkManagerGetTicketFailureCompletion)(NSString *errorDescription);

typedef void (^RFNetworkManagerGetAccessTokenRequestSuccessCompletion)(NSString *access_token);
typedef void (^RFNetworkManagerGetAccessTokenRequestFailureCompletion)(NSString *errorDescription);

@interface RFNetworkManager ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@end

@implementation RFNetworkManager

+ (RFNetworkManager *)instance {
    static dispatch_once_t pred;
    static RFNetworkManager *_instance = nil;
    
    dispatch_once(&pred, ^{
        _instance = [self new];
    });
    
    return _instance;
}

- (NSURLSessionConfiguration *)sessionConfiguration {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{@"User-Agent"  : @"Niantic App"};
    
    return sessionConfiguration;
}

- (AFHTTPSessionManager *)manager {
    if (!_manager) {
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[self sessionConfiguration]];
        //      manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        //    manager.securityPolicy.allowInvalidCertificates = YES;
        
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager = manager;
    }
    return _manager;
}

#pragma mark Login API

#pragma mark Private

- (void)prepareLoginPtcWithSuccess:(RFNetworkManagerPrepareLoginPTCSuccessCompletion)successBlock
                           failure:(RFNetworkManagerPrepareLoginPTCFailureCompletion)failureBlock {
    [self.manager GET:RFPokemonApiLoginUrl
           parameters:nil
             progress:nil
              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                  NSError *error;
                  NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                           options:0
                                                                             error:&error];
                  if (error) {
                      failureBlock(@"Invalid JSON received");
                  } else {
                      NSString *lt = jsonDict[@"lt"];
                      NSString *execution = jsonDict[@"execution"];
                      
                      successBlock(lt, execution);
                  }
              }
              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                  NSLog(@"Error preparing login %@", error);
                  failureBlock(error.localizedDescription);
              }];
}

- (void)getTicketWithParameters:(NSDictionary *)parameters
                      onSuccess:(RFNetworkManagerGetTicketSuccessCompletion)successBlock
                      onFailure:(RFNetworkManagerGetTicketFailureCompletion)failureBlock {
    [self.manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
        return nil;
    }];
    
    [self.manager POST:RFPokemonApiLoginUrl
            parameters:parameters
              progress:nil
               success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   NSError *error;
                   NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseObject
                                                                            options:0
                                                                              error:&error];
                   
                   if ([jsonDict[@"errors"] isKindOfClass:[NSArray class]]) {
                       NSString *errorString = jsonDict[@"errors"][0];
                       
                       NSLog(@"Error: %@", errorString);
                       failureBlock(errorString);
                   }
               }
               failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   NSHTTPURLResponse *response = (NSHTTPURLResponse *)[task response];
                   
                   if (response.statusCode == 302) { //redirected
                       NSString *locationHeader = response.allHeaderFields[@"Location"];
                       
                       DDURLParser *parser = [[DDURLParser alloc] initWithURLString:locationHeader];
                       
                       NSString *ticket = [parser valueForVariable:@"ticket"];
                       
                       if (ticket.length > 0) {
                           successBlock(ticket);
                       } else {
                           failureBlock(@"Failed to get ticket");
                       }
                   } else {
                       failureBlock(@"Invalid status code received");
                   }
               }];
}

- (void)getAccessTokenRequestWithParameters:(NSDictionary *)parameters
                                  onSuccess:(RFNetworkManagerGetAccessTokenRequestSuccessCompletion)successBlock
                                  onFailure:(RFNetworkManagerGetAccessTokenRequestFailureCompletion)failureBlock {
    [self.manager POST:RFPokemonApiLoginOauth
            parameters:parameters
              progress:nil
               success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                   NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                   
                   if (responseString.length > 0 && [responseString rangeOfString:@"access_token"].location != NSNotFound) {
                       //hack
                       NSString *urlStr = [NSString stringWithFormat:@"http://q.ru/?%@", responseString];
                       
                       DDURLParser *parser = [[DDURLParser alloc] initWithURLString:urlStr];
                       
                       NSString *access_token = [parser valueForVariable:@"access_token"];
                       
                       if (access_token.length > 0) {
                           successBlock(access_token);
                       } else {
                           failureBlock(@"Invalid token");
                       }
                   }
               }
               failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                   NSLog(@"%@",task.response);
                   failureBlock(error.localizedDescription);
               }];
}

#pragma mark Public

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                onSuccess:(RFNetworkManagerLoginSuccessCompletion)successBlock
                onFailure:(RFNetworkManagerLoginFailureCompletion)failureBlock {
    self.manager = nil;
    
    NSLog(@"start login process");
    [self prepareLoginPtcWithSuccess:^(NSString *lt, NSString *execution) {
        NSLog(@"prepare login success");
        NSLog(@"received lt %@ execution %@", lt, execution);
        
        NSMutableDictionary *loginData = [NSMutableDictionary new];
        
        loginData[@"lt"] = lt;
        loginData[@"execution"] = execution;
        loginData[@"_eventId"] = @"submit";
        loginData[@"username"] = username;
        loginData[@"password"] = password;
        
        [self getTicketWithParameters:loginData
                            onSuccess:^(NSString *ticket) {
                                NSLog(@"received ticket %@", ticket);
                                
                                NSMutableDictionary *getTokenParameters = [NSMutableDictionary new];
                                
                                getTokenParameters[@"client_id"] = @"mobile-app_pokemon-go";
                                getTokenParameters[@"redirect_uri"] = @"https://www.nianticlabs.com/pokemongo/error";
                                getTokenParameters[@"client_secret"] = RFPokemonApiClientSecret;
                                getTokenParameters[@"grant_type"] = @"refresh_token";
                                getTokenParameters[@"code"] = ticket;
                                
                                [self getAccessTokenRequestWithParameters:getTokenParameters
                                                                onSuccess:^(NSString *access_token) {
                                                                    NSLog(@"logged with access token %@", access_token);
                                                                    successBlock(access_token);
                                                                }
                                                                onFailure:^(NSString *errorDescription) {
                                                                    NSLog(@"get token error %@", errorDescription);
                                                                    failureBlock(errorDescription);
                                                                }];
                            }
                            onFailure:^(NSString *errorDescription) {
                                NSLog(@"error getting ticket: %@",errorDescription);
                                failureBlock(errorDescription);
                            }];
        
    } failure:^(NSString *errorDescription) {
        NSLog(@"error prepare login: %@",errorDescription);
        failureBlock(errorDescription);
    }];
}

#pragma mark - Get Profile

- (void)getApiUrlOnSuccess:(RFNetworkManagerGetApiUrlSuccessCompletion)successBlock
                 onFailure:(RFNetworkManagerGetApiUrlFailureCompletion)failureBlock {
    RFRPCGetProfileRequest *request = [[RFRPCGetProfileRequest alloc]
                                       initWithSuccess:^(ResponseEnvelope *response) {
                                           NSLog(@"%@",response);
                                           
                                           if ([response hasApiUrl]) {
                                               successBlock(response.apiUrl);
                                           } else {
                                               failureBlock(@"Invalid response");
                                           }
                                       }
                                       failure:^(NSString *description) {
                                           failureBlock(description);
                                       }];
    request.apiUrl = RFPokemonApiUrl;
    [request start];
}

- (void)getProfileOnSuccess:(RFNetworkManagerGetProfileSuccessCompletion)successBlock
                  onFailure:(RFNetworkManagerGetProfileFailureCompletion)failureBlock {
    RFRPCGetProfileRequest *request = [[RFRPCGetProfileRequest alloc]
                                       initWithSuccess:^(ResponseEnvelope *response) {
                                           NSLog(@"%@",response);
                                           if (response.statusCode == 1 ||
                                               response.statusCode == 53 ||
                                               response.statusCode == 2) {
                                               
                                                   successBlock(@"");
                                               
                                           } else {
                                               failureBlock(@"Server error");
                                           }
                                       }
                                       failure:^(NSString *description) {
                                           failureBlock(description);
                                       }];
    request.apiUrl = [[RFAuthManager instance] apiUrl];
    [request start];
}

- (void)getMapObjectsWithCoordinate:(CLLocationCoordinate2D)coordinate
                          onSuccess:(RFRPCRequestGetMapObjectsSuccessCompletion)successBlock
                          onFailure:(RFRPCRequestGetMapObjectsFailureCompletion)failureBlock {
    RFRPCGetMapObjectsRequest *request = [[RFRPCGetMapObjectsRequest alloc]
                                          initWithCoordinate:coordinate
                                          onSuccess:^(ResponseEnvelope *response) {
                                              
                                              if (response.statusCode == 1) {
                                                  if (response.returns.count > 0) {
                                                      GetMapObjectsResponse *resp = [GetMapObjectsResponse parseFromData:response.returns[0]];
                                                      
                                                      // NSLog(@"%@",resp);
                                                      successBlock(resp);
                                                  } else {
                                                      successBlock(nil);
                                                  }
                                              } else {
                                                  failureBlock(@"Server error");
                                              }
                                          }
                                          onFailure:^(NSString *description) {
                                              failureBlock(description);
                                          }];
    request.apiUrl = [[RFAuthManager instance] apiUrl];
    [request start];
}

@end
