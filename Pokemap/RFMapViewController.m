//
//  RFMapViewController.m
//  Pokemap online
//
//  Created by Михаил on 19.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFMapViewController.h"
#import "RFAuthManager.h"
#import "RFNetworkManager.h"
#import "RFLocationManager.h"
#import <GoogleMaps/GoogleMaps.h>
#import "RFMapObjectsManager.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "RFAuthViewController.h"

@interface RFMapViewController () <RFLocationManagerDelegate, GMSMapViewDelegate, RFMapObjectsManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, assign) BOOL autocenter;
@property (nonatomic, strong) UIActivityIndicatorView *loaderView;
@end

@implementation RFMapViewController

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self tryLogin];
    }
}
- (void)logoutTap {
    [self showAuth];
}

- (void)newPokemonsReceived:(NSArray *)array {
    for (RFPokemonMarker *mark in array) {
        mark.map = _mapView;
    }
}

- (void)needRemovePokemonFromMap:(RFPokemonMarker *)marker {
    marker.map = nil;
}

- (void)showLoader {
    [UIView animateWithDuration:.3 animations:^{
        _loaderView.alpha = 1;
    }];
}

- (void)hideLoader {
    [UIView animateWithDuration:.3 animations:^{
        _loaderView.alpha = 0;
    }];
}

- (void)getMapObjects {
    [[RFMapObjectsManager instance] getMapObjectsWithCoordinate:[RFLocationManager instance].currentLocation.coordinate];
}

- (void)setAutocenter:(BOOL)autocenter {
    _autocenter = autocenter;
    
    if (_autocenter) {
        [_mapView animateToLocation:[RFLocationManager instance].currentLocation.coordinate];
    }
    
    _mapView.settings.myLocationButton = !_autocenter;
}
#pragma mark - Location Manager delegate

- (void)locationManager:(RFLocationManager *)manager didUpdateLocation:(CLLocation *)location {
    if (_autocenter) {
        [_mapView animateToLocation:location.coordinate];
    }
    
    //  [self generateRandom];
    [self getMapObjects];
}

#pragma mark - Map Delegate

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (gesture) {
        self.autocenter = NO;
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    if (GMSGeometryDistance(position.target, [RFLocationManager instance].currentLocation.coordinate) < 10) {
        self.autocenter = YES;
        
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    self.autocenter = NO;
    return NO;
}

#pragma make - View Controller Lifecycle

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = view;
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:[RFLocationManager instance].currentLocation.coordinate
                                                               zoom:16];
    
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    _mapView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _mapView.settings.indoorPicker = NO;
    _mapView.settings.rotateGestures = YES;
    _mapView.settings.myLocationButton = NO;
    _mapView.settings.scrollGestures = YES;
    _mapView.myLocationEnabled = YES;
    
    _mapView.settings.compassButton = YES;
    _mapView.delegate = self;
    _mapView.settings.allowScrollGesturesDuringRotateOrZoom = NO;
    _mapView.padding = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height + 22, 0, 0, 0);
    [_mapView setMinZoom:11 maxZoom:19];
    
    [self.view addSubview:_mapView];
    
    _loaderView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _loaderView.frame = CGRectMake((self.view.frame.size.width - 50) / 2, self.view.frame.size.height - 50 - 20, 50, 50);
    _loaderView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.2];
    _loaderView.layer.cornerRadius = 10;
    
    
    [_loaderView startAnimating];
    
    [self.view addSubview:_loaderView];
    
    [self setConstraints];
}

- (void)setConstraints {
    NSDictionary *metrics = @{};
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_mapView);
    
    //Horizontal layout
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"|[_mapView]|"
                               options:0
                               metrics:metrics
                               views:views]];
    
    //Vertical layout
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mapView]|"
                                                                      options:0
                                                                      metrics:metrics
                                                                        views:views]];
}

- (void)showAuth {
    [[UICKeyChainStore keyChainStore] setString:nil forKey:@"username"];
    [[UICKeyChainStore keyChainStore] setString:nil forKey:@"password"];
    
    RFAuthViewController *vc = [[RFAuthViewController alloc] initWithNibName:@"RFAuthViewController" bundle:[NSBundle mainBundle]];
    vc.completionBlock = ^(BOOL success) {
        [self tryLogin];
    };
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)tryLogin {
    RFAuthManager *man = [RFAuthManager instance];
    
    NSString *username = [[UICKeyChainStore keyChainStore] stringForKey:@"username"];
    NSString *password = [[UICKeyChainStore keyChainStore] stringForKey:@"password"];
    
    if (username.length > 0 && password.length > 0) {
        [man loginWithUsername:username
                      password:password
                     onSuccess:^{
                         [self hideLoader];
                         
                         [self getMapObjects];
                     }
                     onFailure:^(NSString *description){
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self hideLoader];
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login error"
                                                                             message:description
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"Close"
                                                                   otherButtonTitles:@"Retry", nil];
                             alert.delegate = self;
                             
                             [alert show];
                         });
                     }];
    } else {
        [self showAuth];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pokemap";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logout"]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(logoutTap)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
    self.autocenter = YES;
    
    [[RFLocationManager instance] setDelegate:self];
    
    RFMapObjectsManager *mapMan = [RFMapObjectsManager instance];
    mapMan.delegate = self;
    
    [self tryLogin];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
