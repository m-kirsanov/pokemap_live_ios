//
//  RFConstants.h
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFConstants : NSObject

#pragma mark Google Maps

extern NSString *RFGoogleApiKey;

#pragma mark - API

extern NSString *RFPokemonApiUrl;
extern NSString *RFPokemonApiLoginUrl;
extern NSString *RFPokemonApiLoginOauth;

extern NSString *RFPokemonApiRequestUserAgent;

extern NSString *RFPokemonApiAppId;
extern NSString *RFPokemonApiAndroidId;
extern NSString *RFPokemonApiClientSecret;
extern NSString *RFPokemonApiService;
extern NSString *RFPokemonApiClientSig;

@end
