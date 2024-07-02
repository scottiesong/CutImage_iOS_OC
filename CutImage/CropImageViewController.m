//
//  CropImageViewController.m
//  CutImage
//
//  Created by pengyuesong on 2024/6/27.
//

#import "CropImageViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface CropImageViewController ()

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIView *cropView;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGesture;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

@end

@implementation CropImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.blackColor;
    CAShapeLayer * layer = [[CAShapeLayer alloc] init];
    layer.fillColor = [UIColor colorWithRed:.0 green:.0 blue:.0 alpha:0.5].CGColor;
    layer.fillRule = kCAFillRuleEvenOdd;
    UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds cornerRadius:0];
    layer.path = path.CGPath;
    [self.view.layer addSublayer:layer];
    
    // 设置图片视图
    self.imageView = [[UIImageView alloc] initWithImage:self.imageToCrop];
    self.imageView.frame = self.view.bounds;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.userInteractionEnabled = YES;
    [self.view addSubview:self.imageView];
    
    // 添加手势识别器
    self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.imageView addGestureRecognizer:self.pinchGesture];
    [self.imageView addGestureRecognizer:self.panGesture];
    
    // 设置裁剪视图
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat cropHeight = screenWidth * 0.75;
    self.cropView = [[UIView alloc] initWithFrame:CGRectMake(0, (self.view.bounds.size.height - cropHeight) / 2, screenWidth, cropHeight)];
    self.cropView.layer.borderColor = [UIColor redColor].CGColor;
    self.cropView.layer.borderWidth = 2.0;
    [self.view addSubview:self.cropView];
    self.cropView.userInteractionEnabled = YES;
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.cropView addGestureRecognizer:pinchGesture];
    [self.cropView addGestureRecognizer:panGesture];
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 50 - 46, self.view.bounds.size.width, 46 + 50)];
    view.backgroundColor = [UIColor colorWithRed:30/255.0 green:30/255.0 blue:30/255.0 alpha:0.7];
    [self.view addSubview:view];
    
    UIButton * canncelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    canncelBtn.frame = CGRectMake(0, 0, 60, 44);
    canncelBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [canncelBtn setTitle:@"取 消" forState:UIControlStateNormal];
    [canncelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [canncelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:canncelBtn];
    
    UIButton * doneBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    doneBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 0, 60, 44);
    doneBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [doneBtn setTitle:@"完 成" forState:UIControlStateNormal];
    [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(cropImage) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:doneBtn];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    UIView *currentView = gesture.view;
    if (currentView == self.cropView) {
//        NSLog(@"pinch -> cropView");
        currentView = self.imageView;
    }
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
//        gesture.view.transform = CGAffineTransformScale(gesture.view.transform, gesture.scale, gesture.scale);
        currentView.transform = CGAffineTransformScale(currentView.transform, gesture.scale, gesture.scale);
        gesture.scale = 1;
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self adjustImageViewPosition];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.view];
    CGPoint imageViewPosition = self.imageView.center;
    self.imageView.center = CGPointMake(imageViewPosition.x + translation.x * 1.5, imageViewPosition.y + translation.y * 1.5); // 加快移动速度
    [gesture setTranslation:CGPointZero inView:self.view];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self adjustImageViewPosition];
    }
}

- (void)adjustImageViewPosition {
    CGRect imageViewFrame = self.imageView.frame;
    CGRect cropViewFrame = self.cropView.frame;
    
    CGPoint adjustedCenter = self.imageView.center;
    
    if (CGRectGetMinX(imageViewFrame) > CGRectGetMinX(cropViewFrame)) {
        NSLog(@"%s minX", __PRETTY_FUNCTION__);
        adjustedCenter.x = CGRectGetMidX(cropViewFrame) - (CGRectGetWidth(cropViewFrame) / 2 - CGRectGetWidth(imageViewFrame) / 2);
    }
    
    if (CGRectGetMaxX(imageViewFrame) < CGRectGetMaxX(cropViewFrame)) {
        NSLog(@"%s maxX", __PRETTY_FUNCTION__);
        adjustedCenter.x = CGRectGetMidX(cropViewFrame) + (CGRectGetWidth(cropViewFrame) / 2 - CGRectGetWidth(imageViewFrame) / 2);
    }
    
    if (CGRectGetMinY(imageViewFrame) > CGRectGetMinY(cropViewFrame)) {
        NSLog(@"%s minY", __PRETTY_FUNCTION__);
        adjustedCenter.y = CGRectGetMidY(cropViewFrame) - (CGRectGetHeight(cropViewFrame) / 2 - CGRectGetHeight(imageViewFrame) / 2);
    }
    
    if (CGRectGetMaxY(imageViewFrame) < CGRectGetMaxY(cropViewFrame)) {
        NSLog(@"%s maxY", __PRETTY_FUNCTION__);
        adjustedCenter.y = CGRectGetMidY(cropViewFrame) + (CGRectGetHeight(cropViewFrame) / 2 - CGRectGetHeight(imageViewFrame) / 2);
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.imageView.center = adjustedCenter;
    }];
}

- (void)cropImage {
//    // 获取imageView在屏幕上的frame
//    CGRect imageViewFrameInSuperview = [self.imageView.superview convertRect:self.imageView.frame fromView:self.imageView];
    
    // 获取cropView在imageView坐标系中的frame
    CGRect cropRectInImageView = [self.cropView.superview convertRect:self.cropView.frame toView:self.imageView];
    
    // 获取UIImage在UIImageView中的显示frame
    CGSize imageSize = self.imageView.image.size;
    CGRect imageFrame = AVMakeRectWithAspectRatioInsideRect(imageSize, self.imageView.bounds);
    
    // 计算裁剪区域在图片中的frame
    CGFloat scale = imageSize.width / imageFrame.size.width;
    CGRect cropRectInImage = CGRectMake((cropRectInImageView.origin.x - imageFrame.origin.x) * scale,
                                        (cropRectInImageView.origin.y - imageFrame.origin.y) * scale,
                                        cropRectInImageView.size.width * scale,
                                        cropRectInImageView.size.height * scale);
    
    // 裁剪图片
    CGImageRef imageRef = CGImageCreateWithImageInRect([self.imageView.image CGImage], cropRectInImage);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // 通过代理将裁剪后的图片传回
    if ([self.delegate respondsToSelector:@selector(cropImageViewController:didCropImage:)]) {
        [self.delegate cropImageViewController:self didCropImage:croppedImage];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelBtnClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
