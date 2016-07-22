//
//  RFPokemonMarker.h
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "Response.pb.h"

@class RFPokemonMarker;

@protocol RFPokemonMarkerDelegate <NSObject>

- (void)needRemovePokemon:(RFPokemonMarker *)marker;

@end

@interface RFPokemonMarker : GMSMarker

@property (nonatomic, weak) id <RFPokemonMarkerDelegate> delegate;

@property (nonatomic, assign) int pokemonId;
@property (nonatomic, strong) NSString *pokemonName;
@property (nonatomic, assign) NSTimeInterval timeExpireDate;
@property (nonatomic, strong) NSString *pokemonSpawnId;
@property (nonatomic, strong) NSTimer *snippetTimer;

- (id)initWithMapPokemon:(MapPokemon *)mapPokemon;
- (id)initWithWildPokemon:(WildPokemon *)wildPokemon;

@end
