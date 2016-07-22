//
//  RFRPCGetProfileRequest.m
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFRPCGetProfileRequest.h"

@implementation RFRPCGetProfileRequest

- (Request *)createGetPlayerRequest {
    Request *request = [[[Request builder] setRequestType:RPC_GET_PLAYER] build];
    return request;
}

- (id)initWithSuccess:(RFRPCRequestSuccessCompletion)successBlock
              failure:(RFRPCRequestFailureCompletion)failureBlock {
    self = [super initWithType:RPC_GET_PLAYER
                     onSuccess:successBlock
                     onFailure:failureBlock];
    
    if (self) {
        self.requestEnvelop = [self createEnvelopWithRequest:[self createGetPlayerRequest]];
        
        [self addAuthInfo];
    }
    
    return self;
}

@end
