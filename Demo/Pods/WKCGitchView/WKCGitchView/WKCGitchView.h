//
//  WKCGitchManager.h
//  WKCCameraGitch
//
//  Created by wkcloveYang on 2019/7/18.
//  Copyright © 2019 wkcloveYang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

/**
  Gitch类型
  @enum WKCGitchTypeNormal     正常模式
  @enum WKCGitchTypeScale      缩放模式
  @enum WKCGitchTypeSoulOut    灵魂出窍
  @enum WKCGitchTypeShake      摇晃
  @enum WKCGitchTypeShineWhite 闪模式
  @enum WKCGitchTypeGlitch     Glitch模式
  @enum WKCGitchTypeVertigo    vertigo模式
 */
typedef NS_ENUM(NSInteger, WKCGitchType) {
    WKCGitchTypeNormal     = 0,
    WKCGitchTypeScale      = 1,
    WKCGitchTypeSoulOut    = 2,
    WKCGitchTypeShake      = 3,
    WKCGitchTypeShineWhite = 4,
    WKCGitchTypeGlitch     = 5,
    WKCGitchTypeVertigo    = 6
};

/**
  图片铺展模式
  @enum WKCGitchContentModeNone 无(会铺满, 拉伸图片)
  @enum WKCGitchContentModeFit  适应
  @enum WKCGitchContentModeFill 铺满,不拉伸
 */
typedef NS_ENUM(NSInteger, WKCGitchContentMode) {
    WKCGitchContentModeFit  = 0,
    WKCGitchContentModeFill = 1,
    WKCGitchContentModeNone = 2
};


@interface WKCGitchView : NSObject

/**
  原图
 */
@property (nonatomic, strong) UIImage * image;

/**
  Gitch类型
 */
@property (nonatomic, assign) WKCGitchType type;

/**
  图片铺展模式
 */
@property (nonatomic, assign) WKCGitchContentMode contentMode;

/**
  超出部分是否裁剪
 */
@property (nonatomic, assign) BOOL maskToBounds;

/**
  效果图片数组
 */
@property (nonatomic, strong, readonly) NSArray <UIImage *> * images;

/**
  图片生成的gif数据
 */
@property (nonatomic, strong, readonly) NSData * gifData;


/**
 *  初始化
 *  @param superView 父视图
 *  @param frame 坐标
 *  @return WKCGitchView
 */
- (instancetype)initWithSuperView:(UIView *)superView
                            frame:(CGRect)frame;

/**
 *  保存Gif到相册
 *  @param handle 结果回调
 */
- (void)saveGifToAlbumHandle:(void(^)(BOOL isSuccess))handle;

@end

