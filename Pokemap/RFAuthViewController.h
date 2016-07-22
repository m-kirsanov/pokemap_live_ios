//
//  RFAuthViewController.h
//  Pokemap
//
//  Created by Михаил on 22.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^RFAuthViewControllerCompletion)(BOOL success);

@interface RFAuthViewController : UIViewController

@property (nonatomic, strong) RFAuthViewControllerCompletion completionBlock;

@end
