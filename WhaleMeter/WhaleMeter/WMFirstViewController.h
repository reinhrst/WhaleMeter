//
//  WMFirstViewController.h
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 18/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface WMFirstViewController : UIViewController
@property(nonatomic, retain) IBOutlet UILabel *locationLabel;
@property(nonatomic, retain) IBOutlet UILabel *luxLabel;
@property(nonatomic, retain) IBOutlet UILabel *batteryLabel;
@property(nonatomic, retain) IBOutlet UILabel *IRLabel;
@property(nonatomic, retain) IBOutlet UILabel *UVLabel;
@property(nonatomic, retain) IBOutlet UIView *lightLastUpdateView;
@property(nonatomic, retain) IBOutlet UILabel *lightLastUpdateLabel;
@property(nonatomic, retain) IBOutlet UIView *locationInaccurateView;
@property(nonatomic, retain) IBOutlet UILabel *locationInaccurateLabel;
@property(nonatomic, retain) IBOutlet MKMapView *map;
@end
