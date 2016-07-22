//
//  RFLocationManager.m
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFLocationManager.h"

@interface RFLocationManager () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation RFLocationManager

+ (RFLocationManager *)instance {
    static RFLocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        [self setupLocationManager];
    }
    return self;
}

- (void)setupLocationManager {
    self.locationManager                    = [[CLLocationManager alloc] init];
    self.locationManager.delegate           = self;
    self.locationManager.desiredAccuracy    = kCLLocationAccuracyBestForNavigation;
    self.locationManager.distanceFilter     = kCLDistanceFilterNone;
    self.locationManager.activityType       = CLActivityTypeFitness;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    
    [self.locationManager startUpdatingLocation];
}

- (CLLocation *)currentLocation {
    if (_currentLocation.coordinate.longitude == 0 && _currentLocation.coordinate.latitude == 0) {
        return nil;
    } else {
        return _currentLocation;
    }
}
#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *currentLocation = locations.firstObject;
        
    if (currentLocation == nil) {
        return;
    }
    self.currentLocation = currentLocation;
   
    [_delegate locationManager:self didUpdateLocation:currentLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error);
}

- (void)startUpdatingLocation {
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

@end
