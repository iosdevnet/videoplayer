//
//  ViewController.m
//  MoviePlayerPractice
//
//  Created by MA on 14-9-21.
//  Copyright (c) 2014年 ma. All rights reserved.
//

#import "ViewController.h"
#import<MobileCoreServices/MobileCoreServices.h>
#import "MyCommon.h"
#import <AVFoundation/AVFoundation.h>
#import "MoviePlayer.h"

@interface ViewController ()
<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    UIImagePickerController *picker;
    IBOutlet MoviePlayer *player;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)play:(NSURL*)url
{
    [player stop];
    player.contentURL = url;
    [player play];
}

- (IBAction)shoot:(id)sender
{
    [self loadPicker];
    picker.sourceType= UIImagePickerControllerSourceTypeCamera;
    picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    //视频品质
    picker.videoQuality = UIImagePickerControllerQualityTypeIFrame960x540;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)selectFromAlbum:(id)sender
{
    [self loadPicker];
    picker.sourceType= UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)loadPicker
{
    if(!picker){
        picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.modalTransitionStyle= UIModalTransitionStyleCoverVertical;
        //媒体类型
        picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeMovie, nil];
        //是否允许编辑
        picker.allowsEditing = YES;
        //自带的
        //picker.showsCameraControls = NO;
        //picker.cameraOverlayView.hidden = NO;
    }
}

#pragma mark - UIImagePickerControllerDelegate
//临时文件
#define Temp_VideoPath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/tempVideo.mp4"]

- (void)imagePickerController:(UIImagePickerController *)_picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL *url = nil;
    if(picker.sourceType==UIImagePickerControllerSourceTypeCamera
       && picker.cameraCaptureMode==UIImagePickerControllerCameraCaptureModeVideo){
        //拍摄视频
        url = [info objectForKey:UIImagePickerControllerMediaURL];
    }else if(picker.sourceType==UIImagePickerControllerSourceTypeSavedPhotosAlbum){
        //选择视频
        url = [info objectForKey:UIImagePickerControllerReferenceURL];
    }
    if(!url){
        [picker dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    //转MP4
    NSURL *mp4URL = [NSURL fileURLWithPath:Temp_VideoPath];
    [MyCommon encodeVideoByUrl:url ToUrl:mp4URL Quality:AVAssetExportPreset960x540 Completion:^(BOOL isSuccess) {
        if(isSuccess){
            [picker dismissViewControllerAnimated:YES completion:^{
                [self play:mp4URL];
            }];
        }else{
            [picker dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)_picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
