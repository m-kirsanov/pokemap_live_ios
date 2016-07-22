//
//  RFLocationManager.h
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@class RFLocationManager;

@protocol RFLocationManagerDelegate

- (void)locationManager:(RFLocationManager *)manager didUpdateLocation:(CLLocation *)location;

@end

@interface RFLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak) id<RFLocationManagerDelegate> delegate;
@property (nonatomic, strong) CLLocation *currentLocation;

+ (RFLocationManager *)instance;

- (void)setupLocationManager;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
