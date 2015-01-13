#import "FwkViewPull.h"


@interface FwkViewPull () {

}

/**
 * Initialize class's private variables
 */
- (void)_init;
/**
 * Visualize all view's components
 */
- (void)_visualize;

@end


@implementation FwkViewPull


@synthesize delegate=_delegate, scrollView=_scrollView, isLoading=_isLoading, currentState=_currentState;


#pragma mark - Class's constructors
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
        [self didMoveToSuperview];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    _delegate = nil;
    
    FwiRelease(_scrollView);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self switchState:_currentState offset:0.0f];
}
- (void)layoutSubviews {
    [super layoutSubviews];
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)finishLoadingWithCompletion:(void(^)(BOOL finished))completion {
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         if (_scrollView) [_scrollView setContentInset:UIEdgeInsetsZero];
                     }
                     completion:completion];
}
- (void)switchState:(PullViewState)state offset:(CGFloat)offset {
    _currentState = state;
    
    switch (_currentState) {
        case kPullViewState_Idle: {
            _isLoading = NO;
            break;
        }
        case kPullViewState_Loading: {
            _isLoading = YES;
            break;
        }
        case kPullViewState_Pull: {
            _isLoading = NO;
            break;
        }
        case kPullViewState_Release: {
            _isLoading = NO;
            break;
            
        }
        default:
            break;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    /* Condition validation */
    if (self.isLoading) return;
    
    CGPoint point  = [scrollView contentOffset];
    CGFloat offset = point.y;
    if (offset >= 0.0f) {
        [self switchState:kPullViewState_Idle offset:offset];
    }
    else if (offset <= 0.0f && offset >= -_maxHeight) {
        [self switchState:kPullViewState_Pull offset:offset];
    }
    else {
        [self switchState:kPullViewState_Release offset:offset];
    }
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView {
    /* Condition validation */
    if (self.isLoading) return;
    
    CGPoint point  = [scrollView contentOffset];
    CGFloat offset = point.y;
    
    if (offset <= 0.0f && offset < -_maxHeight) {
        [self switchState:kPullViewState_Loading offset:offset];
        
        UIEdgeInsets insets = UIEdgeInsetsMake(_maxHeight, 0.0f, 0.0f, 0.0f);
        [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [scrollView setContentInset:insets];
                         }
                         completion:^(BOOL finished) {
                             if (_delegate && [_delegate respondsToSelector:@selector(viewPull:isTriggered:)])
                                 [_delegate viewPull:self isTriggered:YES];
                         }];
    }
}


#pragma mark - Class's private methods
- (void)_init {
    _isLoading    = NO;
    _delegate     = nil;
    _scrollView   = nil;
    _maxHeight    = 0;
    _currentState = kPullViewState_Idle;
}
- (void)_visualize {
}


#pragma mark - Class's notification handlers


@end
