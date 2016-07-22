//
//  s2geometry.h
//  s2geometry
//
//  Created by Михаил on 20.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface s2geometry : NSObject

+ (NSArray *)cellsForCoordinate:(CLLocationCoordinate2D)coordinate;
+ (CLLocationCoordinate2D)coordinateForCellId:(unsigned long long)numCellId;

@end
