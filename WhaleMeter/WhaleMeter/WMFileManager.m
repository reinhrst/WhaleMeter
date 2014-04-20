//
//  WMFileManager.m
//  WhaleMeter
//
//  Created by Reinoud Elhorst on 20/04/2014.
//  Copyright (c) 2014 Reinoud Elhorst. All rights reserved.
//

#import "WMFileManager.h"

@implementation WMFileManager
NSString* activeFilename;
NSFileHandle *activeFile;

+ (WMFileManager*)sharedInstance
{
    static WMFileManager* _sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[WMFileManager alloc] init];
    });
    return _sharedInstance;
}

-(id) init
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH.mm.ss.'csv'"];
    activeFilename = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:[formatter stringFromDate:[NSDate date]]];
    NSLog(@"%@", activeFilename);
    return self;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (void) writeLine:(NSString*)line
{
    if(!activeFile) {
        [[NSFileManager defaultManager] createFileAtPath:activeFilename contents:nil attributes:nil];
        activeFile = [NSFileHandle fileHandleForWritingAtPath:activeFilename];
        [activeFile writeData:[
        @"date,lux,visible,ir,uv,"
                               "WGS84_lat,WGS84_lon,WGS84_alt,"
                               "OSGB36_northing,OSGB36_easting,OSGB36_altitude,"
                               "accuracy_horizontal,accuracy_vertical,comments"
                               dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [activeFile writeData:[[NSString stringWithFormat:@"%@\n", line]
                           dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
