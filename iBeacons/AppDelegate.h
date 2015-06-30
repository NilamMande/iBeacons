//
//  AppDelegate.h
//  iBeacons
//
//  Created by Nilam on 6/20/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;

-(void)startBeaconScanning;
-(void)stopBeaconScanning;

@end

