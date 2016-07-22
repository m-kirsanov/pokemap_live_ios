//
//  RFRPCRequest.m
//  Pokemap
//
//  Created by Михаил on 20.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFRPCRequest.h"
#import "RFConstants.h"
#import "RFLocationManager.h"
#import "RFNetworkManager.h"

@interface RFRPCRequest ()

@property (nonatomic, assign) BOOL requesting;

@end

@implementation RFRPCRequest

#pragma mark - Private

- (RequestEnvelopeBuilder *)createEnvelopWithRequest:(Request *)request {
    RequestEnvelopeBuilder *requestEnvelop = [RequestEnvelope builder];
    
    [requestEnvelop addRequests:request];
    
    requestEnvelop.statusCode = 2;
    
    requestEnvelop.requestId = [[NSDate date] timeIntervalSince1970] * 1000;
    
    CLLocation *currentLocation = [[RFLocationManager instance] currentLocation];
    
    if (currentLocation) {
        requestEnvelop.latitude = currentLocation.coordinate.latitude;
        requestEnvelop.longitude = currentLocation.coordinate.longitude;
        requestEnvelop.altitude = -1;
    }
    
    requestEnvelop.unknown12 = 989;
    
    return requestEnvelop;
}

- (void)addAuthTicket {
    ResponseAuthTicket *lastTicket = [[RFNetworkManager instance] lastAuthTicket];
    if (lastTicket) {
        AuthTicketBuilder *authTicket = [AuthTicket builder];
        authTicket.start = lastTicket.start;
        authTicket.expireTimestampMs = lastTicket.expireTimestampMs;
        authTicket.end = lastTicket.end;
        
        self.requestEnvelop.authTicket = [authTicket build];
    }
}

- (void)addAuthInfo {
    RFAuthManager *authManager = [RFAuthManager instance];
    
    NSString *token = [authManager accessToken];
    if (token) {
        AuthInfoBuilder *authInfo = [AuthInfo builder];
        authInfo.provider = RFPokemonApiService;
        
        JWTBuilder *authJWT = [JWT builder];
        authJWT.contents = token;
        authJWT.unknown2 = 59;
        
        authInfo.token = [authJWT build];
        
        self.requestEnvelop.authInfo = [authInfo build];
    }
}

- (void)addUnknown6 {
    RequestEnvelopeUnknown6Builder *unknown6 = [RequestEnvelopeUnknown6 builder];
    
    unknown6.unknown1 = 6;
    
    NSMutableData *timedata = [NSMutableData data];
    char bytesToAppend[18] = {0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80};
    
    [timedata appendBytes:bytesToAppend length:sizeof(bytesToAppend)];
    
    RequestEnvelopeUnknown6Unknown2Builder *unknown6Unknown2 = [RequestEnvelopeUnknown6Unknown2 builder];
    unknown6Unknown2.unknown1 = timedata;
    
    unknown6.unknown2 = [unknown6Unknown2 build];
    
    self.requestEnvelop.unknown6 = [unknown6 build];
}

#pragma mark - Public

- (id)initWithType:(int)type
         onSuccess:(RFRPCRequestSuccessCompletion)successBlock
         onFailure:(RFRPCRequestFailureCompletion)failureBlock {
    self = [super init];
    if (self) {
        self.timeout = 5;
        self.retryCountLeft = 5;
        
        self.type = type;
        
        self.successBlock = successBlock;
        self.failureBlock = failureBlock;
    }
    return self;
}

- (void)start {
    if (_requesting) {
        return;
    }
    
    if (!_requestEnvelop) {
        _failureBlock(@"Internal Error");
        return;
    }
    
    if (!_apiUrl) {
        _failureBlock(@"");
        return;
    }
    
    _requesting = YES;
    
    NSData *data = [_requestEnvelop build].data;
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.apiUrl]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    request.timeoutInterval = _timeout;
    
    [request setValue:@"Niantic App" forHTTPHeaderField:@"User-Agent"];
    
    //NSLog(@"%@",request);
    NSURLSession *session = [[[RFNetworkManager instance] manager] session];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data,
                                                                NSURLResponse * _Nullable response,
                                                                NSError * _Nullable error) {
                                                _requesting = NO;
                                                NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
                                                if (error || res.statusCode != 200) {
                                                    _retryCountLeft--;
                                                    
                                                    if (_retryCountLeft > 0) {
                                                        [self start];
                                                    } else {
                                                        self.failureBlock(@"Request timeout");
                                                    }
                                                } else {
                                                    ResponseEnvelope *resp = [ResponseEnvelope parseFromData:data];
                                                    
                                                    //NSLog(@"%@", resp);
                                                    if (resp.hasAuthTicket) {
                                                        [[RFNetworkManager instance] setLastAuthTicket:resp.authTicket];
                                                    }
                                                    self.successBlock(resp);
                                                }
                                            }];
    [task resume];
}

@end
