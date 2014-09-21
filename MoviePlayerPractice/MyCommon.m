//
//  MyCommon.m
//  MoviePlayerPractice
//
//  Created by MA on 14-9-21.
//  Copyright (c) 2014年 ma. All rights reserved.
//

#import "MyCommon.h"
#import <AVFoundation/AVFoundation.h>

@implementation MyCommon

//视频转MP4
+ (void)encodeVideoByUrl:(NSURL*)_videoURL ToUrl:(NSURL*)_mp4URL Quality:(NSString *const)quality Completion:(void (^)(BOOL isSuccess))completion
{
    if(!_videoURL){
        if(completion)
            completion(NO);
    }
    if([[NSFileManager defaultManager] removeItemAtURL:_mp4URL error:nil]){
        NSLog(@"Delete old MP4 Successful!");
    }
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:_videoURL options:nil];
    CMTime assetTime = [avAsset duration];
    Float64 duration = CMTimeGetSeconds(assetTime);
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    NSString *mQuality;
    if(quality.length)
        mQuality = quality;
    else
        mQuality = AVAssetExportPresetMediumQuality;
    if ([compatiblePresets containsObject:mQuality])
    {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:mQuality];
        
        exportSession.outputURL = _mp4URL;
        exportSession.shouldOptimizeForNetworkUse = YES;
        //格式
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        //视频截取
//        CMTime start = CMTimeMakeWithSeconds(0.0, avAsset.duration.timescale);
//        float trimDuration = 10.0;
//        if(trimDuration>duration){
//            trimDuration = duration;
//        }
//        CMTime cmDuration = CMTimeMakeWithSeconds(trimDuration, avAsset.duration.timescale);
//        CMTimeRange range = CMTimeRangeMake(start, cmDuration);
//        exportSession.timeRange = range;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:{
                    NSLog(@"Convert to MP4 Failed!");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(completion)
                            completion(NO);
                    });
                }
                    break;
                case AVAssetExportSessionStatusCancelled:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(completion)
                            completion(NO);
                    });
                }
                    break;
                case AVAssetExportSessionStatusCompleted:{
                    NSLog(@"Convert to MP4 Successful!");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(completion)
                            completion(YES);
                    });
                }
                    break;
                default:
                    break;
            }
        }];
    }
    else
    {
        NSLog(@"AVAsset doesn't support mp4 quality");
    }
}

@end
