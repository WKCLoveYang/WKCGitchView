//
//  ViewController.m
//  Demo
//
//  Created by wkcloveYang on 2019/8/23.
//  Copyright © 2019 wkcloveYang. All rights reserved.
//

#import "ViewController.h"
#import <WKCGitchView.h>
#import "WKCGitchItemCell.h"
#import <Masonry.h>
#import <JGProgressHUD.h>

@interface ViewController ()
<UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) WKCGitchView * gitchView;
@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSArray <NSNumber *> * dataSource;
@property (nonatomic, strong) UIButton * saveButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.darkGrayColor;
    
    _gitchView = [[WKCGitchView alloc] initWithSuperView:self.view frame:self.view.frame];
    _gitchView.image = [UIImage imageNamed:@"2"];
    _gitchView.type = WKCGitchTypeNormal;
    
    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [_saveButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    _saveButton.backgroundColor = UIColor.yellowColor;
    _saveButton.layer.cornerRadius = 2;
    _saveButton.layer.masksToBounds = YES;
    [_saveButton addTarget:self action:@selector(actionSave:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_saveButton];
    [self.view addSubview:self.collectionView];
    
    [_saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-20);
        make.top.equalTo(self.view).offset(60);
        make.size.mas_equalTo(CGSizeMake(60, 30));
    }];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-60);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo([WKCGitchItemCell itemSize].height);
    }];
}

- (NSArray<NSNumber *> *)dataSource
{
    if (!_dataSource) {
        _dataSource = @[
                        @(WKCGitchTypeNormal),
                        @(WKCGitchTypeSoulOut),
                        @(WKCGitchTypeScale),
                        @(WKCGitchTypeShake),
                        @(WKCGitchTypeGlitch),
                        @(WKCGitchTypeVertigo),
                        @(WKCGitchTypeShineWhite)
                        ];
    }
    
    return _dataSource;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout * layout = [UICollectionViewFlowLayout new];
        layout.minimumLineSpacing = 4;
        layout.minimumInteritemSpacing = 4;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = WKCGitchItemCell.itemSize;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundView = nil;
        _collectionView.backgroundColor = nil;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.contentInset = UIEdgeInsetsMake(0, 20, 0, 20);
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:WKCGitchItemCell.class forCellWithReuseIdentifier:NSStringFromClass(WKCGitchItemCell.class)];
    }
    
    return _collectionView;
}

- (void)actionSave:(UIButton *)sender
{
    JGProgressHUD * hud = [[JGProgressHUD alloc] initWithStyle:JGProgressHUDStyleLight];
    [hud showInView:self.view];
    [_gitchView saveGifToAlbumHandle:^(BOOL isSuccess) {
        [hud dismiss];
        [self showAlertWithTitle:isSuccess ? @"保存成功" : @"保存失败"];
    }];
}

- (void)showAlertWithTitle:(NSString *)title
{
    UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertVC addAction:action];
    alertVC.popoverPresentationController.sourceRect = self.saveButton.frame;
    alertVC.popoverPresentationController.sourceView = self.saveButton;
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark -UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WKCGitchItemCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(WKCGitchItemCell.class) forIndexPath:indexPath];
    WKCGitchType type = [self.dataSource[indexPath.row] integerValue];
    switch (type) {
        case WKCGitchTypeNormal:
        {
            cell.title = @"Normal";
        }
            break;
            
        case WKCGitchTypeShineWhite:
        {
            cell.title = @"Shine";
        }
            break;
            
        case WKCGitchTypeScale:
        {
            cell.title = @"Scale";
        }
            break;
            
        case WKCGitchTypeShake:
        {
            cell.title = @"Shake";
        }
            break;
            
        case WKCGitchTypeGlitch:
        {
            cell.title = @"Glitch";
        }
            break;
            
        case WKCGitchTypeSoulOut:
        {
            cell.title = @"SoulOut";
        }
            break;
            
        case WKCGitchTypeVertigo:
        {
            cell.title = @"Vertigo";
        }
            break;
            
        default:
            break;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    WKCGitchType type = [self.dataSource[indexPath.row] integerValue];
    _gitchView.type = type;
}

@end
