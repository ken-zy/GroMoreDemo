//
//  BUMentaNativeAdapter.m
//  BUMentaCustomAdapter
//
//  Created by jdy on 2024/7/9.
//

#import "BUMentaNativeAdapter.h"
#import "BUMentaNativeAdHelper.h"
#import <MentaUnifiedSDK/MentaUnifiedSDK-umbrella.h>
#import <MentaVlionBaseSDK/MVYYWebImageManager.h>

@interface BUMentaNativeAdapter () <MentaUnifiedNativeExpressAdDelegate, MentaUnifiedNativeAdDelegate>

@property (nonatomic, strong) MentaUnifiedNativeAd *nativeAd;
@property (nonatomic, strong) MentaNativeObject *nativeAdData;
@property (nonatomic, strong) MentaUnifiedNativeExpressAd *nativeExpressAd;
@property (nonatomic, strong) UIView *nativeExpressView;

@end


@implementation BUMentaNativeAdapter

/// 当前加载的广告的状态，native模板广告
- (BUMMediatedAdStatus)mediatedAdStatusWithExpressView:(UIView *)view {
    return BUMMediatedAdStatusUnknown;
}

/// 当前加载的广告的状态，native非模板广告
- (BUMMediatedAdStatus)mediatedAdStatusWithMediatedNativeAd:(BUMMediatedNativeAd *)ad {
    return BUMMediatedAdStatusUnknown;
}

- (void)loadNativeAdWithSlotID:(nonnull NSString *)slotID andSize:(CGSize)size imageSize:(CGSize)imageSize parameter:(nonnull NSDictionary *)parameter {
    // 获取广告加载数量
    NSLog(@"parameter %@", parameter);
    // 获取是否需要加载模板广告，非必要，视network支持而定
    NSInteger renderType = [parameter[BUMAdLoadingParamExpressAdType] integerValue];
    if (renderType == 1) { // 此处仅说明渲染类型可下发，开发者需根据实际定义情况编写
        if (self.nativeExpressAd) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.nativeExpressAd destory];
            });
            self.nativeExpressAd.delegate = nil;
            self.nativeExpressAd = nil;
        }
        
        MUNativeExpressConfig *config = [[MUNativeExpressConfig alloc] init];
        if (size.height == 0) {
            CGFloat aspectRatio = 9.0 / 16.0;
            CGFloat height = size.width * aspectRatio;
            config.adSize = CGSizeMake(size.width, height);
        } else {
            config.adSize = size;
        }
        
        config.slotId = slotID;
        config.materialFillMode = MentaNativeExpressAdMaterialFillMode_ScaleAspectFill;
        config.viewController = self.bridge.viewControllerForPresentingModalView;// 必须设置, 用于内部presentvc

        self.nativeExpressAd = [[MentaUnifiedNativeExpressAd alloc] initWithConfig:config];
        self.nativeExpressAd.delegate = self;

        [self.nativeExpressAd loadAd];
        
    } else {
        if (self.nativeAd) {
            self.nativeAd.delegate = nil;
            self.nativeAd = nil;
        }
        MUNativeConfig *config = [MUNativeConfig new];
        config.slotId = slotID;
        config.viewController = self.bridge.viewControllerForPresentingModalView;
//        config.tolerateTime = 30;
        self.nativeAd = [[MentaUnifiedNativeAd alloc] initWithConfig:config];
        self.nativeAd.delegate = self;
        [self.nativeAd loadAd];
    }
}

- (void)registerContainerView:(nonnull __kindof UIView *)containerView andClickableViews:(nonnull NSArray<__kindof UIView *> *)views forNativeAd:(nonnull id)nativeAd {
    if ([nativeAd isKindOfClass:[MentaNativeObject class]]) {
        MentaNativeObject *ad = (MentaNativeObject *)nativeAd;
        [containerView insertSubview:ad.nativeAdView atIndex:0];
        [ad registerClickableViews:views closeableViews:@[]];
    }
}

- (void)renderForExpressAdView:(nonnull UIView *)expressAdView {
    // 如不adn广告不需要render，请尽量模拟回调renderSuccess
    [self.bridge nativeAd:self renderSuccessWithExpressView:expressAdView];
}

- (void)setRootViewController:(nonnull UIViewController *)viewController forExpressAdView:(nonnull UIView *)expressAdView {
//    if ([expressAdView isKindOfClass:[BUMDCustomExpressNativeView class]]) {
//        BUMDCustomExpressNativeView *view = (BUMDCustomExpressNativeView *)expressAdView;
//        view.viewController = viewController;
//    }
}

- (void)setRootViewController:(nonnull UIViewController *)viewController forNativeAd:(nonnull id)nativeAd {
//    if ([nativeAd isKindOfClass:[BUMDCustomNativeData class]]) {
//        BUMDCustomNativeData *ad = (BUMDCustomNativeData *)nativeAd;
//        ad.viewController = viewController;
//    }
}

- (void)unregisterClickableViewsForNativeAd:(nonnull id)nativeAd { 
    
}

- (void)didReceiveBidResult:(BUMMediaBidResult *)result {
    // 在此处理Client Bidding的结果回调
    if (result.win) {
        [self.nativeAd sendWinNotification];
        [self.nativeExpressAd sendWinNotification];
    } else {
        if (result.winnerPrice) {
            [self.nativeAd sendLossNotificationWithInfo:@{MU_M_L_WIN_PRICE : @(result.winnerPrice)}];
            [self.nativeExpressAd sendLossNotificationWithInfo:@{MU_M_L_WIN_PRICE : @(result.winnerPrice)}];
        }
    }
}

#pragma mark - private

- (void)downloadImgWith:(NSString *)imgUrl {
    __weak typeof(self) weakSelf = self;
    [[MVYYWebImageManager sharedManager] requestImageWithURL:[NSURL URLWithString:imgUrl]
                                                     options:0
                                                    progress:nil
                                                   transform:nil
                                                  completion:^(UIImage * _Nullable image,
                                                               NSURL * _Nonnull url,
                                                               MVYYWebImageFromType from,
                                                               MVYYWebImageStage stage,
                                                               NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (image) {
            NSLog(@"downloadImg success");
            id<BUMMediatedNativeAdData, BUMMediatedNativeAdViewCreator> helper = [[BUMentaNativeAdHelper alloc] initWithAdData:strongSelf.nativeAdData image:image];
            [strongSelf generateBuDataWith:helper];
        }
    }];
}

- (void)generateBuDataWith:(BUMentaNativeAdHelper *)helper {
    BUMMediatedNativeAd *ad = [[BUMMediatedNativeAd alloc] init];
    ad.originMediatedNativeAd = self.nativeAdData;
    ad.view = self.nativeAdData.nativeAdView;
    ad.viewCreator = helper;
    ad.data = helper;
    
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *exts = [NSMutableArray arrayWithCapacity:1];
    [list addObject:ad];
    NSString *ecpm = [NSString stringWithFormat:@"%@", self.nativeAdData.dataObject.price];
    [exts addObject:@{BUMMediaAdLoadingExtECPM : ecpm,}];
    NSLog(@"[self.bridge nativeAd:self didLoadWithNativeAds:[list copy] exts:exts.copy];");
    [self.bridge nativeAd:self didLoadWithNativeAds:[list copy] exts:exts.copy];
}

#pragma mark - MentaUnifiedNativeExpressAdDelegate

/// 广告策略服务加载成功
- (void)menta_didFinishLoadingADPolicy:(MentaUnifiedNativeExpressAd *_Nonnull)nativeExpressAd {
    NSLog(@"%s", __FUNCTION__);
}

/**
 广告数据回调
 @param unifiedNativeAdDataObjects 广告数据数组
 */
- (void)menta_nativeExpressAdLoaded:(NSArray<MentaUnifiedNativeExpressAdObject *> * _Nullable)unifiedNativeAdDataObjects nativeExpressAd:(MentaUnifiedNativeExpressAd *_Nonnull)nativeExpressAd {
    NSLog(@"%s", __FUNCTION__);
}


/**
信息流广告加载失败
@param nativeExpressAd MentaUnifiedNativeExpressAd 实例,
@param error 错误
*/
- (void)menta_nativeExpressAd:(MentaUnifiedNativeExpressAd *_Nonnull)nativeExpressAd didFailWithError:(NSError * _Nullable)error description:(NSDictionary *_Nonnull)description {
    NSLog(@"%s", __FUNCTION__);
}

/**
 信息流渲染成功
 @param nativeExpressAd MentaUnifiedNativeExpressAd 实例,
 */
- (void)menta_nativeExpressAdViewRenderSuccess:(MentaUnifiedNativeExpressAd *_Nonnull)nativeExpressAd nativeExpressAdObject:(MentaUnifiedNativeExpressAdObject *_Nonnull)nativeExpressAdObj {
    NSLog(@"%s", __FUNCTION__);
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *exts = [NSMutableArray arrayWithCapacity:1];
    [list addObject:nativeExpressAdObj.expressView];
    NSString *ecpm = [NSString stringWithFormat:@"%@", nativeExpressAdObj.price];
    [exts addObject:@{BUMMediaAdLoadingExtECPM : ecpm,}];
    [self.bridge nativeAd:self didLoadWithExpressViews:[list copy] exts:exts.copy];
}

/**
 信息流渲染失败
 @param nativeExpressAd MentaUnifiedNativeExpressAd 实例,
 */
- (void)nativeExpressAdViewRenderFail:(MentaUnifiedNativeExpressAd *_Nonnull)nativeExpressAd nativeExpressAdObject:(MentaUnifiedNativeExpressAdObject *_Nonnull)nativeExpressAdObj {
    NSLog(@"%s", __FUNCTION__);
    
    NSError *error = [NSError errorWithDomain:@"MentaUnified"
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: @"unknown error"}];
    [self.bridge nativeAd:self renderFailWithExpressView:nativeExpressAdObj.expressView andError:error];
}

/**
 广告曝光回调
 @param nativeExpressAd MentaUnifiedNativeExpressAd 实例,
 */
- (void)menta_nativeExpressAdViewWillExpose:(MentaUnifiedNativeExpressAd *_Nullable)nativeExpressAd nativeExpressAdObject:(MentaUnifiedNativeExpressAdObject *_Nonnull)nativeExpressAdObj {
    NSLog(@"%s", __FUNCTION__);
    [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:nativeExpressAdObj.expressView];
}


/**
 广告点击回调,
 @param nativeExpressAd MentaUnifiedNativeExpressAd 实例,
 */
- (void)menta_nativeExpressAdViewDidClick:(MentaUnifiedNativeExpressAd *_Nullable)nativeExpressAd nativeExpressAdObject:(MentaUnifiedNativeExpressAdObject *_Nonnull)nativeExpressAdObj {
    NSLog(@"%s", __FUNCTION__);
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:nativeExpressAdObj.expressView];
    [self.bridge nativeAd:self willPresentFullScreenModalWithMediatedNativeAd:nativeExpressAdObj.expressView];
}

/**
 广告点击关闭回调 UI的移除和数据的解绑 需要在该回调中进行
 @param nativeExpressAd MentaUnifiedNativeExpressAd 实例,
 */
- (void)menta_nativeExpressAdDidClose:(MentaUnifiedNativeExpressAd *_Nonnull)nativeExpressAd nativeExpressAdObject:(MentaUnifiedNativeExpressAdObject *_Nonnull)nativeExpressAdObj {
    NSLog(@"%s", __FUNCTION__);
    [self.bridge nativeAd:self didCloseWithExpressView:nativeExpressAdObj.expressView closeReasons:@[]];
}

#pragma mark - MentaUnifiedNativeAdDelegate

/**
 广告数据回调

 @param unifiedNativeAdDataObjects 广告数据数组
 */
- (void)menta_nativeAdLoaded:(NSArray<MentaNativeObject *> * _Nullable)unifiedNativeAdDataObjects nativeAd:(MentaUnifiedNativeAd *_Nullable)nativeAd {
    NSLog(@"%s", __FUNCTION__);
    
    self.nativeAdData = unifiedNativeAdDataObjects.firstObject;
    if (self.nativeAdData.dataObject.isVideo) {
        id<BUMMediatedNativeAdData, BUMMediatedNativeAdViewCreator> helper = [[BUMentaNativeAdHelper alloc] initWithAdData:self.nativeAdData];
        [self generateBuDataWith:helper];
    } else {
        [self downloadImgWith:self.nativeAdData.dataObject.materialList.firstObject.materialUrl];
    }
}

/// 信息流自渲染加载失败
- (void)menta_nativeAd:(MentaUnifiedNativeAd *_Nonnull)nativeAd didFailWithError:(NSError * _Nullable)error description:(NSDictionary *_Nonnull)description {
    NSLog(@"%s", __FUNCTION__);
}


/**
 广告曝光回调,
 @param nativeAd MentaUnifiedNativeAd 实例,
 @param adView 广告View
 */
- (void)menta_nativeAdViewWillExpose:(MentaUnifiedNativeAd *_Nullable)nativeAd adView:(UIView<MentaNativeAdViewProtocol> *_Nonnull)adView {
    NSLog(@"%s", __FUNCTION__);
    [self.bridge nativeAd:self didVisibleWithMediatedNativeAd:self.nativeAdData];
}

/**
 广告曝光失败回调
 @param nativeAd MentaUnifiedNativeAd 实例
 @param error 错误
 */
- (void)menta_nativeAd:(MentaUnifiedNativeAd *)nativeAd didFailToExposeWithError:(NSError *)error {
    NSLog(@"%s", __FUNCTION__);
}

/**
 广告点击回调,

 @param nativeAd MentaUnifiedNativeAd 实例,
 */
- (void)menta_nativeAdViewDidClick:(MentaUnifiedNativeAd *_Nullable)nativeAd adView:(UIView<MentaNativeAdViewProtocol> *_Nullable)adView {
    NSLog(@"%s", __FUNCTION__);
    [self.bridge nativeAd:self didClickWithMediatedNativeAd:self.nativeAdData];
    [self.bridge nativeAd:self willPresentFullScreenModalWithMediatedNativeAd:self.nativeAdData];
}

/**
 广告点击关闭回调 UI的移除和数据的解绑 需要在该回调中进行

 @param nativeAd MentaUnifiedNativeAd 实例,
 */
- (void)menta_nativeAdDidClose:(MentaUnifiedNativeAd *_Nonnull)nativeAd adView:(UIView<MentaNativeAdViewProtocol> *_Nullable)adView {
    NSLog(@"%s", __FUNCTION__);
}


/**
 广告详情页面即将展示回调, 当广告位落地页广告时会触发

 @param nativeAd MentaUnifiedNativeAd 实例,
 */
- (void)menta_nativeAdDetailViewWillPresentScreen:(MentaUnifiedNativeAd *_Nullable)nativeAd adView:(UIView<MentaNativeAdViewProtocol> *_Nonnull)adView {
    NSLog(@"%s", __FUNCTION__);
}


/**
 广告详情页关闭回调,即落地页关闭回调, 当关闭弹出的落地页时 触发

 @param nativeAd MentaUnifiedNativeAd 实例,
 */
- (void)menta_nativeAdDetailViewClosed:(MentaUnifiedNativeAd *_Nullable)nativeAd adView:(UIView<MentaNativeAdViewProtocol> *_Nonnull)adView {
    NSLog(@"%s", __FUNCTION__);
}

@end
