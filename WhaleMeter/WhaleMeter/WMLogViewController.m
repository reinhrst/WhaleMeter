//
//  WMSecondViewController.m
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 18/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import "WMLogViewController.h"
#import "WMFileManager.h"
#import "WMLogfileViewController.h"

@interface WMLogViewController () <UITableViewDataSource,UITableViewDelegate>

@end

@implementation WMLogViewController
NSArray* fileNames;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    NSArray* tempFilenames = [[WMFileManager sharedInstance] getAllLogfileNames];
    if ([tempFilenames count] != [fileNames count]) {
        fileNames = [[[tempFilenames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]
                     reverseObjectEnumerator] allObjects];
        [self.tableView reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [fileNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"LogfileCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [fileNames objectAtIndex:indexPath.row];
    return cell;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    WMLogfileViewController* logfileVC = (WMLogfileViewController* ) segue.destinationViewController;
    logfileVC.fileName = ((UITableViewCell*)sender).textLabel.text;
}

@end
