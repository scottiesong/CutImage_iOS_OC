//
//  CropImageViewController.h
//  CutImage
//
//  Created by pengyuesong on 2024/6/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CropImageViewControllerDelegate;

@interface CropImageViewController : UIViewController

@property (strong, nonatomic) UIImage *imageToCrop;
@property (weak, nonatomic) id<CropImageViewControllerDelegate> delegate;

@end

@protocol CropImageViewControllerDelegate <NSObject>

- (void)cropImageViewController:(CropImageViewController *)controller didCropImage:(UIImage *)croppedImage;

@end

NS_ASSUME_NONNULL_END
