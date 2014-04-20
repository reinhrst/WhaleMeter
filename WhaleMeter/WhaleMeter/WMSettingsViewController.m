//
//  WMSettingsViewController.m
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 20/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import "WMSettingsViewController.h"
#import <Foundation/NSUserDefaults.h>

@interface WMSettingsViewController () <UITextFieldDelegate>

@end

@implementation WMSettingsViewController

NSUserDefaults* settings;

- (void)viewDidLoad
{
    [super viewDidLoad];
    settings = [NSUserDefaults standardUserDefaults];
    [self
     setDefault:[settings stringForKey:@"Coordinate System"]
     forSegmentedControl:self.coordinateSystemControl];
    
    [self
     setDefault:[settings stringForKey:@"Maptype"]
     forSegmentedControl:self.maptypeControl];
    self.defaultEmail.text = [settings stringForKey:@"Default Email"];
    self.defaultComment.text = [settings stringForKey:@"Default Comment"];
}

-(void)setDefault:(NSString*)value forSegmentedControl:(UISegmentedControl*)control
{
    for(unsigned int i =0; i < control.numberOfSegments; i++) {
        if ([value isEqualToString:[control titleForSegmentAtIndex:i]]) {
            control.selectedSegmentIndex=i;
        }
    }
}

-(IBAction)somethingChanged:(id)sender
{
    NSLog(@"change");
    [settings setObject:[self.coordinateSystemControl
                         titleForSegmentAtIndex:self.coordinateSystemControl.selectedSegmentIndex]
                 forKey:@"Coordinate System"];
    [settings setObject:[self.maptypeControl
                         titleForSegmentAtIndex:self.maptypeControl.selectedSegmentIndex]
                 forKey:@"Maptype"];
    [settings setObject:self.defaultEmail.text
                 forKey:@"Default Email"];
    [settings setObject:self.defaultComment.text
                 forKey:@"Default Comment"];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
