//
//  RFRPCGetMapObjectsRequest.m
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFRPCGetMapObjectsRequest.h"
#import "S2Geometry.h"
#import "RFLocationManager.h"

@implementation RFRPCGetMapObjectsRequest

- (Request *)createGetMapObjectsRequest {
    RequestBuilder *requestBuilder = [Request builder];
    
    requestBuilder.requestType = RPC_GET_MAP_OBJECTS;
    
    GetMapObjectsMessageBuilder *mapMessageBuilder = [GetMapObjectsMessage builder];
    
    //get cell id from s2-geometry
    CLLocation *currentLocation = [[RFLocationManager instance] currentLocation];
    
    if (!currentLocation) {
        return nil;
    }
    
    NSArray *cells = [s2geometry cellsForCoordinate:self.coordinate];
    
    for (NSString *cell in cells) {
        unsigned long long result = 0;
        
        NSScanner *scanner = [NSScanner scannerWithString:cell];
        [scanner scanHexLongLong:&result];
        
        [mapMessageBuilder addCellId:result];
        [mapMessageBuilder addSinceTimestampMs:0];
    }
    
    mapMessageBuilder.latitude = self.coordinate.latitude;
    mapMessageBuilder.longitude = self.coordinate.longitude;
    
    GetMapObjectsMessage *resultMessage = [mapMessageBuilder build];
    
    requestBuilder.requestMessage = [resultMessage data];
    
    return [requestBuilder build];
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
               onSuccess:(RFRPCRequestSuccessCompletion)successBlock
                 onFailure:(RFRPCRequestFailureCompletion)failureBlock {
    self = [super initWithType:RPC_GET_PLAYER
                     onSuccess:successBlock
                     onFailure:failureBlock];
    
    if (self) {
        self.coordinate = coordinate;
        
        self.requestEnvelop = [self createEnvelopWithRequest:[self createGetMapObjectsRequest]];
        
        self.requestEnvelop.latitude = coordinate.latitude;
        self.requestEnvelop.longitude = coordinate.longitude;
        
        [self addAuthTicket];
}
    
    return self;
}

@end
