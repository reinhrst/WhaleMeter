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
NSTimer* updateTimeoutView;
NSDate* lastLightUpdate;
NSString* locationLine;
NSString* lightLine;

#pragma mark view

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startStandardUpdates];
    mycentral = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
    self.map.delegate = self;
    updateTimeoutView = [NSTimer scheduledTimerWithTimeInterval: 1
                                                         target: self
                                                       selector: @selector(updateTimeoutView)
                                                       userInfo: nil
                                                        repeats: YES];
    [self showLocationInaccurateText:@"determining location" show:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showLastLightUpdateText:(NSString*)text show:(BOOL)show
{
    if (show) {
        self.lightLastUpdateLabel.text = text;
        self.lightLastUpdateLabel.hidden = NO;
        self.lightLastUpdateView.alpha = .2;
    } else {
        self.lightLastUpdateLabel.hidden = YES;
        self.lightLastUpdateView.alpha = 1;
    }
}

-(void)showLocationInaccurateText:(NSString*)text show:(BOOL)show
{
    if (show) {
        self.locationInaccurateLabel.text = text;
        self.locationInaccurateLabel.hidden = NO;
        self.locationInaccurateView.alpha = .4;
    } else {
        self.locationInaccurateLabel.hidden = YES;
        self.locationInaccurateView.alpha = 1;
    }
}

-(void)updateTimeoutView
{
    if (lastLightUpdate) {
        NSTimeInterval interval= -[lastLightUpdate timeIntervalSinceNow];
        if (interval > 5) {
            [self showLastLightUpdateText:[NSString stringWithFormat:@"Lost connection: %.0fs", interval]
                                     show:YES];
        } else {
            [self showLastLightUpdateText:nil show:NO];
        }
    } else {
        [self showLastLightUpdateText:@"No connection" show:YES];
    }
}

#pragma mark location and map

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        double x = location.coordinate.latitude;
        double y = location.coordinate.longitude;
        double z = location.altitude;
        WGS84toOSGB36(&x,&y,&z);
        [self.locationLabel setText:[NSString stringWithFormat:
                                     @"%.1f  %.1f",x, y]];
        if (location.horizontalAccuracy > 5) {
            [self showLocationInaccurateText:[NSString
                                              stringWithFormat:@"Inaccurate %.0fm",
                                              location.horizontalAccuracy]
                                        show:YES];
        } else {
            [self showLocationInaccurateText:nil show:NO];
        }
        locationLine = [NSString
                        stringWithFormat:@"%f,%f,%f,%f,%f,%f,%f%f",
                        location.coordinate.latitude,
                        location.coordinate.longitude,
                        location.altitude,
                        x,
                        y,
                        z,
                        location.horizontalAccuracy,
                        location.verticalAccuracy
                        ];
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

#pragma mark BLE

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        mycentral = central;
        [mycentral
         scanForPeripheralsWithServices:nil
         options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @1}];
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (![@"Whale" isEqualToString:[advertisementData valueForKey:@"kCBAdvDataLocalName"]]) {
        return;
    }
    NSData* data = [advertisementData valueForKey:@"kCBAdvDataManufacturerData"]; //keep reference
    const uint8_t* bytes = [data bytes] + 2;
    
    uint16_t uv = [self decodeBytes:bytes atPos: 0];
    uint16_t vis = [self decodeBytes:bytes atPos: 2];
    uint16_t ir = [self decodeBytes:bytes atPos: 4];
    uint16_t batt = [self decodeBytes:bytes atPos: 6];

    double lux = [self luxFromVisible:vis andIR:ir];
    if (lux == 999.0) {
        [self.luxLabel setText:@"> 1000"];
    } else {
        [self.luxLabel setText:[NSString stringWithFormat:@"%.3g", lux]];
    }
    [self.batteryLabel setText:[NSString stringWithFormat:@"%d", batt]];
    if (ir == 0xFFFF) {
        [self.IRLabel setText:[NSString stringWithFormat:@"> %d", 0xFFFF]];
    } else {
        [self.IRLabel setText:[NSString stringWithFormat:@"%d", ir]];
    }
    [self.UVLabel setText:[NSString stringWithFormat:@"%d", uv]];
    lastLightUpdate = [NSDate date];
    lightLine = [NSString stringWithFormat:@"%f,%d,%d",
                 lux,
                 ir,
                 uv
                 ];

}

// from datasheet: http://dlnmh9ip6v2uc.cloudfront.net/datasheets/Sensors/LightImaging/TSL2561.pdf
- (double)luxFromVisible:(uint16_t)vis andIR:(uint16_t)ir
{
    if (vis == 0) {
        return 0.0;
    }
    if (vis == 0xFFFF) {
        return 999.0;
    }
    double ch0 = (double) vis;
    double ch1 = (double) ir;
    double ratio = ch1 / ch0;
    double r;
    if (ratio < 0.5) {
        r = 0.0304 * ch0 - 0.062 * ch0 * pow(ch1/ch0,1.4);
    }
    else if (ratio < 0.61) {
        r = 0.0224 * ch0 - 0.031 * ch1;
    }
    else if (ratio < 0.80) {
        r = 0.0128 * ch0 - 0.0153 * ch1;
    }
    else if (ratio < 1.30) {
        r = 0.00146 * ch0 - 0.00112 * ch1;
    } else {
        r = 0.0;
    }
    return MIN(r, 999.0);
}

// some complex magic to retrieve all parts of the int
- (uint16_t) decodeBytes:(const uint8_t*) bytes atPos:(uint8_t) pos{
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


@end
