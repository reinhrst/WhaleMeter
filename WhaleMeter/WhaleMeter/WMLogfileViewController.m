//
//  WMLogfileViewController.m
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 21/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import "WMLogfileViewController.h"
#import "WMFileManager.h"
#import <MessageUI/MFMailComposeViewController.h>

#define SOUND_FIELD_INDEX 13
#define MANUAL_LIGHT_FIELD_INDEX 14
#define COMMENT_FIELD_INDEX 15

@interface WMLogfileViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation WMLogfileViewController
NSMutableArray* lines;
UIActionSheet* clickActionSheet;
UIActionSheet* deleteFileActionSheet;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    clickActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:@"Delete"
                                          otherButtonTitles:@"Edit comment",nil];
    deleteFileActionSheet= [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:@"Delete File"
                                              otherButtonTitles:nil];

}

-(void) viewWillAppear:(BOOL)animated
{
    self.navigationItem.title = self.fileName;
    NSString* fileContent = [[WMFileManager sharedInstance] getLogfileContent:self.fileName];
    lines = [NSMutableArray arrayWithObject:[fileContent componentsSeparatedByString:@"\n"]];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[lines lastObject] count] - 2; // remove header, remove last empty line
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"LoglineCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    @try {
        NSString* line = [[lines lastObject] objectAtIndex:indexPath.row + 1]; // ignore header
        NSArray* parts = [line componentsSeparatedByString:@","];
        NSString* time = [parts[0] componentsSeparatedByString:@" "][1];
        double_t lux = [parts[1] doubleValue];
        NSString* sound = parts[SOUND_FIELD_INDEX];
        NSString* manualLight = parts[MANUAL_LIGHT_FIELD_INDEX];
        NSString* comments = parts[COMMENT_FIELD_INDEX];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %.3g lx %@ %@ %@", time, lux, sound, manualLight, comments];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        cell.textLabel.text=@"#ERROR#";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [clickActionSheet showInView:self.view];
}

- (void)checkEnableUndoButton
{
    self.undoButton.enabled = ([lines count] > 1);
}

-(IBAction)undo:(id)sender
{
    if ([lines count] > 1) {
        [lines removeLastObject];
    }
    [self.tableView reloadData];
    [self writeFile];
    [self checkEnableUndoButton];
}

-(IBAction)deleteFileButtonPress:(id)sender
{
    [deleteFileActionSheet showInView:self.view];
}

-(void) writeFile
{
    [[WMFileManager sharedInstance] writeFile:self.fileName withData:[[lines lastObject] componentsJoinedByString:@"\n"]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == clickActionSheet) {
        NSInteger indexInArray = self.tableView.indexPathForSelectedRow.row + 1; //ignore header
        switch(buttonIndex) {
            case 0: /*delete*/
            {
                NSArray* startLines = [[lines lastObject] subarrayWithRange:NSMakeRange(0, indexInArray)];
                NSArray* endLines =   [[lines lastObject]
                                       subarrayWithRange:NSMakeRange(
                                                                     indexInArray+1,
                                                                     [[lines lastObject] count] - (indexInArray + 1))];
                [lines addObject:[startLines arrayByAddingObjectsFromArray:endLines]];
                [self.tableView reloadData];
                [self writeFile];
                [self checkEnableUndoButton];
                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
                break;
            }
            case 1: /* edit */
            {
                self.modalMaker.hidden = NO;
                self.commentBox.hidden = NO;
                NSString* line = [lines lastObject][indexInArray];
                NSArray* parts = [line componentsSeparatedByString:@","];
                NSString* sound = parts[SOUND_FIELD_INDEX];
                NSString* manualLight = parts[MANUAL_LIGHT_FIELD_INDEX];
                NSString* comments = parts[COMMENT_FIELD_INDEX];
                self.soundField.text = sound;
                self.manualLightField.text = manualLight;
                self.commentField.text = comments;
                [self.soundField becomeFirstResponder];
                break;
            }
            case 3: /*cancel*/
            {
                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
                break;
            }
        }
    } else {
        if (buttonIndex == 0) {
            [[WMFileManager sharedInstance] deleteFile:self.fileName];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

-(IBAction)editCommentCancel:(id)sender
{
    self.modalMaker.hidden = YES;
    self.commentBox.hidden = YES;
    [self.soundField resignFirstResponder];
    [self.manualLightField resignFirstResponder];
    [self.commentField resignFirstResponder];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
}

-(IBAction)editCommentSubmit:(id)sender
{
    NSInteger indexInArray = self.tableView.indexPathForSelectedRow.row + 1; //ignore header
    NSString* line = [lines lastObject][indexInArray]; //ignore header
    NSArray* parts = [line componentsSeparatedByString:@","];
    NSArray* partsWeKeep = [parts subarrayWithRange:NSMakeRange(0, SOUND_FIELD_INDEX)];
    NSArray* toAdd = @[
                    [self.soundField.text stringByReplacingOccurrencesOfString:@"," withString:@"."],
                    [self.manualLightField.text stringByReplacingOccurrencesOfString:@"," withString:@"."],
                    [self.commentField.text stringByReplacingOccurrencesOfString:@"," withString:@"."]];
    NSArray* newparts = [partsWeKeep arrayByAddingObjectsFromArray: toAdd];
    NSString* newline = [newparts componentsJoinedByString:@","];

    NSMutableArray* newlines = [[lines lastObject] mutableCopy];
    [newlines replaceObjectAtIndex:indexInArray withObject:newline];
    [lines addObject:[NSArray arrayWithArray:newlines]];
    [self.tableView reloadData];
    [self writeFile];
    [self checkEnableUndoButton];
    [self editCommentCancel:sender];
}

-(IBAction)sendByEmail:(id)sender
{
    MFMailComposeViewController* mailViewController = [MFMailComposeViewController new];
    mailViewController.mailComposeDelegate = self;
    NSString* to = [[NSUserDefaults standardUserDefaults] stringForKey:@"Default Email"];
    [mailViewController setToRecipients:[to componentsSeparatedByString:@","]];
    [mailViewController setSubject:[NSString stringWithFormat:@"Whalemeter: %@", self.fileName]];
    NSData* data = [[[WMFileManager sharedInstance] getLogfileContent:self.fileName]
                    dataUsingEncoding:NSUTF8StringEncoding];
    [mailViewController addAttachmentData:data mimeType:@"text/csv" fileName:self.fileName];
    [self presentViewController:mailViewController animated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
