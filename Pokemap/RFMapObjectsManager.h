//
//  RFMapObjectsManager.h
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFPokemonMarker.h"

@protocol RFMapObjectsManagerDelegate <NSObject>

- (void)newPokemonsReceived:(NSArray *)array;
- (void)needRemovePokemonFromMap:(RFPokemonMarker *)marker;
- (void)showLoader;
- (void)hideLoader;

@end
@interface RFMapObjectsManager : NSObject <RFPokemonMarkerDelegate>

@property (nonatomic, weak) id <RFMapObjectsManagerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *pokemonsArray;
@property (nonatomic, assign) BOOL gettingData;
@property (nonatomic, assign) BOOL internal_gettingData;
@property (nonatomic, strong) NSMutableArray *coordinatesArray;
@property (nonatomic, assign) NSTimeInterval lastTimeStamp;
@property (nonatomic, assign) CLLocationCoordinate2D lastCoordinate;

@property (nonatomic, assign) NSTimeInterval lastGlobalTimeStamp;

+ (instancetype)instance;

- (void)getMapObjectsWithCoordinate:(CLLocationCoordinate2D)coordinate;

- (void)cleanExpiredPokemons;

@end
