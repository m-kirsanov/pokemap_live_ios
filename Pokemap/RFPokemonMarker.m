//
//  RFPokemonMarker.m
//  Pokemap
//
//  Created by Михаил on 21.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFPokemonMarker.h"

@implementation RFPokemonMarker

- (void)setMap:(GMSMapView *)map {
    if (map == nil) {
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:self.layer.opacity];
        opacityAnimation.toValue = [NSNumber numberWithFloat:0.0];
        opacityAnimation.duration = 0.3;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.3];
        [CATransaction setCompletionBlock:^{
            [super setMap:nil];
        }];
        [self.layer addAnimation:opacityAnimation forKey:@"opacity"];
        [CATransaction commit];
        self.layer.opacity = 0;
    } else {
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = [NSNumber numberWithFloat:self.layer.opacity];
        opacityAnimation.toValue = [NSNumber numberWithFloat:1.0];
        opacityAnimation.duration = 0.3;
        [super setMap:map];
        
        [self.layer addAnimation:opacityAnimation forKey:@"opacity"];
        self.layer.opacity = 1;
    }
}

- (void)setPokemonId:(int)pokemonId {
    _pokemonId = pokemonId;
    
    NSString *image = [NSString stringWithFormat:@"%i",(int)pokemonId];
    self.icon = [UIImage imageNamed:image];
}

- (void)updateSnippet {
    NSTimeInterval timeToExpire = (self.timeExpireDate / 1000) - [[NSDate date] timeIntervalSince1970];
    
    int mins = timeToExpire / 60;
    int secs = (int)timeToExpire % 60;
    
    self.snippet = [NSString stringWithFormat:@"Time to dissapear %02d:%02d", mins, secs];
}

- (id)initWithMapPokemon:(MapPokemon *)mapPokemon {
    self = [super init];
    if (self) {
        self.appearAnimation = kGMSMarkerAnimationPop;
        self.groundAnchor = CGPointMake(0.5, 0.5);
        self.position = CLLocationCoordinate2DMake(mapPokemon.latitude, mapPokemon.longitude);
        self.pokemonSpawnId = mapPokemon.spawnpointId;
        self.pokemonId = mapPokemon.pokemonId;
        self.timeExpireDate = mapPokemon.expirationTimestampMs;

        if (self.timeExpireDate < 0) {
            self.timeExpireDate = ([[NSDate date] timeIntervalSince1970] * 1000) + ((60 * 60) * 1000);
            NSLog(@"time < 0 for pokemon id %i", self.pokemonId);
        }
        NSTimeInterval timeToExpire = (self.timeExpireDate / 1000) - [[NSDate date] timeIntervalSince1970];
        
        self.snippetTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                             target:self
                                                           selector:@selector(updateSnippet)
                                                           userInfo:nil repeats:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToExpire * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_snippetTimer invalidate];
            self.snippetTimer = nil;
            
            [_delegate needRemovePokemon:self];
        });
    }
    return self;
}

- (id)initWithWildPokemon:(WildPokemon *)wildPokemon {
    self = [super init];
    if (self) {
        self.appearAnimation = kGMSMarkerAnimationPop;
        self.groundAnchor = CGPointMake(0.5, 0.5);
        self.position = CLLocationCoordinate2DMake(wildPokemon.latitude, wildPokemon.longitude);
        self.pokemonSpawnId = wildPokemon.spawnpointId;
        self.pokemonId = wildPokemon.pokemonData.pokemonId;
        
        int timetill = wildPokemon.timeTillHiddenMs;
        
        if (timetill < 0) {
            timetill = (60 * 60) * 1000;
            NSLog(@"time < 0 for pokemon id %i", self.pokemonId);
        }
        NSTimeInterval timeToExpire = timetill / 1000;
        
        self.timeExpireDate = ([[NSDate date] timeIntervalSince1970] * 1000) + timetill;
        
        self.snippetTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                             target:self
                                                           selector:@selector(updateSnippet)
                                                           userInfo:nil repeats:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToExpire * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_snippetTimer invalidate];
            self.snippetTimer = nil;
            
            [_delegate needRemovePokemon:self];
        });
    }
    return self;
}

- (void)dealloc {
    
}

@end
