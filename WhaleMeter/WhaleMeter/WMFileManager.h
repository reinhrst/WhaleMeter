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
- (void) writeLine:(NSString*)line;
@end
