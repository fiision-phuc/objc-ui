//  Project name: FwiUI
//  File name   : FwkCarousel.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 11/14/12
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2013 Trinity 0715. All Rights Reserved.
//  --------------------------------------------------------------
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,  FITNESS  FOR  A  PARTICULAR  PURPOSE  AND
// NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED
// IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR  ANY
// DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
// NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR  PERFORMANCE
// OF THIS SOFTWARE.
//
//
// Disclaimer
// ----------
// Although reasonable care has been taken to ensure the correctness of  this  implementation,  this
// code should never be used in any application without proper verification and testing.  I disclaim
// all liability and responsibility to any person or entity with  respect  to  any  loss  or  damage
// caused, or alleged to be caused, directly or indirectly, by the use of this  class.  However,  if
// you discover any kind of bugs, please feel free to email me at phuc.fwi@gmail.com.

#import <UIKit/UIKit.h>


typedef enum {
    kCarouselType_CoverFlow1            = 0x07,
    kCarouselType_CoverFlow2            = 0x08,
    kCarouselType_Cylinder              = 0x03,
    kCarouselType_CylinderInverted      = 0x04,
    kCarouselType_Linear                = 0x00,
    kCarouselType_Rotary                = 0x01,
    kCarouselType_RotaryInverted        = 0x02,
    kCarouselType_TimeMachine           = 0x09,
    kCarouselType_TimeMachineInverted   = 0x0a,
    kCarouselType_Wheel                 = 0x05,
    kCarouselType_WheelInverted         = 0x06
} CarouselType;


@protocol FwkCarouselDataSource, FwkCarouselDelegate;


@interface FwkCarousel : UIView {
    
@private
    NSInteger                 _viewCount;
    NSInteger                 _visibleCount;
    
    CarouselType _type;
    BOOL _isVertical;
    
    BOOL _enableScroll;
    BOOL _isBouncing;
    BOOL _isRotable;
}

@property (nonatomic, assign) IBOutlet id<FwkCarouselDataSource> datasource;
@property (nonatomic, assign) IBOutlet id<FwkCarouselDelegate> delegate;

@property (nonatomic, readonly) CarouselType type;
@property (nonatomic, readonly) BOOL isVertical;

@property (nonatomic, assign)   BOOL enableScroll;
@property (nonatomic, assign)   BOOL isBouncing;
@property (nonatomic, assign)   BOOL isRotable;

@property (nonatomic, readonly) NSInteger viewCount;
@property (nonatomic, readonly) NSInteger visibleCount;

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, readonly) CGFloat currentOffset;

/**
 * Return array of visible indexes for this carousel
 */
- (NSArray *)visibleIndexes;
/**
 * Return array of visible views for this carousel
 */
- (NSArray *)visibleViews;
/**
 * Return current selected view for this carousel
 */
- (UIView *)currentView;

/**
 * Reload carousel
 */
- (void)reload;

/**
 * Render carousel
 */
- (void)render;

/**
 * Change carousel's style
 */
- (void)changeType:(CarouselType)type;
- (void)changeType:(CarouselType)type animations:(void(^)(void))animations completion:(void(^)(BOOL finished))completion;
/**
 * Switch between horizontal and vertical carousel
 */
- (void)changeVertical:(BOOL)vertical;
- (void)changeVertical:(BOOL)vertical animations:(void(^)(void))animations completion:(void(^)(BOOL finished))completion;

/**
 * Insert new view into carousel
 */
- (void)insertView;
- (void)insertViewWithCompletion:(void(^)(BOOL finished))completion;

/**
 * Remove a selected view from carousel
 */
- (void)removeView;
- (void)removeViewWithCompletion:(void(^)(BOOL finished))completion;

/**
 * Scroll to specific index
 */
- (void)scrollToViewAtIndex:(NSInteger)index;
- (void)scrollToViewAtIndex:(NSInteger)index completion:(void(^)(BOOL finished))completion;

@end




@protocol FwkCarouselDataSource <NSObject>

@required
/**
 * Number of views inside carousel
 */
- (NSUInteger)viewCountForCarousel:(FwkCarousel *)carousel;
/**
 * View's height inside carousel
 */
- (CGFloat)viewHeightForCarousel:(FwkCarousel *)carousel;
/**
 * View's width inside carousel
 */
- (CGFloat)viewWidthForCarousel:(FwkCarousel *)carousel;

/**
 * Return a sub view for carousel
 */
- (UIView *)carousel:(FwkCarousel *)carousel viewAtIndex:(NSUInteger)index reusingView:(UIView *)view;

@end




@protocol FwkCarouselDelegate <NSObject>

@required
/**
 * Handle insert new view into carousel
 */
- (void)carousel:(FwkCarousel *)carousel willInsertViewAtIndex:(NSInteger)index;
- (void)carousel:(FwkCarousel *)carousel didInsertViewAtIndex:(NSInteger)index;

/**
 * Handle remove view from carousel
 */
- (void)carousel:(FwkCarousel *)carousel willRemoveViewAtIndex:(NSInteger)index;
- (void)carousel:(FwkCarousel *)carousel didRemoveViewAtIndex:(NSInteger)index;

@optional
/**
 * Control & handle action change carousel's style
 */
- (BOOL)carousel:(FwkCarousel *)carousel shouldChangeToType:(CarouselType)type;
- (void)carousel:(FwkCarousel *)carousel willChangeToType:(CarouselType)type;
- (void)carousel:(FwkCarousel *)carousel didChangeToType:(CarouselType)type;

/**
 * Control & handle action change carousel's render direction
 */
- (BOOL)carousel:(FwkCarousel *)carousel shouldChangeRenderDirection:(BOOL)isVertical;
- (void)carousel:(FwkCarousel *)carousel willChangeRenderDirection:(BOOL)isVertical;
- (void)carousel:(FwkCarousel *)carousel didChangeRenderDirection:(BOOL)isVertical;

/**
 * Control insert new view into carousel
 */
- (BOOL)carousel:(FwkCarousel *)carousel shouldInsertViewAtIndex:(NSInteger)index;

/**
 * Control remove view from carousel
 */
- (BOOL)carousel:(FwkCarousel *)carousel shouldRemoveViewAtIndex:(NSInteger)index;

/**
 * Control & handle carousel's sroll action
 */
- (BOOL)carousel:(FwkCarousel *)carousel shouldScrollToViewAtIndex:(NSInteger)index;
- (void)carousel:(FwkCarousel *)carousel willScrollToViewAtIndex:(NSInteger)index;
- (void)carousel:(FwkCarousel *)carousel didScrollToViewAtIndex:(NSInteger)index;

- (void)carousel:(FwkCarousel *)carousel changedToViewAtIndex:(NSInteger)index;

@end