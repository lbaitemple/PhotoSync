//
//  ViewController.h
//  PhotoSync
//
//  Created by Hong on 9/29/16.
//  Copyright © 2016 Hong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <CommonCrypto/CommonDigest.h>

typedef void(^Result)(NSData *fileData, NSString *fileName);
typedef void(^ResultPath)(NSString *filePath, NSString *fileName);

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *info;

@property (weak, nonatomic) IBOutlet UILabel *log;

@property (weak, nonatomic) IBOutlet UIButton *sync;

- (IBAction)doSync:(id)sender;

-(BOOL)ifUploaded:(NSString *)fileKey;
-(void)setUploaded:(NSString *)fileKey bol:(BOOL)bol;

+ (void)getImageFromPHAsset:(PHAsset *)asset Complete:(Result)result;
+ (void)getVideoFromPHAsset:(PHAsset *)asset Complete:(Result)result;

@end

@interface NSString (md5)
    - (NSString *) md5;
@end
