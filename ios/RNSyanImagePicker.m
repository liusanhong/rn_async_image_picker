
#import "RNSyanImagePicker.h"
#import "TZImagePickerController.h"
#import <AVFoundation/AVFoundation.h>
#import "TZImageManager.h"
#import "NSDictionary+SYSafeConvert.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <React/RCTUtils.h>


@interface RNSyanImagePicker ()

@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (nonatomic, strong) NSDictionary *cameraOptions;
/**
 保存Promise的resolve block
 */
@property (nonatomic, copy) RCTPromiseResolveBlock resolveBlock;
/**
 保存Promise的reject block
 */
@property (nonatomic, copy) RCTPromiseRejectBlock rejectBlock;
/**
 保存回调的callback
 */
@property (nonatomic, copy) RCTResponseSenderBlock callback;
/**
 保存选中的图片数组
 */
@property (nonatomic, strong) NSMutableArray *selectedAssets;


@end

@implementation RNSyanImagePicker

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedAssets = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    _selectedAssets = nil;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(showImagePicker:(NSDictionary *)options
                  callback:(RCTResponseSenderBlock)callback) {
    self.cameraOptions = options;
    self.callback = callback;
    self.resolveBlock = nil;
    self.rejectBlock = nil;
    [self openImagePicker];
}

RCT_REMAP_METHOD(asyncShowImagePicker,
                 options:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    self.cameraOptions = options;
    self.resolveBlock = resolve;
    self.rejectBlock = reject;
    self.callback = nil;
    [self openImagePicker];
}

RCT_REMAP_METHOD(asyncOpenCamera,
                 options:(NSDictionary *)options
                 resolve:(RCTPromiseResolveBlock)resolve
                 rejecte:(RCTPromiseRejectBlock)reject) {
    self.cameraOptions = options;
    self.resolveBlock = resolve;
    self.rejectBlock = reject;
    self.callback = nil;
    [self openVideoPicker];
//    [self openImagePicker];
}

RCT_EXPORT_METHOD(openCamera:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback) {
    self.cameraOptions = options;
    self.callback = callback;
    self.resolveBlock = nil;
    self.rejectBlock = nil;
    [self takePhoto];
}

RCT_EXPORT_METHOD(deleteCache) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath: [NSString stringWithFormat:@"%@ImageCaches", NSTemporaryDirectory()] error:nil];
}

RCT_EXPORT_METHOD(removePhotoAtIndex:(NSInteger)index) {
    if (self.selectedAssets && self.selectedAssets.count > index) {
        [self.selectedAssets removeObjectAtIndex:index];
    }
}

RCT_EXPORT_METHOD(removeAllPhoto) {
    if (self.selectedAssets) {
        [self.selectedAssets removeAllObjects];
    }
}


- (void)openVideoPicker
{
    [[self topViewController] presentViewController:self.imagePicker animated:YES completion:nil];
}

- (UIImagePickerController *)imagePicker
{
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        _imagePickerVc.sourceType = UIImagePickerControllerSourceTypeCamera;    //设置来源为摄像头
        _imagePickerVc.cameraDevice = UIImagePickerControllerCameraDeviceRear; //设置使用的摄像头为：后置摄像头
        
        _imagePickerVc.mediaTypes = @[(NSString *)kUTTypeMovie];
        
        //        _imagePicker.mediaTypes = @[(NSString *)kUTTypeVideo];    //设置为视频模式-<span style="color: rgb(51, 51, 51); font-family: Georgia, 'Times New Roman', Times, sans-serif; font-size: 14px; line-height: 25px;">注意媒体类型定义在MobileCoreServices.framework中</span>
        _imagePickerVc.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;   //设置视频质量
        _imagePickerVc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;  //设置摄像头模式为录制视频
        
    }
    return _imagePickerVc;
}


- (void)openImagePicker {
    // 照片最大可选张数
    NSInteger imageCount = [self.cameraOptions sy_integerForKey:@"imageCount"];
    // 显示内部拍照按钮
    BOOL isCamera        = [self.cameraOptions sy_boolForKey:@"isCamera"];
    BOOL isCrop          = [self.cameraOptions sy_boolForKey:@"isCrop"];
    BOOL isGif           = [self.cameraOptions sy_boolForKey:@"isGif"];
    BOOL showCropCircle  = [self.cameraOptions sy_boolForKey:@"showCropCircle"];
    BOOL isRecordSelected = [self.cameraOptions sy_boolForKey:@"isRecordSelected"];
    BOOL allowPickingOriginalPhoto = [self.cameraOptions sy_boolForKey:@"allowPickingOriginalPhoto"];
    BOOL sortAscendingByModificationDate = [self.cameraOptions sy_boolForKey:@"sortAscendingByModificationDate"];
    NSInteger CropW      = [self.cameraOptions sy_integerForKey:@"CropW"];
    NSInteger CropH      = [self.cameraOptions sy_integerForKey:@"CropH"];
    NSInteger circleCropRadius = [self.cameraOptions sy_integerForKey:@"circleCropRadius"];
    NSInteger   quality  = [self.cameraOptions sy_integerForKey:@"quality"];
    NSInteger   openGalleryType  = [self.cameraOptions sy_integerForKey:@"openGalleryType"];
    
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:imageCount delegate:nil];
    
    imagePickerVc.maxImagesCount = imageCount;
    imagePickerVc.allowPickingGif = isGif; // 允许GIF
    imagePickerVc.allowTakePicture = isCamera; // 允许用户在内部拍照
    imagePickerVc.allowPickingVideo = YES; // 允许视频
    imagePickerVc.allowPickingOriginalPhoto = allowPickingOriginalPhoto; // 允许原图
    imagePickerVc.sortAscendingByModificationDate = sortAscendingByModificationDate;
    imagePickerVc.alwaysEnableDoneBtn = YES;
    imagePickerVc.allowCrop = isCrop;   // 裁剪
     imagePickerVc.openGalleryType = openGalleryType;   // 是否为视频
    
    if (isRecordSelected) {
        imagePickerVc.selectedAssets = self.selectedAssets; // 当前已选中的图片
    }
    
    if (imageCount == 1) {
        // 单选模式
        imagePickerVc.showSelectBtn = NO;
        
        if(isCrop){
            if(showCropCircle) {
                imagePickerVc.needCircleCrop = showCropCircle; //圆形裁剪
                imagePickerVc.circleCropRadius = circleCropRadius; //圆形半径
            } else {
                CGFloat x = ([[UIScreen mainScreen] bounds].size.width - CropW) / 2;
                CGFloat y = ([[UIScreen mainScreen] bounds].size.height - CropH) / 2;
                imagePickerVc.cropRect = CGRectMake(x,y,CropW,CropH);
            }
        }
    }
    
    __block TZImagePickerController *weakPicker = imagePickerVc;
     //图片选择后的回调
    [imagePickerVc setDidFinishPickingPhotosWithInfosHandle:^(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto,NSArray<NSDictionary *> *infos) {
        if (isRecordSelected) {
            self.selectedAssets = [NSMutableArray arrayWithArray:assets];
        }
        NSMutableArray *selectedPhotos = [NSMutableArray array];
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:selectedPhotos options:kNilOptions error:nil];
        NSLog(@"selectedPhotos::::%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//        NSLog(@"selectedPhotos::::%@",st2);
        
        [weakPicker showProgressHUD];
        if (imageCount == 1 && isCrop) {
            [selectedPhotos addObject:[self handleImageData:photos[0] quality:quality]];
        } else {
            [infos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [selectedPhotos addObject:[self handleImageData:photos[idx] quality:quality]];
            }];
        }
        [self invokeSuccessWithResult:selectedPhotos];
        [weakPicker hideProgressHUD];
    }];
    
    //视频选择后的回调
    [imagePickerVc setDidFinishPickingVideoHandle:^(UIImage *coverImage,PHAsset *asset){
        NSLog(@"selectedPhotos:::video:::,%f,%ld",coverImage.size.width,(long)asset.mediaType);
//        NSMutableArray *selectedPhotos = [NSMutableArray array];
//         [selectedPhotos addObject:[self handleImageData:asset quality:quality]];
        
        if (asset.mediaType == PHAssetMediaTypeVideo) {
                     PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
                      options.version = PHImageRequestOptionsVersionCurrent;
                     options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
                     
                     PHImageManager *manager = [PHImageManager defaultManager];
                        [manager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                             AVURLAsset *urlAsset = (AVURLAsset *)asset;
                             
                            NSURL *url = urlAsset.URL;
//                           NSData *data = [NSData dataWithContentsOfURL:url];
//                   NSLog(@"%@",data);
                              NSString *urlPath = [url path];
                    NSLog(@"视频保存后的回调urlPath:::%@", urlPath);
                    NSMutableArray *selectedVideo = [NSMutableArray array];
                    NSMutableDictionary *video = [NSMutableDictionary dictionary];
                    
                    UIImage *firtImage = [self thumbnailImageForVideo:url atTime:0];
                    //拿到视频第一针，并将相关数据放到video
                    video =[self handleImageData:firtImage];
                    video[@"type"] = @"video";
                    video[@"uri"] = [@"file://" stringByAppendingString:urlPath];
                    [selectedVideo addObject:video];
                    self.resolveBlock(selectedVideo);
                             
                        }];
                 }
        
    }];
    
    __block TZImagePickerController *weakPickerVc = imagePickerVc;
    [imagePickerVc setImagePickerControllerDidCancelHandle:^{
        [self invokeError];
        [weakPickerVc hideProgressHUD];
    }];
    
    [[self topViewController] presentViewController:imagePickerVc animated:YES completion:nil];
}

- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
    }
    return _imagePickerVc;
}

#pragma mark - UIImagePickerController
- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        // 无相机权限 做一个友好的提示
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self takePhoto];
                });
            }
        }];
        // 拍照之前还需要检查相册权限
    } else if ([PHPhotoLibrary authorizationStatus] == 2) { // 已被拒绝，没有相册权限，将无法保存拍的照片
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if ([PHPhotoLibrary authorizationStatus] == 0) { // 未请求过相册权限
        [[TZImageManager manager] requestAuthorizationWithCompletion:^{
            [self takePhoto];
        }];
    } else {
        [self pushImagePickerController];
    }
}

// 调用相机
- (void)pushImagePickerController {
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerVc.sourceType = sourceType;
        [[self topViewController] presentViewController:self.imagePickerVc animated:YES completion:nil];
    }else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
        NSLog(@"type urlPath:::%@",type);
        if ([type isEqualToString:@"public.image"]) {
            NSLog(@"public.image urlPath:::");
            TZImagePickerController *tzImagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
            tzImagePickerVc.sortAscendingByModificationDate = NO;
            [tzImagePickerVc showProgressHUD];
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            
            // save photo and get asset / 保存图片，获取到asset
            [[TZImageManager manager] savePhotoWithImage:image location:NULL completion:^(PHAsset *asset, NSError *error){
                if (error) {
                    [tzImagePickerVc hideProgressHUD];
                    NSLog(@"图片保存失败 %@",error);
                } else {
                    [[TZImageManager manager] getCameraRollAlbum:NO allowPickingImage:YES needFetchAssets:YES completion:^(TZAlbumModel *model) {
                        [[TZImageManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:NO allowPickingImage:YES completion:^(NSArray<TZAssetModel *> *models) {
                            [tzImagePickerVc hideProgressHUD];
                            
                            TZAssetModel *assetModel = [models firstObject];
                            BOOL isCrop          = [self.cameraOptions sy_boolForKey:@"isCrop"];
                            BOOL showCropCircle  = [self.cameraOptions sy_boolForKey:@"showCropCircle"];
                            NSInteger CropW      = [self.cameraOptions sy_integerForKey:@"CropW"];
                            NSInteger CropH      = [self.cameraOptions sy_integerForKey:@"CropH"];
                            NSInteger circleCropRadius = [self.cameraOptions sy_integerForKey:@"circleCropRadius"];
                            NSInteger   quality = [self.cameraOptions sy_integerForKey:@"quality"];
                            
                            if (isCrop) {
                                TZImagePickerController *imagePicker = [[TZImagePickerController alloc] initCropTypeWithAsset:assetModel.asset photo:image completion:^(UIImage *cropImage, id asset) {
                                    [self invokeSuccessWithResult:@[[self handleImageData:cropImage quality:quality]]];
                                }];
                                imagePicker.allowPickingImage = YES;
                                if(showCropCircle) {
                                    imagePicker.needCircleCrop = showCropCircle; //圆形裁剪
                                    imagePicker.circleCropRadius = circleCropRadius; //圆形半径
                                } else {
                                    CGFloat x = ([[UIScreen mainScreen] bounds].size.width - CropW) / 2;
                                    CGFloat y = ([[UIScreen mainScreen] bounds].size.height - CropH) / 2;
                                    imagePicker.cropRect = CGRectMake(x,y,CropW,CropH);
                                }
                                [[self topViewController] presentViewController:imagePicker animated:YES completion:nil];
                            } else {
                                [self invokeSuccessWithResult:@[[self handleImageData:image quality:quality]]];
                            }
                        }];
                    }];
                }
            }];
        }else if([type isEqualToString:(NSString *)kUTTypeMovie]){
            //视频保存后 播放视频
            NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
            NSString *urlPath = [url path];
            //urlPath:::/private/var/mobile/Containers/Data/Application/E689D40D-6FF0-4050-9A5B-F64E6CB00F3C/tmp/57476060886__4316FAC0-4F6B-4706-84F1-B7F9B9000AA0.MOV
          
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlPath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(urlPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
        }
    }];
}


//视频保存后的回调 返回给js端
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存视频过程中发生错误，错误信息:%@",error.localizedDescription);
    }else{
        NSLog(@"视频保存成功.");
        //录制完之后自动发送到js端
        NSURL *url=[NSURL fileURLWithPath:videoPath];
        NSString *urlPath = [url path];
        NSLog(@"视频保存后的回调urlPath:::%@", urlPath);
        NSMutableArray *selectedVideo = [NSMutableArray array];
        NSMutableDictionary *video = [NSMutableDictionary dictionary];
     
        UIImage *firtImage = [self thumbnailImageForVideo:url atTime:0];
        //拿到视频第一针，并将相关数据放到video
        video =[self handleImageData:firtImage];
        video[@"type"] = @"video";
        video[@"uri"] = [@"file://" stringByAppendingString:urlPath];
        [selectedVideo addObject:video];
       self.resolveBlock(selectedVideo);
    }
}

//拿到视频的第一针图片
- (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    
    return thumbnailImage;
}



- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self invokeError];
    if ([picker isKindOfClass:[UIImagePickerController class]]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (NSDictionary *)handleImageData:(UIImage *) image quality:(NSInteger)quality {
    NSMutableDictionary *photo = [NSMutableDictionary dictionary];
    NSData *imageData = UIImageJPEGRepresentation(image, quality * 1.0 / 100);
    
    // 剪切图片并放在tmp中
    photo[@"width"] = @(image.size.width);
    photo[@"height"] = @(image.size.height);
    photo[@"size"] = @(imageData.length);
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
    [self createDir];
    NSString *filePath = [NSString stringWithFormat:@"%@ImageCaches/%@", NSTemporaryDirectory(), fileName];
    if ([imageData writeToFile:filePath atomically:YES]) {
        photo[@"uri"] = filePath;
    } else {
        NSLog(@"保存压缩图片失败%@", filePath);
    }
    
    if ([self.cameraOptions sy_boolForKey:@"enableBase64"]) {
        photo[@"base64"] = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", [imageData base64EncodedStringWithOptions:0]];
    }
    return photo;
}

// 视频图片的转换，没有质量压缩。不会有base64，uri为：thumbnail
- (NSDictionary *)handleImageData:(UIImage *) image  {
    NSMutableDictionary *photo = [NSMutableDictionary dictionary];
    NSData *imageData = UIImageJPEGRepresentation(image,1.0 / 100);
    
    // 剪切图片并放在tmp中
    photo[@"width"] = @(image.size.width);
    photo[@"height"] = @(image.size.height);
    photo[@"size"] = @(imageData.length);
    
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
    [self createDir];
    NSString *filePath = [NSString stringWithFormat:@"%@ImageCaches/%@", NSTemporaryDirectory(), fileName];
    if ([imageData writeToFile:filePath atomically:YES]) {
        photo[@"thumbnail"] = filePath;
    } else {
        NSLog(@"保存压缩图片失败%@", filePath);
    }
    
    if ([self.cameraOptions sy_boolForKey:@"enableBase64"]) {
        photo[@"base64"] = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", [imageData base64EncodedStringWithOptions:0]];
    }
    return photo;
}

- (void)invokeSuccessWithResult:(NSArray *)photos {
    if (self.callback) {
        self.callback(@[[NSNull null], photos]);
        self.callback = nil;
    }
    if (self.resolveBlock) {
        self.resolveBlock(photos);
        self.resolveBlock = nil;
    }
}

- (void)invokeError {
    if (self.callback) {
        self.callback(@[@"取消"]);
        self.callback = nil;
    }
    if (self.rejectBlock) {
        self.rejectBlock(@"", @"取消", nil);
        self.rejectBlock = nil;
    }
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (BOOL)createDir {
    NSString * path = [NSString stringWithFormat:@"%@ImageCaches", NSTemporaryDirectory()];;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if  (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {//先判断目录是否存在，不存在才创建
        BOOL res=[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        return res;
    } else return NO;
}

- (UIViewController *)topViewController {
    UIViewController *rootViewController = RCTPresentedViewController();
    return rootViewController;
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

@end
