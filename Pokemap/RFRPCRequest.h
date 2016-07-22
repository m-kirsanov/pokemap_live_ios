//
//  RFRPCRequest.h
//  Pokemap
//
//  Created by Михаил on 20.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Request.pb.h"
#import "Response.pb.h"
#import <CoreLocation/CoreLocation.h>
#import "RFRPCRequestTypes.h"
#import "RFAuthManager.h"

#define RAND_FROM_TO(min, max) (min + arc4random_uniform(max - min + 1))

typedef void (^RFRPCRequestSuccessCompletion)(ResponseEnvelope *response);
typedef void (^RFRPCRequestFailureCompletion)(NSString *description);

static inline uint64_t doubleToRawBits(double x) {
    uint64_t bits;
    memcpy(&bits, &x, sizeof bits);
    return bits;
}

@interface RFRPCRequest : NSObject

@property (nonatomic, strong) NSString *apiUrl;
@property (nonatomic, assign) NSInteger timeout;
@property (nonatomic, assign) NSInteger retryCountLeft;
@property (nonatomic, assign) int type;
@property (nonatomic, strong) RequestEnvelopeBuilder *requestEnvelop;
@property (nonatomic, strong) RFRPCRequestFailureCompletion failureBlock;
@property (nonatomic, strong) RFRPCRequestSuccessCompletion successBlock;

- (id)initWithType:(int)type
         onSuccess:(RFRPCRequestSuccessCompletion)successBlock
         onFailure:(RFRPCRequestFailureCompletion)failureBlock;

- (RequestEnvelopeBuilder *)createEnvelopWithRequest:(Request *)request;

- (void)addAuthInfo;
- (void)addAuthTicket;
- (void)addUnknown6;

- (void)start;

@end
