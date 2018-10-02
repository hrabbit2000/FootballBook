//
//  callCPPBridger.m
//  FootballBook
//
//  Created by eric on 01/10/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

#import "callCPPBridger.h"
#import "letterRecognize.h"


const char *gTest = "alert\(\\'[^\\]+";

@implementation ImgRecBridger

+ (void) initImgRec:(NSString*)path
{
    initImgRecognizer([path UTF8String]);
}

+ (NSString*) getString:(NSString*)imgPath
{
    const char* pStr = getStringFromImg([imgPath UTF8String]);
    return [NSString stringWithUTF8String:pStr];
}


@end
