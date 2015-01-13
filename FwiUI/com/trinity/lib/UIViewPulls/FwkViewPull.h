//  Project name: FwiUI
//  File name   : FwkViewPull.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 11/24/12
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
    kPullViewState_Idle     = 0,
    kPullViewState_Loading  = 1,
    kPullViewState_Pull     = 2,
    kPullViewState_Release  = 3
} PullViewState;


@protocol FwkViewPullDelegate;


@interface FwkViewPull : UIView {

@protected
    UIScrollView *_scrollView;
    
    NSInteger    _maxHeight;
    
@private
    BOOL _isLoading;
    PullViewState _currentState;
}

@property (nonatomic, assign) id<FwkViewPullDelegate> delegate;
@property (nonatomic, retain) UIScrollView *scrollView;

@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, readonly) PullViewState currentState;


/**
 * Return to normal
 */
- (void)finishLoadingWithCompletion:(void(^)(BOOL finished))completion;
/**
 * Switch state of refresh view
 */
- (void)switchState:(PullViewState)state offset:(CGFloat)offset;

/**
 * Handle did scroll event from scroll view
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
/**
 * Handle did end dragging event from scroll view
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView;

@end




@protocol FwkViewPullDelegate <NSObject>

@optional
- (void)viewPull:(FwkViewPull *)viewPull isTriggered:(BOOL)isTriggered;

@end