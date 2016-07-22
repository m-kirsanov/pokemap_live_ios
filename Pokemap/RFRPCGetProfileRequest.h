//
//  RFRPCGetProfileRequest.h
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFRPCRequest.h"

@interface RFRPCGetProfileRequest : RFRPCRequest

- (id)initWithSuccess:(RFRPCRequestSuccessCompletion)successBlock
              failure:(RFRPCRequestFailureCompletion)failureBlock;

@end
