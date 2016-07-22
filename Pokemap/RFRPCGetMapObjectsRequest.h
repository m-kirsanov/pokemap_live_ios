//
//  RFRPCGetMapObjectsRequest.h
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFRPCRequest.h"

@interface RFRPCGetMapObjectsRequest : RFRPCRequest

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
                onSuccess:(RFRPCRequestSuccessCompletion)successBlock
                onFailure:(RFRPCRequestFailureCompletion)failureBlock;

@end
