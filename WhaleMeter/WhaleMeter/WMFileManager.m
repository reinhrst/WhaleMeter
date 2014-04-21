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
    [self startNewLogfile];
    return self;
}

- (void) startNewLogfile {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH.mm.ss.'csv'"];
    activeFilename = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:[formatter stringFromDate:[NSDate date]]];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (void) writeLine:(NSString*)line withHeader:(NSString* ) header
{
    NSFileHandle* file;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:activeFilename]) {
        NSData* headerData = [[NSString stringWithFormat:@"%@\n", header]
                              dataUsingEncoding:NSUTF8StringEncoding];
        [fileManager createFileAtPath:activeFilename contents:headerData attributes:nil];
    }
    file = [NSFileHandle fileHandleForWritingAtPath:activeFilename];
    [file seekToEndOfFile];
    [file writeData:[[NSString stringWithFormat:@"%@\n", line]
                           dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

-(NSArray*) getAllLogfileNames
{
    return [[NSFileManager defaultManager]
                contentsOfDirectoryAtPath:[self applicationDocumentsDirectory].path
                                    error:NULL];
}

-(NSArray*) getLogfileLines:(NSString*)filename
{
    NSString* path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent: filename];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return @[];
    }
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    return [fileContents componentsSeparatedByString:@"\n"];
}

-(void) deleteFile:(NSString*) filename
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent: filename];
    [fileManager removeItemAtPath:path error:NULL];
}

-(void) writeFile:(NSString*) filename withData:(NSString*)string {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* path = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent: filename];

    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:NULL];
    }
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    [fileManager createFileAtPath:activeFilename contents:data attributes:nil];
}


@end
