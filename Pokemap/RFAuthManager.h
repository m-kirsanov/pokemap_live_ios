//
//  RFAuthManager.h
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RFAuthManagerSuccessCompletion)();
typedef void (^RFAuthManagerFailureCompletion)(NSString *description);


@interface RFAuthManager : NSObject

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *apiUrl;

+ (instancetype)instance;

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                onSuccess:(RFAuthManagerSuccessCompletion)successBlock
                onFailure:(RFAuthManagerFailureCompletion)failureBlock;

@end
