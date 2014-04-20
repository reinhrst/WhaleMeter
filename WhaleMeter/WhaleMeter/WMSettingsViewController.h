//
//  WMSettingsViewController.h
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 20/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMSettingsViewController : UITableViewController
@property(nonatomic, retain) IBOutlet UISegmentedControl* coordinateSystemControl;
@property(nonatomic, retain) IBOutlet UISegmentedControl* maptypeControl;
@property(nonatomic, retain) IBOutlet UITextField* defaultEmail;
@property(nonatomic, retain) IBOutlet UITextField* defaultComment;
-(IBAction)somethingChanged:(id)sender;
@end
