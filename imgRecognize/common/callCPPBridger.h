//
//  callCPPBridger.h
//  FootballBook
//
//  Created by eric on 01/10/2016.
//  Copyright © 2016 王 逸平. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImgRecBridger : NSObject

+ (void) initImgRec:(NSString*)path;
+ (NSString*) getString:(NSString*)imgPath;


@end
