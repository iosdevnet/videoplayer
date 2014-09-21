//
//  MoviePlayer.h
//  MoviePlayerPractice
//
//  Created by MA on 14-9-21.
//  Copyright (c) 2014年 ma. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MoviePlayerDelegate <NSObject>

- (void)moviePlayerPlaybackDidFinish;

@end

@interface MoviePlayer : UIView

@property (nonatomic, copy) NSURL *contentURL;

@property (nonatomic, weak) id<MoviePlayerDelegate> delegate;

- (void)play;

- (void)pause;

- (void)stop;

@end
