//
//  AppDelegate.m
//  iBeacons
//
//  Created by Nilam on 6/20/15.
//
//

#import "AppDelegate.h"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize locationManager;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self askPermissionForLocationAceess];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], nil]];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"inBackground"];
    
    [self startBeaconScanning];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    //set flag to inform the app is in background.
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"inBackground"];
    
    //call backgroundTaskWithExpirationHandler block to allow app background scanning.
    NSLog(@"=== DID ENTER BACKGROUND ===");
    UIBackgroundTaskIdentifier bgTask = [[UIApplication  sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"End of tolerate time. Application should be suspended now if we do not ask more 'tolerance'");
    }];
    
    if (bgTask == UIBackgroundTaskInvalid) {
        NSLog(@"This application does not support background mode");
    } else {
        //if application supports background mode, we'll see this log.
        NSLog(@"Application will continue to run in background");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"inBackground"];
    NSLog(@"=== GOING BACK FROM IDLE MODE ===");
    //it’s important to stop background task when we do not need it anymore
    [[UIApplication sharedApplication] endBackgroundTask:UIBackgroundTaskInvalid];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)askPermissionForLocationAceess {
    locationManager = [[CLLocationManager alloc] init];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [locationManager requestWhenInUseAuthorization];
        [locationManager requestAlwaysAuthorization];
    }
    
    locationManager.distanceFilter = kCLDistanceFilterNone; // whenever we move
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 m
    [locationManager startUpdatingLocation];
}

-(void)startBeaconScanning
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Code in this part is run on a background thread
        [self initRegion];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            //Code here is run on the main thread
            
        });
    });
}
- (void)initRegion {
    //assign here your beacon's UUID and the identifier you want to.
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B432ACEB-2362-7121-B550-AF2186EFF7C9"];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"MyBeacon"];
    self.beaconRegion.notifyOnEntry = YES;
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}


-(void)stopBeaconScanning
{
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [self.locationManager requestStateForRegion:self.beaconRegion];
}

- (void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
        {
            NSLog(@"Region inside");
            [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        }
            break;
        case CLRegionStateOutside:
            NSLog(@"Region outside");
            break;
        case CLRegionStateUnknown:
            NSLog(@"Region unknown");
            break;
        default:
            NSLog(@"Region unknown");
            [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    //If your app is already in background and device is in sleep mode, the background scannning may stopped,hence start background scanning again, call below block-
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"inBackground"])
    {
        NSLog(@"=== DID ENTER BACKGROUND ===");
        UIBackgroundTaskIdentifier bgTask = [[UIApplication  sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"End of tolerate time. Application should be suspended now if we do not ask more 'tolerance'");
            [[UIApplication sharedApplication] endBackgroundTask:UIBackgroundTaskInvalid];
        }];
        if (bgTask == UIBackgroundTaskInvalid) {
            NSLog(@"This application does not support background mode");
        } else {
            //if application supports background mode, we'll see this log.
            NSLog(@"Application will continue to run in background");
        }
    }
    
    //schedule local notification to awake the device if in sleep mode.
    [self scheduleNotificationOn:[NSDate dateWithTimeIntervalSinceNow:1]
                            text:@"Entered in beacon region"
                          action:@"View"
                           sound:nil
                     launchImage:nil
                         andInfo:nil];
    
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    [self scheduleNotificationOn:[NSDate dateWithTimeIntervalSinceNow:1]
                            text:@"Exit the beacon region"
                          action:@"View"
                           sound:nil
                     launchImage:nil
                         andInfo:nil];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    for(CLBeacon *beacon in beacons)
    {
        NSLog(@"%@",[NSString stringWithFormat:@"Detected beacon properties: major= %@,minor = %@, rssi = %ld",beacon.major,beacon.minor,(long)beacon.rssi]);
    }
}

//schedule local notification.
- (void) scheduleNotificationOn:(NSDate*) fireDate
                           text:(NSString*) alertText
                         action:(NSString*) alertAction
                          sound:(NSString*) soundfileName
                    launchImage:(NSString*) launchImage
                        andInfo:(NSDictionary*) userInfoDict

{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = fireDate;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    
    localNotification.alertBody = alertText;
    localNotification.alertAction = alertAction;
    
    if(soundfileName == nil)
    {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    else
    {
        localNotification.soundName = soundfileName;
    }
    
    localNotification.userInfo = userInfoDict;
    
    // Schedule it with the app
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}


@end
