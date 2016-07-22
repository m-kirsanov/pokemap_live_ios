//
//  RFNetworkManager.h
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFRPCRequest.h"
#import <AFNetworking.h>

typedef void (^RFNetworkManagerLoginSuccessCompletion)(NSString *access_token);
typedef void (^RFNetworkManagerLoginFailureCompletion)(NSString *description);

typedef void (^RFNetworkManagerGetApiUrlSuccessCompletion)(NSString *api_url);
typedef void (^RFNetworkManagerGetApiUrlFailureCompletion)(NSString *description);

typedef void (^RFNetworkManagerGetProfileSuccessCompletion)();
typedef void (^RFNetworkManagerGetProfileFailureCompletion)(NSString *description);

typedef void (^RFRPCRequestGetMapObjectsSuccessCompletion)(GetMapObjectsResponse *mapObjects);
typedef void (^RFRPCRequestGetMapObjectsFailureCompletion)(NSString *description);

@interface RFNetworkManager : NSObject

@property (nonatomic, strong) ResponseAuthTicket *lastAuthTicket;

+ (instancetype)instance;

- (AFHTTPSessionManager *)manager;

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                onSuccess:(RFNetworkManagerLoginSuccessCompletion)successBlock
                onFailure:(RFNetworkManagerLoginFailureCompletion)failureBlock;

- (void)getApiUrlOnSuccess:(RFNetworkManagerGetApiUrlSuccessCompletion)successBlock
                 onFailure:(RFNetworkManagerGetApiUrlFailureCompletion)failureBlock;

- (void)getProfileOnSuccess:(RFNetworkManagerGetProfileSuccessCompletion)successBlock
                  onFailure:(RFNetworkManagerGetProfileFailureCompletion)failureBlock;

- (void)getMapObjectsWithCoordinate:(CLLocationCoordinate2D)coordinate
                          onSuccess:(RFRPCRequestGetMapObjectsSuccessCompletion)successBlock
                          onFailure:(RFRPCRequestGetMapObjectsFailureCompletion)failureBlock;

@end
