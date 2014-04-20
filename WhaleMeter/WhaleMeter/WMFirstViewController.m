//
//  WMFirstViewController.m
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 18/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import "WMFirstViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBCentralManager.h>
#import <MapKit/MapKit.h>
#import "conversion.h"
#import "math.h"
#import "stdlib.h"


struct manufacturerdata {
    uint16_t _void;
    uint16_t uv;
    uint16_t vis;
    uint16_t ir;
    uint16_t batt;
};

@interface WMFirstViewController () <CLLocationManagerDelegate,CBCentralManagerDelegate,MKMapViewDelegate>

@end

@implementation WMFirstViewController

CLLocationManager* locationManager;
CBCentralManager* mycentral;
NSTimer* mapBackToFollowingModeTimer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startStandardUpdates];
    mycentral = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    self.map.delegate = self;

	// Do any additional setup after loading the view, typically from a nib.
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        mycentral = central;
        [mycentral
         scanForPeripheralsWithServices:nil
         options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @1}];
    }
}


// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        double x = location.coordinate.latitude;
        double y = location.coordinate.longitude;
        WGS84toOSGB36(&x,&y);
        [self.locationLabel setText:[NSString stringWithFormat:
                                     @"%.1f  %.1f",x, y]];
    }
}

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    [self.map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [mapView setUserTrackingMode:MKUserTrackingModeNone];
    if (mapBackToFollowingModeTimer) {
        [mapBackToFollowingModeTimer invalidate];
    }
    mapBackToFollowingModeTimer = [NSTimer scheduledTimerWithTimeInterval: 20
                                                          target: self
                                                        selector: @selector(mapTimerFire)
                                                        userInfo: nil
                                                         repeats: NO];
}

- (void) mapTimerFire {
    [self.map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}

- (void)startStandardUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];
}

// some complex magic to retrieve all parts of the int
uint16_t decode(const uint8_t* bytes, uint8_t pos){
    uint16_t val = bytes[pos] | ((uint16_t) bytes[pos+1]) << 8;
    uint8_t correction = bytes[8];
    if (!((correction >> (7-pos)) & 1)) {
        val ^= 0x1;
    }
    if (!((correction >> (6-pos)) & 1)) {
        val ^= 0x100;
    }
    return val;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    const uint8_t* data = [[advertisementData valueForKey:@"kCBAdvDataManufacturerData"] bytes];
    
    uint16_t uv = decode(data+2, 0);
    uint16_t vis = decode(data+2, 2);
    uint16_t ir = decode(data+2, 4);
    uint16_t batt = decode(data+2, 6);

    double lux = [self luxFromVisible:vis andIR:ir];
    [self.luxLabel setText:[NSString stringWithFormat:@"%.4g", lux]];
    [self.batteryLabel setText:[NSString stringWithFormat:@"%d", batt]];
    [self.IRLabel setText:[NSString stringWithFormat:@"%d", ir]];
    [self.UVLabel setText:[NSString stringWithFormat:@"%d", uv]];
}

// from datasheet: http://dlnmh9ip6v2uc.cloudfront.net/datasheets/Sensors/LightImaging/TSL2561.pdf
- (double)luxFromVisible:(uint16_t)vis andIR:(uint16_t)ir
{
    if (vis == 0) {
        return 0.0;
    }
    double ch0 = (double) vis;
    double ch1 = (double) ir;
    double ratio = ch1 / ch0;
    if (ratio < 0.5) {
        return 0.0304 * ch0 - 0.062 * ch0 * pow(ch1/ch0,1.4);
    }
    if (ratio < 0.61) {
        return 0.0224 * ch0 - 0.031 * ch1;
    }
    if (ratio < 0.80) {
        return 0.0128 * ch0 - 0.0153 * ch1;
    }
    if (ratio < 1.30) {
        return 0.00146 * ch0 - 0.00112 * ch1;
    }
    return 0.0;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
