//
//  WMFileManager.h
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 20/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMFileManager : NSObject
+ (WMFileManager*)sharedInstance;
- (void) startNewLogfile;
- (void) writeLine:(NSString*)line withHeader:(NSString*)header;
-(NSArray*) getAllLogfileNames;
-(NSString*) getLogfileContent:(NSString*)filename;
-(void) writeFile:(NSString*) filename withData:(NSString*)data;
-(void) deleteFile:(NSString*) filename;
@end
