//
//  WMLogfileViewController.h
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 21/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMLogfileViewController : UIViewController
@property(strong, nonatomic) NSString* fileName;
@property(strong, nonatomic) IBOutlet UITableView* tableView;
@property(strong, nonatomic) IBOutlet UIBarButtonItem* undoButton;
@property(nonatomic, retain) IBOutlet UIView *modalMaker;
@property(nonatomic, retain) IBOutlet UIView *commentBox;
@property(nonatomic, retain) IBOutlet UITextField *soundField;
@property(nonatomic, retain) IBOutlet UITextField *manualLightField;
@property(nonatomic, retain) IBOutlet UITextField *commentField;
@end
