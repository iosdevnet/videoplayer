//
//  MyCommon.h
//  MoviePlayerPractice
//
//  Created by MA on 14-9-21.
//  Copyright (c) 2014年 ma. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyCommon : NSObject

//视频转MP4
+ (void)encodeVideoByUrl:(NSURL*)_videoURL ToUrl:(NSURL*)_mp4URL Quality:(NSString *const)quality Completion:(void (^)(BOOL isSuccess))completion;

@end
