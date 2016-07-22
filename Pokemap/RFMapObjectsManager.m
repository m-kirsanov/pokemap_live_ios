//
//  RFMapObjectsManager.m
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFMapObjectsManager.h"
#import "RFLocationManager.h"
#import "RFNetworkManager.h"
#import "RFCoordinate.h"

#define MAX_KMH 2000

@implementation RFMapObjectsManager

+ (instancetype)instance {
    static RFMapObjectsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.pokemonsArray = [NSMutableArray new];
    });
    
    return instance;
}

- (double)radiansFromDegrees:(double)degrees {
    return degrees * (M_PI/180.0);
}

- (double)degreesFromRadians:(double)radians {
    return radians * (180.0/M_PI);
}

- (CLLocationCoordinate2D)coordinateFromCoord:
(CLLocationCoordinate2D)fromCoord
                                 atDistanceKm:(double)distanceKm
                             atBearingDegrees:(double)bearingDegrees
{
    double distanceRadians = distanceKm / 6371.0;
    //6,371 = Earth's radius in km
    double bearingRadians = [self radiansFromDegrees:bearingDegrees];
    double fromLatRadians = [self radiansFromDegrees:fromCoord.latitude];
    double fromLonRadians = [self radiansFromDegrees:fromCoord.longitude];
    
    double toLatRadians = asin( sin(fromLatRadians) * cos(distanceRadians)
                               + cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians) );
    
    double toLonRadians = fromLonRadians + atan2(sin(bearingRadians)
                                                 * sin(distanceRadians) * cos(fromLatRadians), cos(distanceRadians)
                                                 - sin(fromLatRadians) * sin(toLatRadians));
    
    // adjust toLonRadians to be in the range -180 to +180...
    toLonRadians = fmod((toLonRadians + 3*M_PI), (2*M_PI)) - M_PI;
    
    CLLocationCoordinate2D result;
    result.latitude = [self degreesFromRadians:toLatRadians];
    result.longitude = [self degreesFromRadians:toLonRadians];
    return result;
}

- (NSArray *)coordinatesAroundArrayWithCoordinate:(CLLocationCoordinate2D)coordinate {
    double dist = 0.400;
    double distDiag = 0.285;
    
    CLLocationCoordinate2D center = coordinate;
    
    RFCoordinate *centerCoord = [RFCoordinate new];
    centerCoord.coordinate = center;
    
    CLLocationCoordinate2D leftCenter = [self coordinateFromCoord:center
                                                     atDistanceKm:dist
                                                 atBearingDegrees:270];
    
    RFCoordinate *leftCenterCoord = [RFCoordinate new];
    leftCenterCoord.coordinate = leftCenter;
    
    CLLocationCoordinate2D leftTop = [self coordinateFromCoord:center
                                                  atDistanceKm:distDiag
                                              atBearingDegrees:315];
    
    RFCoordinate *leftTopCoord = [RFCoordinate new];
    leftTopCoord.coordinate = leftTop;
    
    CLLocationCoordinate2D top = [self coordinateFromCoord:center
                                              atDistanceKm:dist
                                          atBearingDegrees:0];
    
    RFCoordinate *topCoord = [RFCoordinate new];
    topCoord.coordinate = top;
    
    CLLocationCoordinate2D rightTop = [self coordinateFromCoord:center
                                                   atDistanceKm:distDiag
                                               atBearingDegrees:45];
    
    RFCoordinate *rightTopCoord = [RFCoordinate new];
    rightTopCoord.coordinate = rightTop;
    
    CLLocationCoordinate2D rightCenter = [self coordinateFromCoord:center
                                                      atDistanceKm:dist
                                                  atBearingDegrees:90];
    
    RFCoordinate *rightCenterCoord = [RFCoordinate new];
    rightCenterCoord.coordinate = rightCenter;
    
    CLLocationCoordinate2D rightBottom = [self coordinateFromCoord:center
                                                      atDistanceKm:distDiag
                                                  atBearingDegrees:135];
    
    RFCoordinate *rightBottomCoord = [RFCoordinate new];
    rightBottomCoord.coordinate = rightBottom;
    
    CLLocationCoordinate2D bottom = [self coordinateFromCoord:center
                                                 atDistanceKm:dist
                                             atBearingDegrees:180];
    
    RFCoordinate *bottomCoord = [RFCoordinate new];
    bottomCoord.coordinate = bottom;
    
    CLLocationCoordinate2D leftBottom = [self coordinateFromCoord:center
                                                     atDistanceKm:distDiag
                                                 atBearingDegrees:225];
    
    RFCoordinate *leftBottomCoord = [RFCoordinate new];
    leftBottomCoord.coordinate = leftBottom;
    
    NSArray *resultArray = @[centerCoord,
                             leftCenterCoord,
                             leftTopCoord,
                             topCoord,
                             rightTopCoord,
                             rightCenterCoord,
                             rightBottomCoord,
                             bottomCoord,
                             leftBottomCoord];
    
    return resultArray;
}

- (void)internal_getMapObjectsWithCoordinate:(RFCoordinate *)coordinate {
    @synchronized (self) {
        if (_internal_gettingData) {
            return;
        }
        
        if (_lastCoordinate.latitude != 0 && _lastCoordinate.longitude != 0) {
            //CHECK that position changes not too fast
            
            NSTimeInterval timeElapsed = [[NSDate date] timeIntervalSince1970] - _lastTimeStamp;
            double distanceFromLast = GMSGeometryDistance(coordinate.coordinate, _lastCoordinate);
            
            double metersPassedInSec = distanceFromLast / timeElapsed;
            double metersPassedInHour = metersPassedInSec * 60 * 60;
            
            double kmPassedInHour = metersPassedInHour / 1000;
            
            // NSLog(@"speed %f", kmPassedInHour);
            
            if (kmPassedInHour > MAX_KMH) {
                //NSLog(@"too fast speed");
                return;
            }
        }
        
        _internal_gettingData = YES;
        
        [[RFNetworkManager instance] getMapObjectsWithCoordinate:coordinate.coordinate
                                                       onSuccess:^(GetMapObjectsResponse *mapObjects) {
                                                           _lastTimeStamp = [[NSDate date] timeIntervalSince1970];
                                                           _lastCoordinate = coordinate.coordinate;
                                                           if (mapObjects) {
                                                               dispatch_sync(dispatch_get_main_queue(), ^{
                                                                   [self updateMarkersWithData:mapObjects];
                                                                   //[_delegate debug_drawCircleAround:_lastCoordinate];
                                                                   
                                                                   coordinate.received = YES;
                                                                   _internal_gettingData = NO;
                                                               });
                                                           }
                                                           
                                                       }
                                                       onFailure:^(NSString *description) {
                                                           coordinate.received = NO;
                                                           _internal_gettingData = NO;
                                                       }];
    }
}

- (void)getMapObjectsWithCoordinate:(CLLocationCoordinate2D)coordinate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_gettingData) {
            return;
        }
        
        if (![RFAuthManager instance].apiUrl) {
            return;
        }
        
        if ([[NSDate date] timeIntervalSince1970] - _lastGlobalTimeStamp < 25) {
            NSLog(@"need wait");
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate showLoader];
        });
        
        _gettingData = YES;
        
        //prepare coordinates array
        
        self.coordinatesArray = [NSMutableArray new];
        [self.coordinatesArray addObjectsFromArray:[self coordinatesAroundArrayWithCoordinate:coordinate]];
        
        if (!self.coordinatesArray) {
            _gettingData = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_delegate hideLoader];
            });
            return;
        }
        
        while (_gettingData) {
            RFCoordinate *coordToGet = nil;
            
            //search for next coordinate to get
            
            for (RFCoordinate *coord in _coordinatesArray) {
                if (!coord.received) {
                    coordToGet = coord;
                    break;
                }
            }
            
            
            if (coordToGet) {
                [self internal_getMapObjectsWithCoordinate:coordToGet];
            } else if (_gettingData) {
                _lastGlobalTimeStamp = [[NSDate date] timeIntervalSince1970];
                _gettingData = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate hideLoader];
                });
                return;
            }
            sleep(1);
        }
    });
}

- (BOOL)isPokemonSpawnPointExists:(NSString *)spawnPoint inArray:(NSArray *)array {
    BOOL exists = NO;
    
    for (RFPokemonMarker *marker in array) {
        if ([marker.pokemonSpawnId isEqualToString:spawnPoint]) {
            exists = YES;
            
            break;
        }
    }
    
    return exists;
}

- (void)updateMarkersWithData:(GetMapObjectsResponse *)data {
    NSMutableArray *newPokemons = [NSMutableArray new];
    
    for (MapCell *cell in data.mapCells) {
        for (MapPokemon *mapPok in cell.catchablePokemons) {
            // NSLog(@"map id %i spawn %@",(int)mapPok.pokemonId, mapPok.spawnpointId);
            if (![self isPokemonSpawnPointExists:mapPok.spawnpointId inArray:_pokemonsArray] &&
                ![self isPokemonSpawnPointExists:mapPok.spawnpointId inArray:newPokemons]) {
                RFPokemonMarker *pokemonMarker = [[RFPokemonMarker alloc] initWithMapPokemon:mapPok];
                pokemonMarker.delegate = self;
                [newPokemons addObject:pokemonMarker];
                
                
            }
        }
        
        for (WildPokemon *wild in cell.wildPokemons) {
            // NSLog(@"wild id %i spawn %@",(int)wild.pokemonData.pokemonId, wild.spawnpointId);
            if (![self isPokemonSpawnPointExists:wild.spawnpointId inArray:_pokemonsArray] &&
                ![self isPokemonSpawnPointExists:wild.spawnpointId inArray:newPokemons]) {
                RFPokemonMarker *pokemonMarker = [[RFPokemonMarker alloc] initWithWildPokemon:wild];
                pokemonMarker.delegate = self;
                [newPokemons addObject:pokemonMarker];
                
                
            } else {
                //NSLog(@"exists wild %@", wild.spawnpointId);
            }
        }
    }
    
    [_pokemonsArray addObjectsFromArray:newPokemons];
    
    // NSLog(@"new pokemons count %i", newPokemons.count);
    
    [_delegate newPokemonsReceived:newPokemons];
}

- (void)needRemovePokemon:(RFPokemonMarker *)marker {
    NSLog(@"removing pokemon %@", marker.pokemonSpawnId);
    
    [_delegate needRemovePokemonFromMap:marker];
    
    NSLog(@"before %i", _pokemonsArray.count);
    [_pokemonsArray removeObject:marker];
    NSLog(@"after %i", _pokemonsArray.count);
}

- (void)cleanExpiredPokemons {
    for (RFPokemonMarker *marker in [_pokemonsArray copy]) {
        if (marker.timeExpireDate < [[NSDate date] timeIntervalSince1970]) {
            [self needRemovePokemon:marker];
        }
    }
}
@end
