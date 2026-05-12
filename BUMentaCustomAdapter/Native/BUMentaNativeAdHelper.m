//
//  BUMentaNativeAdHelper.m
//  BUMentaCustomAdapter
//
//  Created by jdy on 2024/7/10.
//

#import "BUMentaNativeAdHelper.h"

@interface BUMentaNativeAdHelper ()
@property (nonatomic, strong) MentaNativeObject *data;
@property (nonatomic, strong) UILabel *adTitleLabel;
@property (nonatomic, strong) UIImageView *adImageView;

@property (nonatomic, strong) UIImage *image;

@end

@implementation BUMentaNativeAdHelper

- (instancetype)initWithAdData:(MentaNativeObject *)data image:(UIImage *)image {
    if (self = [super init]) {
        self.image = image;
        _data = data;
        [self setupView];
    }
    return self;
}

- (instancetype)initWithAdData:(MentaNativeObject *)data {
    if (self = [super init]) {
        _data = data;
        [self setupView];
    }
    return self;
}

- (void)setupView {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.data.nativeAdView.frame = CGRectMake(0, 0, 200, 200);
        strongSelf.adTitleLabel = [[UILabel alloc] init];
        strongSelf.adImageView = [[UIImageView alloc] init];
    });
}

#pragma mark - BUMMediatedNativeAdViewCreator
- (UILabel *)titleLabel {
    return self.adTitleLabel;
}

#pragma mark - BUMMediatedNativeAdData
- (NSString *)AdTitle {
    return self.data.dataObject.title;
}

- (NSString *)AdDescription {
    return self.data.dataObject.desc;
}

- (NSArray<BUMImage *> *)imageList {
    if (self.image) {
        BUMImage *img = [[BUMImage alloc] init];
        img.width = self.data.dataObject.materialList.firstObject.materialWidth;
        img.height = self.data.dataObject.materialList.firstObject.materialHeight;
        img.image = self.image;
        img.imageURL = [NSURL URLWithString:self.data.dataObject.materialList.firstObject.materialUrl];
        return @[img];
    }
    return @[];
}

- (BUMImage *)adLogo {
    BUMImage *img = [[BUMImage alloc] init];
    img.width = 30;
    img.height = 30;
    img.image = self.data.dataObject.adIcon;
    return img;
}

- (BUMImage *)sdkLogo {
    return self.adLogo;
}

- (UIView *)mediaView {
    return self.data.nativeAdView.mentaMediaView;
}

- (BUFeedADMode)imageMode {
    if (self.data.dataObject.isVideo) {
        return BUFeedVideoAdModePortrait;
    } else {
        return BUFeedADModeLargeImage;
    }
}

#pragma mark - BUMMediatedNativeAdData
- (NSString *)adTitle {
    return self.data.dataObject.title;
}

- (NSString *)adDescription {
    return self.data.dataObject.desc;
}

@end
