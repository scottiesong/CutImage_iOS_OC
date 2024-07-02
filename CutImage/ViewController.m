//
//  ViewController.m
//  CutImage
//
//  Created by pengyuesong on 2024/6/27.
//

#import "ViewController.h"
#import "CropImageViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropImageViewControllerDelegate>

@property (strong, nonatomic) UIImageView *resultImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 添加选择图片按钮
    UIButton *selectImageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    selectImageButton.frame = CGRectMake(20, 140, 100, 30);
    [selectImageButton setTitle:@"选择图片" forState:UIControlStateNormal];
    [selectImageButton addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectImageButton];
    
    // 设置结果图片视图
    self.resultImageView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 400 / 2, 300, 400, 300)];
    self.resultImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.resultImageView.backgroundColor = UIColor.lightGrayColor;
    [self.view addSubview:self.resultImageView];
}

- (void)selectImage {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        CropImageViewController *cropVC = [[CropImageViewController alloc] init];
        cropVC.imageToCrop = selectedImage;
        cropVC.delegate = self;
        cropVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:cropVC animated:YES completion:nil];
    }];
}

- (void)cropImageViewController:(CropImageViewController *)controller didCropImage:(UIImage *)croppedImage {
    self.resultImageView.image = croppedImage;
    
    [self photoLibrarySaveImageToLocalAlbum:croppedImage success:^(NSURL *localImageUrl) {
        NSLog(@"local URL: %@", localImageUrl.absoluteString);
    }];
}

/*
 PhotoLibrary 方式存图片到本地相册并返回访问地址
 */
- (void)photoLibrarySaveImageToLocalAlbum:(UIImage *)image success:(void(^)(NSURL *localImageUrl))completionHandler {
    //    __weak typeof(self) weakSelf = self;
    __block NSString *identifier = @"";
    [self getPhotoAuthor:^(BOOL success) {
        if (!success) {
            return;
        }
        /* 保存Image到本地相册 并返回两种方式的URL */
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *result = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            PHObjectPlaceholder *assetPlaceholder = result.placeholderForCreatedAsset;
            // imageLocalIdentifier用于零时存取相片的标识符，方便后边能够取出此相片
            //        weakSelf.imageLocalIdentifier = assetPlaceholder.localIdentifier;
            identifier = assetPlaceholder.localIdentifier;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                // 保存成功后通过前边的identifier得到其路径
                PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
                PHAsset *asset = assets.firstObject;
                [asset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput * _Nullable contentEditingInput, NSDictionary * _Nonnull info) {
                    NSString *ext = [contentEditingInput.fullSizeImageURL pathExtension];
                    NSString *identifier_code = [[identifier componentsSeparatedByString:@"/"] firstObject];
                    
                    /* PHPhotoLibrary 方式的本地相册图片地址 */
                    NSURL *locatPhotoLibraryUrl =  contentEditingInput.fullSizeImageURL;
                    NSLog(@"PhotoLibrary.URL = %@", locatPhotoLibraryUrl.absoluteString);
//                    completionHandler(locatPhotoLibraryUrl);
                    /* Assets-Library 方式的本地相册图片地址拼接 */
                    NSURL *locatAssetsLibraryUrl = [NSURL URLWithString:[NSString stringWithFormat:@"assets-library://asset/asset.%@?id=%@&ext=%@", ext, identifier_code, ext]];
                    NSLog(@"AssetsLibrary.URL = %@", locatAssetsLibraryUrl.absoluteString);
//                    completionHandler(locatAssetsLibraryUrl);
                }];
            }
        }];
    }];
}

/*
 AssetsLibrary 方式存图片到本地相册并返回访问地址
 */
//- (void)assetsLibrarySaveImageToLocalAlbum:(UIImage *)image success:(void(^)(NSURL *localImageUrl))completionHandler {
//    __block ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
//    [lib writeImageToSavedPhotosAlbum:image.CGImage metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
//        //assetURL即地址
//        NSLog(@"assetURL = %@, error = %@", assetURL, error);
//        if (completionHandler) {
//            completionHandler(assetURL);
//        }
//        lib = nil;
//    }];
//}

/*
 获得相册权限
 */
- (void)getPhotoAuthor:(void(^)(BOOL success))completed {
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 14.0) {
        PHAccessLevel photosAuthorizationLevel = PHAccessLevelReadWrite;
        PHAuthorizationStatus photosAuthorizationStatus = [PHPhotoLibrary authorizationStatusForAccessLevel:photosAuthorizationLevel];
        if (photosAuthorizationStatus == PHAuthorizationStatusAuthorized) {
            if (completed != nil) {
                completed(YES);
                return;
            }
        }
        
        [PHPhotoLibrary requestAuthorizationForAccessLevel:photosAuthorizationLevel handler:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    if (completed != nil) {
                        completed(YES);
                        return;
                    }
                } else {
                    if ((status == PHAuthorizationStatusDenied) || (status == PHAuthorizationStatusLimited)) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"视频图片上传" message:@"需要获取您所有的相册权限，才可开启上传视频图片哦" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        }];
                        [alertController addAction:cancel];
                        UIAlertAction *settingAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                NSURL*url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                [[UIApplication sharedApplication] openURL:url];
                            }
                        }];
                        [alertController addAction:settingAction];
                        [self presentViewController:alertController animated:YES completion:nil];
                        if (completed) {
                            completed(NO);
                        }
                    }
                }
            });
        }];
        return;
    }
    
    PHAuthorizationStatus OldStatus = [PHPhotoLibrary authorizationStatus];
    if (OldStatus == PHAuthorizationStatusAuthorized) {
        if (completed) {
            completed(YES);
        }
        return;
    }
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                if (completed) {
                    completed(YES);
                }
            } else if (status == PHAuthorizationStatusDenied) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"视频图片上传" message:@"需要获取您的相册权限，才可开启上传视频图片哦" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                }];
                [alertController addAction:cancel];
                UIAlertAction *settingAction=[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        NSURL*url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
                [alertController addAction:settingAction];
                [self presentViewController:alertController animated:YES completion:nil];
                if (completed) {
                    completed(NO);
                }
            }
        });
    }];
}

@end
