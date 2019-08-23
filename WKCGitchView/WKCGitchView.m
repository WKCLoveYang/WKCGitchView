//
//  WKCGitchManager.m
//  WKCCameraGitch
//
//  Created by wkcloveYang on 2019/7/18.
//  Copyright © 2019 wkcloveYang. All rights reserved.
//

#import "WKCGitchView.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CGFloat WKCGitchScaleOnceTime = 0.6 * 2;
CGFloat WKCGitchSoulOutOnceTime = 0.7 * 2;
CGFloat WKCGitchShakeOnceTime = 0.7 * 2;
CGFloat WKCGitchShineWhiteOnceTime = 0.6 * 2;
CGFloat WKCGitchGlitchOnceTime = 0.3 * 2;
CGFloat WKCGitchVertigoOnceTime = 2.0 * 2;

typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;


@interface WKCGitchView()
{
    
    
    UIView * _superView;
    CGRect _frame;
    CGRect _currentFrame;
    CGFloat _currentOnceTime;
}

@property (nonatomic, assign) SenceVertex * vertices;
@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) GLuint program; // 着色器程序
@property (nonatomic, assign) GLuint vertexBuffer; // 顶点缓存
@property (nonatomic, assign) GLuint textureID; // 纹理 ID
@property (nonatomic, assign) GLint drawableWidth;
@property (nonatomic, assign) GLint drawableHeight;

@property (nonatomic, strong) CADisplayLink *displayLink; // 用于刷新屏幕
@property (nonatomic, assign) NSTimeInterval startTimeInterval; // 开始的时间戳
@property (nonatomic, strong) CAEAGLLayer * bindlayer;

@property (nonatomic, strong) NSMutableArray <UIImage *> * imagesArray;
@property (nonatomic, copy) void(^saveBlock)(BOOL isSuccess);

@end

@implementation WKCGitchView

- (void)dealloc
{
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    
    if (self.displayLink) {
        [self.displayLink invalidate];
    }
}

- (instancetype)initWithSuperView:(UIView *)superView frame:(CGRect)frame
{
    if (self = [super init]) {
        
        _superView = superView;
        _frame = frame;
        _currentFrame = frame;
        
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:self.context];
        self.vertices = malloc(sizeof(SenceVertex) * 4);
        
        self.vertices[0] = (SenceVertex){{-1, 1, 0}, {0, 1}};
        self.vertices[1] = (SenceVertex){{-1, -1, 0}, {0, 0}};
        self.vertices[2] = (SenceVertex){{1, 1, 0}, {1, 1}};
        self.vertices[3] = (SenceVertex){{1, -1, 0}, {1, 0}};
        
        _bindlayer = [[CAEAGLLayer alloc] init];
        _bindlayer.frame = frame;
        _bindlayer.contentsScale = [[UIScreen mainScreen] scale];
        _bindlayer.masksToBounds = YES;
        [superView.layer addSublayer:_bindlayer];
        
        _maskToBounds = YES;
        _imagesArray = [NSMutableArray array];
    }
    
    return self;
}


#pragma mark -Setter、Getter
- (void)setImage:(UIImage *)image
{
    _image = image;
    
    if (!image) return;
    
    _bindlayer.frame = [self getFrameWithMode:_contentMode];
    [self bindRenderLayer:_bindlayer];
    
    GLuint textureID = [self createTextureWithImage:image];
    self.textureID = textureID;  // 将纹理 ID 保存，方便后面切换滤镜的时候重用
    
    glViewport(0, 0, self.drawableWidth, self.drawableHeight);
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * 4;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
    
    self.vertexBuffer = vertexBuffer; // 将顶点缓存保存，退出时才释放
    
    [self startFilerAnimation];
    [self setType:_type];
}

- (void)setType:(WKCGitchType)type
{
    _type = type;
    if (!_image) return;
    
    self.startTimeInterval = 0;
    
    switch (type) {
        case WKCGitchTypeNormal:
        {
            [self setupShaderProgramWithName:@"normal"];
            _currentOnceTime = 0;
        }
            break;
            
        case WKCGitchTypeScale:
        {
            [self setupShaderProgramWithName:@"scale"];
            _currentOnceTime = WKCGitchScaleOnceTime;
        }
            break;
            
        case WKCGitchTypeSoulOut:
        {
            [self setupShaderProgramWithName:@"SoulOut"];
            _currentOnceTime = WKCGitchSoulOutOnceTime;
        }
            break;
            
        case WKCGitchTypeShake:
        {
            [self setupShaderProgramWithName:@"Shake"];
            _currentOnceTime = WKCGitchShakeOnceTime;
        }
            break;
            
        case WKCGitchTypeShineWhite:
        {
            [self setupShaderProgramWithName:@"ShineWhite"];
            _currentOnceTime = WKCGitchShineWhiteOnceTime;
        }
            break;
            
        case WKCGitchTypeGlitch:
        {
            [self setupShaderProgramWithName:@"Glitch"];
            _currentOnceTime = WKCGitchGlitchOnceTime;
        }
            break;
            
        case WKCGitchTypeVertigo:
        {
            [self setupShaderProgramWithName:@"Vertigo"];
            _currentOnceTime = WKCGitchVertigoOnceTime;
        }
            break;
            
        default:
            break;
    }
}

- (void)setContentMode:(WKCGitchContentMode)contentMode
{
    _contentMode = contentMode;
    _bindlayer.frame = [self getFrameWithMode:contentMode];
}

- (void)setMaskToBounds:(BOOL)maskToBounds
{
    _maskToBounds = maskToBounds;
    _bindlayer.masksToBounds = maskToBounds;
}


- (GLint)drawableWidth
{
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    return backingWidth;
}

- (GLint)drawableHeight
{
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    return backingHeight;
}

- (NSArray<UIImage *> *)images
{
    if (_imagesArray && _imagesArray.count != 0) {
        [_imagesArray removeObjectAtIndex:0];
    }
    return _imagesArray;
}

- (NSData *)gifData
{
    
    return [self animatedGifWithArray:self.images];
}

#pragma mark -InnerMethod
- (void)bindRenderLayer:(CALayer <EAGLDrawable> *)layer
{
    GLuint renderBuffer;
    GLuint frameBuffer;
    
    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              renderBuffer);
}

- (GLuint)createTextureWithImage:(UIImage *)image
{
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

- (void)setupShaderProgramWithName:(NSString *)name
{
    GLuint program = [self programWithShaderName:name];
    glUseProgram(program);
    
    GLuint positionSlot = glGetAttribLocation(program, "Position");
    GLuint textureSlot = glGetUniformLocation(program, "Texture");
    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureID);
    glUniform1i(textureSlot, 0);
    
    glEnableVertexAttribArray(positionSlot);
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    glEnableVertexAttribArray(textureCoordsSlot);
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));
    
    self.program = program;
}

- (GLuint)programWithShaderName:(NSString *)shaderName
{
    GLuint vertexShader = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];
    
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    glLinkProgram(program);
    
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    return program;
}

- (GLuint)compileShaderWithName:(NSString *)name
                           type:(GLenum)shaderType
{
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];
    
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    GLuint shader = glCreateShader(shaderType);
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shader);
    
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    
    return shader;
}

- (void)startFilerAnimation
{
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    [_imagesArray removeAllObjects];
    self.startTimeInterval = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timeAction)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                           forMode:NSRunLoopCommonModes];
}

- (void)timeAction
{
    if (self.startTimeInterval == 0) {
        self.startTimeInterval = self.displayLink.timestamp;
    }
    
    glUseProgram(self.program);
    glBindBuffer(GL_ARRAY_BUFFER, self.vertexBuffer);
    
    // 传入时间
    CGFloat currentTime = self.displayLink.timestamp - self.startTimeInterval;
    GLuint time = glGetUniformLocation(self.program, "Time");
    glUniform1f(time, currentTime);
    
    // 清除画布
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(1, 1, 1, 1);
    
    // 重绘
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    
    // 去掉几张黑屏的
    BOOL isCanAdd = ((currentTime > 0) && (currentTime < _currentOnceTime / 2.0)) || ((currentTime > _currentOnceTime / 2.0) && (currentTime < _currentOnceTime)) ;
    NSLog(@"%f %f %d", currentTime, _currentOnceTime, isCanAdd);
    if (isCanAdd) {
         UIImage * image = [self imageFromTexture];
         [_imagesArray addObject:image];
        NSLog(@"加了一张图");
    }
}


- (UIImage *)imageFromTexture
{
    int width = self.drawableWidth;
    int height = self.drawableHeight;
    
    int size = width * height * 4;
    GLubyte *buffer = malloc(size);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, size, NULL);
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    // 此时的 imageRef 是上下颠倒的，调用 CG 的方法重新绘制一遍，刚好翻转过来
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    free(buffer);
    return image;
}

- (CGRect)getFrameWithMode:(WKCGitchContentMode)mode
{
    if (!_image) return _frame;
    
    CGFloat imageWidth = _image.size.width, imageHeight = _image.size.height, layerWidth = _frame.size.width, layerHeight = _frame.size.height;
    CGRect newFrame = CGRectZero;
    CGFloat x = 0 , y = 0, width = 0, height = 0;
    
    switch (mode) {
        case WKCGitchContentModeNone:
        {
            x = _frame.origin.x;
            y = _frame.origin.y;
            width = _frame.size.width;
            height = _frame.size.height;
            newFrame = CGRectMake(x, y, width, height);
        }
            break;
            
        case WKCGitchContentModeFit:
        {
            if (imageHeight / imageWidth > layerHeight / layerWidth) {
                y = 0;
                height = layerHeight;
                width = height * imageWidth / imageHeight;
                x = (layerWidth - width) / 2.0;
            } else {
                x = 0;
                width = layerWidth;
                height = width * imageHeight / imageWidth;
                y = (layerHeight - height) / 2.0;
            }
            newFrame = CGRectMake(x + _frame.origin.x, y + _frame.origin.y, width, height);
        }
            break;
            
        case WKCGitchContentModeFill:
        {
            if (imageHeight / imageWidth > layerHeight / layerWidth) {
                x = 0;
                width = layerWidth;
                height = width * imageHeight / imageWidth;
                y = (layerHeight - height) / 2.0;
            } else {
                y = 0;
                height = layerHeight;
                width = height * imageWidth / imageHeight;
                x = (layerWidth - width) / 2.0;
            }
            newFrame = CGRectMake(x + _frame.origin.x, y + _frame.origin.y, width, height);
        }
            break;
            
        default:
            break;
    }
    
    _currentFrame = newFrame;
    return newFrame;
}


- (NSData *)animatedGifWithArray:(NSArray <UIImage *>*)tabImage
{
    NSInteger frameCount = tabImage.count;
    CGFloat framTotal = self.displayLink.preferredFramesPerSecond == 0 ? 60.0 : self.displayLink.preferredFramesPerSecond * 1.0;
    
    //图像目标
    CGImageDestinationRef destination;
    //创建输出路径
    NSArray *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentStr = [document objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *textDirectory = [documentStr stringByAppendingPathComponent:@"gif"];
    [fileManager createDirectoryAtPath:textDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *path = [textDirectory stringByAppendingPathComponent:@"gitch.gif"];
    
    CFURLRef url = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,
                                                  (CFStringRef)path,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    
    destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, frameCount, NULL);
    
    //设置gif的信息,播放间隔时间,基本数据,和delay时间
    NSDictionary *frameProperties = [NSDictionary
                                     dictionaryWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0/framTotal], (NSString *)kCGImagePropertyGIFDelayTime, nil]
                                     forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    //设置gif信息
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    //
    [dict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCGImagePropertyGIFHasGlobalColorMap];
    
    [dict setObject:(NSString *)kCGImagePropertyColorModelRGB forKey:(NSString *)kCGImagePropertyColorModel];
    
    [dict setObject:[NSNumber numberWithInt:8] forKey:(NSString*)kCGImagePropertyDepth];
    
    [dict setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount];
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:dict
                                                              forKey:(NSString *)kCGImagePropertyGIFDictionary];
    
    @autoreleasepool {
        for (NSInteger index = 0; index < frameCount; index ++) {
            UIImage* dImg = tabImage[index];
            CGImageDestinationAddImage(destination, dImg.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    return data;
}



#pragma mark -OutsideMethod
- (void)saveGifToAlbumHandle:(void(^)(BOOL isSuccess))handle
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handle) {
                    handle(NO);
                }
            });
        } else {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:self.gifData options:options];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handle) {
                        handle(success);
                    }
                });
            }];
        }
    }];
}

@end


#pragma clang diagnostic pop
