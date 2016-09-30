//
//  ViewController.m
//  PhotoSync
//
//  Created by Hong on 9/29/16.
//  Copyright © 2016 Hong. All rights reserved.
//

#import "ViewController.h"
#import "DAVKit.h"

#define MINE_TYPE @{  \
      @"avi":@"video/x-msvideo",\
      @"mov":@"video/quicktime",\
      @"movie":@"video/x-sgi-movie",\
      @"mp3":@"audio/mpeg",\
      @"mpe":@"video/mpeg",\
      @"mpeg":@"video/mpeg",\
      @"mpg":@"video/mpeg",\
      @"mp4":@"video/mp4",\
      @"m4v":@"application/octet-stream" }


@interface ViewController ()<DAVRequestDelegate>
{
    
    PHFetchResult<PHAsset *> *videoAssets;
    PHFetchResult<PHAsset *> *images;
    PHFetchResult<PHAsset *> *audios;
    
    DAVSession *session;
    
    long  total;
    long  current;
    
}

@end

@implementation ViewController

-(NSString *)savePath
{
    NSString *name = [UIDevice currentDevice].name;
    if (name.length == 0) {
        name = [NSString stringWithFormat:@"%@%@",[UIDevice currentDevice].model,[UIDevice currentDevice].systemVersion];
    }

    return name;
}

-(void)initSession
{
    
    NSString *name   = [[NSUserDefaults standardUserDefaults] stringForKey:@"NAME"];
    NSString *passwd = [[NSUserDefaults standardUserDefaults] stringForKey:@"PASS"];
    NSString *server = [[NSUserDefaults standardUserDefaults] stringForKey:@"SERVER"];
    
    DAVCredentials *credentials = [DAVCredentials credentialsWithUsername:name password:passwd];
    NSString *root = server; // don't include the trailing / (slash)
    session = [[DAVSession alloc] initWithRootURL:[NSURL URLWithString:root] credentials:credentials];

    NSString *baseURL = [self savePath];
    NSString *dir = [NSString stringWithFormat:@"/%@",baseURL];
    [session enqueueRequest:[[DAVMakeCollectionRequest alloc] initWithPath:dir]];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    current = 0;
       
    [self checkPermission:^(BOOL result) {
        if (result) {
                
        }
    }];
    
    [self queryImages];

}


- (void)checkPermission:(void (^)(BOOL result))callback
{
   __block UIViewController *ctrl = self;
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        if(status == PHAuthorizationStatusDenied)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误提示" message:@"请打开相册读取权限" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [ctrl presentViewController:alert animated:YES completion:nil];
            
            if (callback) {
                callback(NO);
            }
        }
        if(status == PHAuthorizationStatusAuthorized)
        {
            [self queryImages];
            if (callback) {
                callback(YES);
            }
        }
        
    }];
}

+ (void)getImageFromPHAsset:(PHAsset *)asset Complete:(Result)result {
    __block NSData *data;
    PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:asset] firstObject];
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                          options:options
                                                    resultHandler:
         ^(NSData *imageData,
           NSString *dataUTI,
           UIImageOrientation orientation,
           NSDictionary *info) {
             data = [NSData dataWithData:imageData];
         }];
    }
    
    if (result) {
        if (data.length <= 0) {
            result(nil, nil);
        } else {
            result(data, resource.originalFilename);
        }
    }
}

+ (void)getVideoFromPHAsset:(PHAsset *)asset Complete:(Result)result {
    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
    PHAssetResource *resource;
    
    for (PHAssetResource *assetRes in assetResources) {
        if (assetRes.type == PHAssetResourceTypePairedVideo ||
            assetRes.type == PHAssetResourceTypeVideo) {
            resource = assetRes;
        }
    }
    NSString *fileName = @"tempAssetVideo.mov";
    if (resource.originalFilename) {
        fileName = resource.originalFilename;
    }
    
    if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        NSString *PATH_MOVIE_FILE = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE error:nil];
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
                                                                    toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE]
                                                                   options:nil
                                                         completionHandler:^(NSError * _Nullable error) {
                                                             if (error) {
                                                                 result(nil, nil);
                                                             } else {
                                                                 
                                                                 NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:PATH_MOVIE_FILE]];
                                                                 result(data, fileName);
                                                             }
                                                             [[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE  error:nil];
                                                         }];
    } else {
        result(nil, nil);
    }
}

+ (void)getVideoPathFromPHAsset:(PHAsset *)asset Complete:(ResultPath)result {
    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
    PHAssetResource *resource;
    
    for (PHAssetResource *assetRes in assetResources) { 
        if (assetRes.type == PHAssetResourceTypePairedVideo ||
            assetRes.type == PHAssetResourceTypeVideo) {
            resource = assetRes;
        }
    }
    NSString *fileName = @"tempAssetVideo.mov";
    if (resource.originalFilename) {
        fileName = resource.originalFilename;
    }
    
    if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        NSString *PATH_MOVIE_FILE = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE error:nil];
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
                                                                    toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE]
                                                                   options:nil
                                                         completionHandler:^(NSError * _Nullable error) {
                                                             if (error) {
                                                                 result(nil, nil);
                                                             } else {
                                                                 result(PATH_MOVIE_FILE, fileName);
                                                             }
                                                         }];
    } else {
        result(nil, nil);
    }
}


-(void)queryImages
{
    
    videoAssets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil]; 
    images = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil]; 
    audios = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeAudio options:nil]; 

    total = videoAssets.count+images.count+audios.count;
    
    NSString *info = [NSString stringWithFormat:@"共读取到 图片%lu张 视频%ld段 音频%ld段",(unsigned long)images.count,videoAssets.count,audios.count];
    [self updateMessage:nil info:info];
  
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)requestDidBegin:(DAVRequest *)aRequest
{
    NSString *name = [[aRequest.path componentsSeparatedByString:@"/"] lastObject];
    
    NSString *log = [NSString stringWithFormat:@"正在上传 %@",name];
    [self updateMessage:log info:nil];
}

- (void)request:(DAVRequest *)aRequest didFailWithError:(NSError *)error
{
    NSString *fileName = [[[aRequest path] componentsSeparatedByString:@"/"] lastObject];
   
    current++;
    double p = current/(total/1.0);
    
    NSString *log = [NSString stringWithFormat:@"文件 %@ 上传失败",fileName];
    [self updateMessage:log info:nil progess:p];
    
    
    [self uploadNext];
    
}

- (void)request:(DAVRequest *)aRequest didSucceedWithResult:(id)result
{
    current++;
    
    NSString *fileName = [[[aRequest path] componentsSeparatedByString:@"/"] lastObject];
    NSString *fileMD5 = [fileName md5];
    [self setUploaded:fileMD5 bol:YES];
    
    
    double p  = current/(total/1.0);
    NSString *log = [NSString stringWithFormat:@"文件 %@ 上传成功",fileName];
    NSString *info= [NSString stringWithFormat:@"已经上传%ld个，共%ld个,还剩下%ld个",current,total,total-current];
    [self updateMessage:log info:info progess:p];
    
    
    [self uploadNext];

}

-(void)updateMessage:(NSString *)log info:(NSString *)info progess:(double)progress
{
    dispatch_async(dispatch_get_main_queue(),^{
        
        if (log!= nil) {
            self.log.text = log;
        }
        if (info!=nil) {
            self.info.text =info;
        }
        
        if (progress!=0) {
            self.progress.progress = progress;
        }
        
        [self.view updateConstraints];
        [self.view updateConstraintsIfNeeded];
        [self.view layoutSubviews];
        
        if(log) NSLog(@"LOG:%@",log);
        if(info) NSLog(@"INFO:%@",info);

    });
}
-(void)updateMessage:(NSString *)log info:(NSString *)info
{
    [self updateMessage:log info:info progess:0];
}

- (IBAction)doSync:(UIButton*)sender {
    sender.enabled = NO;
    [self checkPermission:^(BOOL result) {
        sender.enabled = YES;
        if (result) {
            
            [self queryImages];
            if (total == 0) {
                self.info.text = @"没有新图片需要上传";
                return;
            }

            [self initSession];
            
            sender.enabled = NO;
            
            NSString *info = [NSString stringWithFormat:@"准备上传文件，共%ld个",total];
            [self updateMessage:nil info:info];

            
            current = 0;
            [self uploadNext];
            
            sender.enabled = YES;

        }}];
}

- (void)uploadNext
{
    
    if (current < images.count) {
        
        PHAsset *asset = [images objectAtIndex:current];
        
        [ViewController getImageFromPHAsset:asset Complete:^(NSData *fileData, NSString *fileName) {
            
            NSString *md5 = [fileName md5];
            
            if (![self ifUploaded:md5]) {
                
                NSString *saved = [NSString stringWithFormat:@"/%@/%@",[self savePath],fileName];
                DAVPutRequest *send = [[DAVPutRequest alloc] initWithPath:saved];
                send.data = fileData;
                send.delegate = self;
                NSString *type = [[[fileName componentsSeparatedByString:@"."] lastObject] lowercaseString];
                send.dataMIMEType = [NSString stringWithFormat:@"image/%@",type];
                [session enqueueRequest:send];
                
                NSString *log = [NSString stringWithFormat:@"正在上传上传 %@",fileName];
                [self updateMessage:log info:nil];

                
            }else{
                current++;
                double progress = current/(total/1.0);
                
                NSString *info = [NSString stringWithFormat:@"已经上传%ld个，共%ld个,还剩下%ld个",current,total,total-  current];
                NSString *log = [NSString stringWithFormat:@"文件%@已经上传，不需要再次传输",fileName];
                [self updateMessage:log info:info progess:progress];
                                
                [self uploadNext];
                
            }
        }];
        
    } else {
        
        long videoIndex = current - images.count;
        if (videoIndex < videoAssets.count) {
            
            PHAsset *asset = [videoAssets objectAtIndex:videoIndex];
            [ViewController getVideoFromPHAsset:asset Complete:^(NSData *fileData, NSString *fileName) {
                
                NSString *md5 = [fileName md5];
                
                if (fileData!=nil && ![self ifUploaded:md5]) {
                    
                    NSString *saved = [NSString stringWithFormat:@"/%@/%@",[self savePath],fileName];
                    DAVPutRequest *send = [[DAVPutRequest alloc] initWithPath:saved];
                    send.data = fileData;
                    send.delegate = self;
                    
                    NSString *type = [[[fileName componentsSeparatedByString:@"."] lastObject] lowercaseString];
                    NSString *typename = [MINE_TYPE objectForKey:type] ;
                    if (typename == nil) 
                    typename = @"application/octet-stream";
                    send.dataMIMEType = typename;
                    
                    [session enqueueRequest:send];
                    
                    NSString *log = [NSString stringWithFormat:@"正在上传上传 %@",fileName];
                    [self updateMessage:log info:nil];
                    
                }else{
                    
                    current++;
                    double progress = current/(total/1.0);
                    NSString *info = [NSString stringWithFormat:@"已经上传%ld个，共%ld个,还剩下%ld个",current,total,total-current];
                    NSString *log = [NSString stringWithFormat:@"文件%@已经上传，不需要再次传输",fileName];
                    [self updateMessage:log info:info progess:progress];
                    
                    [self uploadNext];

                }
                
            }];
            
        }
        
    }
        
}

-(NSString *)filePath
{
    NSArray<NSString *> *pahts = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [pahts objectAtIndex:0];
    NSString *file = [NSString stringWithFormat:@"%@/sync.data",dir];
    
    return file;
}

-(BOOL)ifUploaded:(NSString *)fileKey {
    
    NSData *fileData = [NSData dataWithContentsOfFile:[self filePath]];
    
    if(fileData == nil) return NO;
    
    NSError *error;  
    NSDictionary *weatherDic = [NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableLeaves error:&error];
    return [weatherDic objectForKey:fileKey] != nil;
}

-(void)setUploaded:(NSString *)fileKey bol:(BOOL)bol
{
    if (!bol) {
        return;
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:[self filePath]];
    NSError *error;  
    NSMutableDictionary *weatherDic = [NSMutableDictionary dictionary];
    if (fileData!=nil) {
        weatherDic = [[NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableLeaves error:&error] mutableCopy]; 
    }
    [weatherDic setValue:@"TRUE" forKey:fileKey];
    NSData *data = [NSJSONSerialization dataWithJSONObject:weatherDic options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:[self filePath] atomically:YES];
}

@end

@implementation NSString (md5)

- (NSString *) md5
{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG) strlen(cStr), result);
    NSMutableString *hash =[NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash uppercaseString];
}

@end
