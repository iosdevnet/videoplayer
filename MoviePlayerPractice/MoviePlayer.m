//
//  MoviePlayer.m
//  MoviePlayerPractice
//
//  Created by MA on 14-9-21.
//  Copyright (c) 2014年 ma. All rights reserved.
//

#import "MoviePlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "XLoader.h"

#define thumbnailLoadKey @"thumbnailLoadKey"

@interface MoviePlayer()
{
    MPMoviePlayerController *player;
    UIButton *playBtn;
    UIImageView *thumbnail;
    XLoader *xLoader;
}

@end

@implementation MoviePlayer
@synthesize delegate;

- (void) initialize
{
    CGRect frame = self.frame;
    // Initialization code
    player = [[MPMoviePlayerController alloc] init];
    player.controlStyle = MPMovieControlStyleNone;
    player.scalingMode = MPMovieScalingModeAspectFill;
    [self addSubview:player.view];
    player.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    //缩略图
    thumbnail = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    thumbnail.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:thumbnail];
    //播放按钮
    playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [playBtn setImage:[UIImage imageNamed:@"video_play_blue"] forState:UIControlStateNormal];
    playBtn.frame = CGRectMake(0, 0, 100, 100);
    playBtn.center = CGPointMake(frame.size.width/2, frame.size.height/2);
    [self addSubview:playBtn];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initialize];
    }
    return self;
}

- (NSURL*)contentURL
{
    return player.contentURL;
}

- (void)setContentURL:(NSURL *)url
{
    player.contentURL = url;
    [[XLoader loader] cancelLoadingObjectByKey:thumbnailLoadKey];
    if(url){
        [[XLoader loader] load:^id{
            UIImage *thumImage = [self getThumbnailImage:url];
            dispatch_async(dispatch_get_main_queue(), ^{
                thumbnail.image = thumImage;
            });
            return thumImage;
        } forKey:thumbnailLoadKey];
    }
}

//播放按钮隐藏
- (void)playBtnHidden:(BOOL)hidden
{
    playBtn.hidden = hidden;
    thumbnail.hidden = hidden;
}

#pragma mark - Action
- (void)playBtnClicked:(id)sender
{
    [self play];
}

- (void)play
{
    if(player.playbackState==MPMoviePlaybackStateStopped
       ||player.playbackState==MPMoviePlaybackStatePaused
       ||player.playbackState==MPMoviePlaybackStateInterrupted){
        [player play];
    }
}

- (void)pause
{
    if(player.playbackState==MPMoviePlaybackStatePlaying
       ||player.playbackState==MPMoviePlaybackStateSeekingForward
       ||player.playbackState==MPMoviePlaybackStateSeekingBackward){
        [player pause];
    }
}

- (void)stop
{
    if(player.playbackState==MPMoviePlaybackStatePlaying
       ||player.playbackState==MPMoviePlaybackStateSeekingForward
       ||player.playbackState==MPMoviePlaybackStateSeekingBackward
       ||player.playbackState==MPMoviePlaybackStatePaused){
        [player stop];
    }
}

#pragma mark - Notification

- (void)didMoveToWindow
{
    if(self.window){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:player];
        //时间进度条
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationAvailable:) name:MPMovieDurationAvailableNotification object:player];
    }else{
        [self stop];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

//加载状态改变
- (void)movieLoadStateDidChange:(NSNotification *)note {
    switch (player.loadState) {
        case MPMovieLoadStatePlayable:
        case MPMovieLoadStatePlaythroughOK:
            //
            //[self showControls:nil];
            break;
        case MPMovieLoadStateStalled:
        case MPMovieLoadStateUnknown:
            break;
        default:
            break;
    }
}

//播放状态改变
- (void)moviePlaybackStateDidChange:(NSNotification *)note {
    switch (player.playbackState) {
        case MPMoviePlaybackStatePlaying:
        case MPMoviePlaybackStateSeekingBackward:
        case MPMoviePlaybackStateSeekingForward:
            //播放状态
            //self.state = ALMoviePlayerControlsStateReady;
            [self playBtnHidden:YES];
            break;
        case MPMoviePlaybackStateInterrupted:
            //加载中
            //self.state = ALMoviePlayerControlsStateLoading;
            break;
        case MPMoviePlaybackStatePaused:
        case MPMoviePlaybackStateStopped:
            //闲置
            //self.state = ALMoviePlayerControlsStateIdle;
            [self playBtnHidden:NO];
            break;
        default:
            break;
    }
}

//播放结束通知
- (void)movieFinished:(NSNotification *)note
{
    if(delegate && [delegate respondsToSelector:@selector(moviePlayerPlaybackDidFinish)]){
        [delegate moviePlayerPlaybackDidFinish];
    }
}

#pragma mark -
-(UIImage *)getThumbnailImage:(NSURL *)videoURL
{
    if(![videoURL isFileURL]){
        return nil;
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 60);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}

@end
