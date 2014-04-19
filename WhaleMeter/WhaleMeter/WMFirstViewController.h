//
//  WMFirstViewController.h
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 18/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMFirstViewController : UIViewController
@property(nonatomic, retain) IBOutlet UILabel *locationLabel;
@property(nonatomic, retain) IBOutlet UILabel *luxLabel;
@property(nonatomic, retain) IBOutlet UILabel *batteryLabel;
@property(nonatomic, retain) IBOutlet UILabel *IRLabel;
@property(nonatomic, retain) IBOutlet UILabel *UVLabel;
@end
