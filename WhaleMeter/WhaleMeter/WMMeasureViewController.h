//
//  WMFirstViewController.h
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 18/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface WMMeasureViewController : UIViewController
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
@property(nonatomic, retain) IBOutlet UIView *modalMaker;
@property(nonatomic, retain) IBOutlet UIView *commentBox;
@property(nonatomic, retain) IBOutlet UITextField *soundField;
@property(nonatomic, retain) IBOutlet UITextField *manualLightField;
@property(nonatomic, retain) IBOutlet UITextField *commentField;
@end
