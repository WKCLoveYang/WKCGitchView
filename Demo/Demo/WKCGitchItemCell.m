//
//  WKCGitchItemCell.m
//  Demo
//
//  Created by wkcloveYang on 2019/8/23.
//  Copyright © 2019 wkcloveYang. All rights reserved.
//

#import "WKCGitchItemCell.h"
#import <Masonry.h>

@interface WKCGitchItemCell()

@property (nonatomic, strong) UILabel * titleLabel;

@end

@implementation WKCGitchItemCell

+ (CGSize)itemSize
{
    return CGSizeMake(80, 60);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        self.contentView.backgroundColor = UIColor.whiteColor;
        self.contentView.layer.cornerRadius = 4;
        self.contentView.layer.masksToBounds = YES;
        
        [self.contentView addSubview:self.titleLabel];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
    }
    
    return self;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:14];
    }
    
    return _titleLabel;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

@end
