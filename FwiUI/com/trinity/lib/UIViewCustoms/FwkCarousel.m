#import "FwkCarousel.h"


#define MAX_VISIBLE_ITEMS 10
#define kCarousel_BounceDistance            0.5f
#define kCarousel_InsertDuration            0.2f
#define kCarousel_ScrollDuration            0.5f
#define kCarousel_Threshold_Decelerate      0.1f
#define kCarousel_Threshold_ScrollSpeed     2.0f
#define kCarousel_TimeMachineTilt           0.4f
#define kCarousel_ToggleDuration            0.2f


@interface FwkCarousel () <UIGestureRecognizerDelegate> {
    
    UIView                 *_vwContent;
    UIPanGestureRecognizer *_panGesture;
    
    NSMutableDictionary    *_viewHolder;
    NSMutableSet           *_viewPool;
    NSTimer                *_timer;
    
    CompletionBlock _completionBlock;
    
    BOOL            _isDecelerating;    // Turn on when carousel performs decelerating animation after swip
    BOOL            _isScrolling;       // Turn on when carousel move to index
    BOOL            _isDragging;        // Turn on when carousel handles drag action
    BOOL            _didDrag;           // Turn on when carousel finished handle drag action
    
    CGFloat         _viewH;             // View's height
    CGFloat         _viewW;             // View's width
    
    CGFloat         _scrollOffset;      // scrollOffset value
    CGFloat         _startOffset;       // Will have value if carousel is in decelerating mode, after dragged
    CGFloat         _endOffset;         // Will have value if carousel is in decelerating mode, after dragged
    
    CGFloat         _prevTranslation;   // Drag mode used
    NSInteger       _prevIdx;           // Save previous index
    
    NSTimeInterval  _scrollDuration;    // Will have value if carousel is in decelerating mode, after dragged
    NSTimeInterval  _startTime;         // Will have value if carousel is in decelerating mode, after dragged
    CGFloat         _startVelocity;     // Will have value if carousel is in decelerating mode, after dragged
    
    NSTimeInterval  _startToggleTime;   // Will have value if carousel is in dragging mode, only apply for CoverFlow2
    CGFloat         _toggleDistance;    // Will have value if carousel is in dragging mode, only apply for CoverFlow2
    
    NSUInteger      _animDisableCounter;
}

/**
 * Initialize carousel
 */
- (void)_init;

/**
 * Helper functions
 */
- (NSInteger)_helper_FindIndexForView:(UIView *)view;

- (UIView *)_helper_CreateContainerForView:(UIView *)view;
- (UIView *)_helper_FindViewAtIndex:(NSUInteger)index;

- (void)_helper_InsertView:(UIView *)view atIndex:(NSInteger)index;
- (void)_helper_SortDepth;

/**
 * Layout views
 */
- (void)_layout_TransformView;
- (void)_layout_TransformView:(UIView *)view atIndex:(NSInteger)index;
- (void)_layout_TransformView:(UIView *)view atOffset:(CGFloat)offset;

/**
 * manage animation
 */
- (void)_animDisable;
- (void)_animEnable;
- (void)_animStart;
- (void)_animStop;

/**
 * manage view
 */
- (UIView *)_management_DequeueView;
- (UIView *)_management_LoadViewAtIndex:(NSInteger)index;

- (void)_management_QueueView:(UIView *)view;
- (void)_management_UpdateVisibleCount;
- (void)_management_UpdateVisibleViews;

/**
 * View's animation handler
 */
- (BOOL)_viewAnim_ShouldDecelerate;
- (void)_viewAnim_StartDecelerating;    // Turn on isDecelerating flag, calculate startOffset & endOffset value, calculate start scroll time & scroll duration
- (void)_viewAnim_NextFrame;
- (void)_viewAnim_DidScroll;

/**
 * Gesture handlers
 */
- (void)_handlePan:(UIPanGestureRecognizer *)gesture;
- (void)_handleTap:(UITapGestureRecognizer *)gesture;

@end


@implementation FwkCarousel


static CGFloat(^_calculateFactor)(CGFloat scrollOffset, NSInteger viewCount, CGFloat bounceDistance, BOOL isBouncing, BOOL isRotable);
static CGFloat(^_calculateVelocity)(CGPoint velocity, CGFloat factor, CGFloat viewWidth, BOOL isVertical);

static NSInteger(^_distanceBetweenIndexes)(NSInteger idxFrom, NSInteger idxTo, NSInteger viewCount, BOOL isRotable);
static CGFloat(^_distanceBetweenOffsets)(CGFloat offsetFrom, CGFloat offsetTo, NSInteger viewCount, BOOL isRotable);
static CGFloat(^_distanceDeceleration)(CGFloat startVelocity);

static CGFloat(^_convertIndex)(NSInteger index, CGFloat scrollOffset, NSInteger viewCount, BOOL isRotable);

static NSInteger(^_rotateIndex)(NSInteger index, NSInteger viewCount, BOOL isRotable);
static CGFloat(^_rotateOffset)(CGFloat offset, NSInteger viewCount, BOOL isRotable);

static CGFloat(^_animationTime)(CGFloat time);
static CGFloat(^_spaceBetweenViews)(CarouselType carouselType, CGFloat viewW, CGFloat viewH, BOOL isVertical);  // Specify a scale factor for each visible view
static NSInteger(^_circularViewCount)(void);
static CGFloat(^_carouselWidth)(UIView *containerView, BOOL isVertical);
static CGFloat(^_alphaForOffset)(CGFloat offset, CarouselType carouselType);    // Only used for time machine


+ (void)initialize {
    _calculateFactor   = ^CGFloat(CGFloat scrollOffset, NSInteger viewCount, CGFloat bounceDistance, BOOL isBouncing, BOOL isRotable) {
        CGFloat f = 1.0f;   // factor
        
        // Validate rotate offset
        CGFloat offset = _rotateOffset(scrollOffset, viewCount, isRotable);
        
        // Calculate factor value if it is not rotating and is bouncing
        if (!isRotable && isBouncing) {
            f = 1.0f - fminf(fabsf(scrollOffset - offset), bounceDistance) / bounceDistance;
        }
        return f;
    };
    _calculateVelocity = ^CGFloat(CGPoint velocity, CGFloat factor, CGFloat viewWidth, BOOL isVertical) {
        CGFloat s = 0.5f;   // Scroll speed
        CGFloat v = 0.0f;   // Start velocity
        
        // Finalize velocity value
        v = -(!isVertical ? velocity.x : velocity.y) * factor * s / viewWidth;
        return v;
    };
    
    _convertIndex  = ^CGFloat(NSInteger index, CGFloat scrollOffset, NSInteger viewCount, BOOL isRotable) {
        // Handle special case for one item
        if (viewCount == 1) return 0.0f;
        
        //calculate relative position
        CGFloat offset = index - scrollOffset;
        
        if (isRotable) {
            if (offset > viewCount / 2)       offset -= viewCount;
            else if (offset < -viewCount / 2) offset += viewCount;
        }
        return offset;
    };
    
    _rotateIndex   = ^NSInteger(NSInteger index, NSInteger viewCount, BOOL isRotable) {
        if (viewCount == 0) return 0;
        
        if (!isRotable) index = MIN(MAX(index, 0), viewCount - 1);
        else index -= (NSInteger)floorf((CGFloat)index / (CGFloat)viewCount) * viewCount;
        
        return index;
    };
    _rotateOffset  = ^CGFloat(CGFloat offset, NSInteger viewCount, BOOL isRotable) {
        if (viewCount == 0) return 0.0f;
        
        if (!isRotable) offset = fminf(fmaxf(0.0f, offset), (CGFloat)viewCount - 1.0f);
        else offset = viewCount ? (offset - floorf(offset / (CGFloat)viewCount) * viewCount) : 0.0f;
        
        return offset;
    };
    
    _distanceBetweenIndexes = ^NSInteger(NSInteger idxFrom, NSInteger idxTo, NSInteger viewCount, BOOL isRotable) {
        NSInteger distance = idxTo - idxFrom;
        if (isRotable) {
            NSInteger wrappedDistance = MIN(idxTo, idxFrom) + viewCount - MAX(idxTo, idxFrom);
            if (idxFrom < idxTo) wrappedDistance *= -1;
            
            distance = (ABS(distance) <= ABS(wrappedDistance)) ? distance : wrappedDistance;
        }
        return distance;
    };
    _distanceBetweenOffsets = ^CGFloat(CGFloat offsetFrom, CGFloat offsetTo, NSInteger viewCount, BOOL isRotable) {
        CGFloat distance = offsetTo - offsetFrom;
        if (isRotable) {
            CGFloat wrappedDistance = fminf(offsetTo, offsetFrom) + viewCount - fmaxf(offsetTo, offsetFrom);
            if (offsetFrom < offsetTo) wrappedDistance *= -1;
            
            distance = (fabsf(distance) <= fabsf(wrappedDistance)) ? distance : wrappedDistance;
        }
        return distance;
    };
    _distanceDeceleration   = ^CGFloat(CGFloat startVelocity) {
        CGFloat decelerationAmplifier = 30.0f;
        CGFloat decelerationRate = 0.95f;
        
        CGFloat acceleration = -startVelocity * decelerationAmplifier * (1.0f - decelerationRate);
        CGFloat distance = -powf(startVelocity, 2.0f) / (2.0f * acceleration);
        return distance;
    };
    
    _animationTime = ^CGFloat(CGFloat time) {
        return (time < 0.5f) ? (0.5f * powf(time * 2.0f, 3.0f)) : (0.5f * powf(time * 2.0f - 2.0f, 3.0f) + 1.0f);
    };
    _circularViewCount = ^NSInteger{
        return 15;
    };
    _spaceBetweenViews = ^CGFloat(CarouselType carouselType, CGFloat viewW, CGFloat viewH, BOOL isVertical) {
        switch (carouselType) {
            case kCarouselType_CoverFlow1:
            case kCarouselType_CoverFlow2: {
                return 0.35f;
            }
            case kCarouselType_Cylinder:
            case kCarouselType_CylinderInverted: {
                break;
            }
            case kCarouselType_Linear: {
                return 1.10f;
            }
            case kCarouselType_Rotary:
            case kCarouselType_RotaryInverted: {
                break;
            }
            case kCarouselType_TimeMachine:
            case kCarouselType_TimeMachineInverted: {
                break;
            }
            case kCarouselType_Wheel:
            case kCarouselType_WheelInverted: {
                break;
            }
            default:
                break;
        }
        if (carouselType == kCarouselType_CoverFlow1 || carouselType == kCarouselType_CoverFlow2) return 0.15f;
        else return 1.15f;
    };
    _carouselWidth = ^CGFloat(UIView *containerView, BOOL isVertical) {
        /* Condition validation */
        if (!containerView) return 0.0f;
        
        CGRect screen = containerView.bounds;
        return (!isVertical ? screen.size.width : screen.size.height);
    };
    _alphaForOffset = ^CGFloat(CGFloat offset, CarouselType carouselType) {
        CGFloat minF   = -INFINITY;  // Low boundary
        CGFloat maxF   = INFINITY;   // High boundary
        CGFloat rangeF = 1.0f;
        
        switch (carouselType) {
            case kCarouselType_TimeMachine        : maxF = 0.0f; break;
            case kCarouselType_TimeMachineInverted: minF = 0.0f; break;
            default: break;
        }
        
        // Validate low & max boundary
        CGFloat alpha = 1.0f;
        
        if (offset > maxF) {
            alpha = 1.0f - fminf((offset - maxF), rangeF) / rangeF;
        }
        else if (offset < minF) {
            alpha = 1.0f - fminf((minF - offset), rangeF) / rangeF;
        }
        return alpha;
    };
}


#pragma mark - Class's constructors
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self _init];
        [self didMoveToSuperview];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _init];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    [self _animStop];
    
    FwiRelease(_vwContent);
    FwiRelease(_viewPool);
    FwiRelease(_viewHolder);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    
    // Initialize content view
    if (!_vwContent) {
        _vwContent = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_vwContent];
    }
    
    // Add pan gesture to content view
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePan:)];
        [_vwContent addGestureRecognizer:_panGesture];
        [_panGesture setDelegate:self];
        FwiRelease(_panGesture);;
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [_vwContent setFrame:self.bounds];
    
    // Reload content view if datasource is available
    if (_datasource) [self reload];
}


#pragma mark - Class's properties
- (NSInteger)currentIndex {
    return _rotateIndex(roundf(_scrollOffset), _viewCount, _isRotable);
}
- (CGFloat)currentOffset {
    return _rotateOffset(_scrollOffset, _viewCount, _isRotable);
}
- (void)setIsRotable:(BOOL)isRotable {
    _isRotable = isRotable;
    [self render];
}


#pragma mark - Class's public methods
- (NSArray *)visibleIndexes {
    return [[_viewHolder allKeys] sortedArrayUsingSelector:@selector(compare:)];
}
- (NSArray *)visibleViews {
    NSArray *indexes = [self visibleIndexes];
    return [_viewHolder objectsForKeys:indexes notFoundMarker:[NSNull null]];
}
- (UIView *)currentView {
    return [self _helper_FindViewAtIndex:self.currentIndex];
}

- (void)reload {
    // Remove all subviews
    if (_viewHolder) [[_viewHolder allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *container = [((UIView *)obj) superview];
        if (container) [container removeFromSuperview];
    }];
    FwiRelease(_viewHolder);
    FwiRelease(_viewPool);
    
    // Stop rendering if datasource is no longer available
    if (!_datasource) return;
    
    // Re-initial all parameters
    _viewCount    = [_datasource viewCountForCarousel:self];
    _viewW        = [_datasource viewWidthForCarousel:self];
    _viewH        = [_datasource viewHeightForCarousel:self];
    _visibleCount = 0;
    
    //reset view pools
    _viewPool   = [[NSMutableSet alloc] initWithCapacity:_viewCount];
    _viewHolder = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    // Render all subviews
    [self render];
}

- (void)render {
    //bail out if not set up yet
    if (!_datasource) return;
    
    // Update visible count
    [self _management_UpdateVisibleCount];
    
    // Prevent false index changed event
    _prevIdx = self.currentIndex;
    
    //update views
    [self _viewAnim_DidScroll];
}

- (void)changeType:(CarouselType)type {
    [self changeType:type animations:nil completion:nil];
}
- (void)changeType:(CarouselType)type animations:(void(^)(void))animations completion:(void(^)(BOOL finished))completion {
    if (_type == type) return;
    
    BOOL shouldChange = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:shouldChangeToType:)])
        shouldChange = [_delegate carousel:self shouldChangeToType:type];
    
    /* Condition validation: If user does not want to change, cancel all action */
    if (!shouldChange) return;
    
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:willChangeToType:)])
        [_delegate carousel:self willChangeToType:type];
    
    _type = type;
    [self _management_UpdateVisibleCount];
    [self _management_UpdateVisibleViews];
    [self setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _prevIdx = self.currentIndex;
                         [self _viewAnim_DidScroll];
                         
                         if (animations) animations();
                     }
                     completion:^(BOOL finished) {
                         [self setUserInteractionEnabled:YES];
                         if (_delegate && [_delegate respondsToSelector:@selector(carousel:didChangeToType:)])
                             [_delegate carousel:self didChangeToType:type];
                         
                         if (completion) completion(finished);
                     }];
}
- (void)changeVertical:(BOOL)vertical {
    [self changeVertical:vertical animations:nil completion:nil];
}
- (void)changeVertical:(BOOL)vertical animations:(void(^)(void))animations completion:(void(^)(BOOL finished))completion {
    if (_isVertical == vertical) return;

    BOOL shouldChange = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:shouldChangeRenderDirection:)])
        shouldChange = [_delegate carousel:self shouldChangeRenderDirection:vertical];
    
    /* Condition validation: If user does not want to change, cancel all action */
    if (!shouldChange) return;
    
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:willChangeRenderDirection:)])
        [_delegate carousel:self willChangeRenderDirection:vertical];
    
    _isVertical = vertical;
    [self setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self render];
                         if (animations) animations();
                     }
                     completion:^(BOOL finished) {
                         [self setUserInteractionEnabled:YES];
                         if (_delegate && [_delegate respondsToSelector:@selector(carousel:didChangeRenderDirection:)])
                             [_delegate carousel:self didChangeRenderDirection:vertical];
                         
                         if (completion) completion(finished);
                     }];
}

- (void)insertView {
    [self insertViewWithCompletion:nil];
}
- (void)insertViewWithCompletion:(void(^)(BOOL finished))completion {
    NSInteger index = self.currentIndex;
    if (_viewCount != 0) index++;
    
    BOOL shouldInsert = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:shouldInsertViewAtIndex:)])
        shouldInsert = [_delegate carousel:self shouldInsertViewAtIndex:index];
    
    /* Condition validation: If user does not want to insert view at a moment, cancel all action */
    if (!shouldInsert) return;
    _viewCount++;
    
    // Create new viewHolder
    NSMutableDictionary *newViews = [[NSMutableDictionary alloc] initWithCapacity:([_viewHolder count] + 1)];
    NSArray *visibleIndexes = [self visibleIndexes];
    
    for (NSNumber *idx in visibleIndexes) {
        NSInteger i = [idx integerValue];
        
        if (i < index) [newViews setObject:[_viewHolder objectForKey:idx] forKey:idx];
        else [newViews setObject:[_viewHolder objectForKey:idx] forKey:[NSNumber numberWithInteger:i + 1]];
    }
    FwiRelease(_viewHolder);
    _viewHolder = newViews;
    
    // Perform insert
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:willInsertViewAtIndex:)])
        [_delegate carousel:self willInsertViewAtIndex:index];
    
    UIView *itemView = [self _management_LoadViewAtIndex:index];
    itemView.superview.layer.opacity = 0.0f;
    _scrollOffset = index;
    _prevIdx = index;
    
    [self setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self _layout_TransformView];
                     }
                     completion:^(BOOL finished) {
                         [self _management_UpdateVisibleCount];
                         [self _management_UpdateVisibleViews];
                         [self _viewAnim_DidScroll];
                         [self _helper_SortDepth];
                         
                         [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              itemView.superview.layer.opacity = 1.0f;
                                          }
                                          completion:^(BOOL finished) {
                                              [self setUserInteractionEnabled:YES];
                                              if (_delegate && [_delegate respondsToSelector:@selector(carousel:didInsertViewAtIndex:)])
                                                  [_delegate carousel:self didInsertViewAtIndex:index];
                                              
                                              if (completion) completion(finished);
                                          }];
                     }];
}

- (void)removeView {
    [self removeViewWithCompletion:nil];
}
- (void)removeViewWithCompletion:(void(^)(BOOL finished))completion {
    BOOL shouldDelete = YES;
    NSInteger index   = self.currentIndex;
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:shouldRemoveViewAtIndex:)])
        shouldDelete = [_delegate carousel:self shouldRemoveViewAtIndex:index];
    
    /* Condition validation: If user does not want to delete view at a moment, cancel all action */
    if (!shouldDelete) return;
    
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:willRemoveViewAtIndex:)])
        [_delegate carousel:self willRemoveViewAtIndex:index];
    
    __block NSInteger idx = _rotateIndex(index, _viewCount, _isRotable);
    UIView *view = [self _helper_FindViewAtIndex:idx];
    
    [self setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [view.superview.layer setOpacity:0.0f];
                     }
                     completion:^(BOOL finished) {
                         [self _management_QueueView:view];
                         [view.superview removeFromSuperview];
                         
                         _viewCount--;
                         _scrollOffset = self.currentIndex;
                         
                         // Create new viewHolder
                         NSMutableDictionary *newViews = [[NSMutableDictionary alloc] initWithCapacity:([_viewHolder count] - 1)];
                         NSArray *visibleIndexes = [self visibleIndexes];
                         
                         for (NSNumber *visibleIndex in visibleIndexes) {
                             NSInteger i = [visibleIndex integerValue];
                             
                             if (i < idx) [newViews setObject:[_viewHolder objectForKey:visibleIndex] forKey:visibleIndex];
                             else if (i > idx) [newViews setObject:[_viewHolder objectForKey:visibleIndex] forKey:[NSNumber numberWithInteger:i - 1]];
                         }
                         FwiRelease(_viewHolder);
                         _viewHolder = newViews;
                         
                         [self _management_UpdateVisibleViews];
                         [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              [self _layout_TransformView];
                                          }
                                          completion:^(BOOL finished) {
                                              [self _viewAnim_DidScroll];
                                              [self _helper_SortDepth];
                                              [self setUserInteractionEnabled:YES];
                                              if (_delegate && [_delegate respondsToSelector:@selector(carousel:didRemoveViewAtIndex:)])
                                                  [_delegate carousel:self didRemoveViewAtIndex:index];
                                              
                                              if (completion) completion(finished);
                                          }];
                     }];
}

- (void)scrollToViewAtIndex:(NSInteger)index {
    [self scrollToViewAtIndex:index completion:nil];
}
- (void)scrollToViewAtIndex:(NSInteger)index completion:(void(^)(BOOL finished))completion {
    BOOL shouldScroll = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:shouldScrollToViewAtIndex:)])
        shouldScroll = [_delegate carousel:self shouldScrollToViewAtIndex:index];
    
    /* Condition validation: If user does not want to delete view at a moment, cancel all action */
    if (!shouldScroll) return;
    
    if (_delegate && [_delegate respondsToSelector:@selector(carousel:willScrollToViewAtIndex:)])
        [_delegate carousel:self willScrollToViewAtIndex:index];
    
    // Prepare completion action
    FwiRelease(_completionBlock);
    
    __block CompletionBlock block = nil;
    if (completion) block = [completion copy];
    
    __weak id weakDelegate = _delegate;
    __weak id weakSelf = self;
    _completionBlock = [^(BOOL finished) {
        if (weakDelegate && [weakDelegate respondsToSelector:@selector(carousel:didScrollToViewAtIndex:)])
            [weakDelegate carousel:weakSelf didScrollToViewAtIndex:index];
        
        if (block) block(finished);
        FwiRelease(block);
    } copy];
    
    // Control scroll flags
    _isDecelerating = NO;
    _isScrolling    = YES;
    
    // Setup scrollOffset
    _startOffset = _scrollOffset;
    _endOffset   = _startOffset + _distanceBetweenOffsets(_scrollOffset, index, _viewCount, _isRotable);
    _prevIdx     = roundf(_scrollOffset);
    
    // Setup animation time
    _startTime      = CACurrentMediaTime();
    _scrollDuration = kCarousel_ScrollDuration;
    
    if (!_isRotable) _endOffset = _rotateOffset(_endOffset, _viewCount, _isRotable);
    [self _animStart];
}


#pragma mark - Class's private methods
- (void)_init {
    // Initialize public variables
    _datasource   = nil;
    _delegate     = nil;
    _viewCount    = 0;
    _visibleCount = 0;
    
    _type         = kCarouselType_CoverFlow1;
    _isVertical   = NO;
    
    _enableScroll = YES;
    _isBouncing   = YES;
    _isRotable    = NO;
    
    // Initialize private variables
    _vwContent       = nil;
    _panGesture      = nil;
    
    _viewPool        = nil;
    _viewHolder      = nil;
    _timer           = nil;
    
    _completionBlock = nil;
    
    _isDecelerating  = NO;
    _isScrolling     = NO;
    _isDragging      = NO;
    _didDrag         = NO;
    
    _viewH           = 0.0f;
    _viewW           = 0.0f;
    
    _scrollOffset    = 0.0f;
    _startOffset     = 0.0f;
    _endOffset       = 0.0f;
    
    _prevTranslation = 0.0f;
    _prevIdx         = 0.0f;
    
    _scrollDuration  = 0.0f;
    _startTime       = 0.0f;
    _startVelocity   = 0.0f;
    
    _startToggleTime = 0.0f;
    _toggleDistance  = 0.0f;
    
    _animDisableCounter = 0;
}

- (void)_handlePan:(UIPanGestureRecognizer *)gesture {
    /* Condition validation */
    if (!_enableScroll) return;
    
    // Get physical info
    CGPoint t = [gesture translationInView:self];   // Translation
    CGPoint v = [gesture velocityInView:self];      // Velocity
    CGFloat w = !_isVertical ? _viewW : _viewH;
    
    // Handle gesture state
    switch ([gesture state]) {
        case UIGestureRecognizerStateBegan: {
            _isDragging      = YES;
            _isScrolling     = NO;
            _isDecelerating  = NO;
            _prevTranslation = !_isVertical ? t.x : t.y;
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            _isDragging = NO;
            _didDrag    = YES;
            
            // Validate if user is using swip or not
            if ([self _viewAnim_ShouldDecelerate]) {
                _didDrag = NO;
                [self _viewAnim_StartDecelerating];
            }
            
            // If user is not using swip, return to original index
            if (!_isDecelerating) {
                [self scrollToViewAtIndex:self.currentIndex];
            }
            break;
        }
            
        default: {
            CGFloat translation = (!_isVertical ? t.x : t.y) - _prevTranslation;
            CGFloat factor   = _calculateFactor(_scrollOffset, _viewCount, kCarousel_BounceDistance, _isBouncing, _isRotable);
            _startVelocity   = _calculateVelocity(v, factor, w, _isVertical);
            
            _prevTranslation = _isVertical ? [gesture translationInView:self].y: [gesture translationInView:self].x;
            _scrollOffset   -= translation * factor * (_type == kCarouselType_CoverFlow2 ? 2.0f : 1.0f) / w;
            [self _viewAnim_DidScroll];
            break;
        }
    }
}
- (void)_handleTap:(UITapGestureRecognizer *)gesture {
    /* Condition validation */
    if (!_enableScroll) return;
    
    NSInteger index = [self _helper_FindIndexForView:[gesture.view.subviews lastObject]];
    if (index != self.currentIndex) [self scrollToViewAtIndex:index];
}


#pragma mark - Class's private methods: Helper functions
- (NSInteger)_helper_FindIndexForView:(UIView *)view {
    NSInteger index = NSNotFound;
    index = [[_viewHolder allValues] indexOfObject:view];
    
    if (index != NSNotFound) {
        return [[[_viewHolder allKeys] objectAtIndex:index] integerValue];
    }
    else if (index == NSNotFound && view != nil && view != _vwContent) {
        return [self _helper_FindIndexForView:view.superview];
    }
    return index;
}

- (UIView *)_helper_CreateContainerForView:(UIView *)view {
    // Set container frame
    CGRect frame = view.bounds;
    frame.size.width  = _viewW;
    frame.size.height = _viewH;
    __autoreleasing UIView *containerView = [[UIView alloc] initWithFrame:frame];
    
    // Add tap gesture recogniser
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)];
    [containerView addGestureRecognizer:tapGesture];
    [tapGesture setDelegate:self];
    FwiRelease(tapGesture);
    
    // Set view frame
    frame = view.frame;
    frame.origin.x = (containerView.bounds.size.width - frame.size.width) / 2.0f;
    frame.origin.y = (containerView.bounds.size.height - frame.size.height) / 2.0f;
    
    [view setFrame:frame];
    [containerView addSubview:view];
    
    return FwiAutoRelease(containerView);
}
- (UIView *)_helper_FindViewAtIndex:(NSUInteger)index {
    return [_viewHolder objectForKey:[NSNumber numberWithUnsignedInteger:index]];
}

- (void)_helper_InsertView:(UIView *)view atIndex:(NSInteger)index {
    [_viewHolder setObject:view forKey:[NSNumber numberWithInteger:index]];
}
- (void)_helper_SortDepth {
    @autoreleasepool {
        NSArray *views = [[_viewHolder allValues] sortedArrayUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
            CATransform3D t1 = view1.superview.layer.transform;
            CATransform3D t2 = view2.superview.layer.transform;
            CGFloat z1 = t1.m13 + t1.m23 + t1.m33 + t1.m43;
            CGFloat z2 = t2.m13 + t2.m23 + t2.m33 + t2.m43;
            CGFloat d  = z1 - z2;
            
            if (d == 0.0f) {
                UIView *view = [self currentView];
                CATransform3D t3 = view.superview.layer.transform;
                CGFloat x1 = t1.m11 + t1.m21 + t1.m31 + t1.m41;
                CGFloat x2 = t2.m11 + t2.m21 + t2.m31 + t2.m41;
                CGFloat x3 = t3.m11 + t3.m21 + t3.m31 + t3.m41;
                d = fabsf(x2 - x3) - fabsf(x1 - x3);
            }
            return (d < 0.0f) ? NSOrderedAscending: NSOrderedDescending;
        }];
        
        for (UIView *view in views) [_vwContent bringSubviewToFront:view.superview];
    }
}


#pragma mark - Class's private methods: layout views
- (void)_layout_TransformView {
    @autoreleasepool {
        NSArray *array = [self visibleIndexes];
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSNumber *number = (NSNumber *)obj;
            NSInteger index  = [number integerValue];
            
            UIView *view = [_viewHolder objectForKey:number];
            [self _layout_TransformView:view atIndex:index];
            [view setUserInteractionEnabled:(index == self.currentIndex)];
        }];
    }
}
- (void)_layout_TransformView:(UIView *)view atIndex:(NSInteger)index {
    // Calculate offset
    CGFloat offset = _convertIndex(index, _scrollOffset, _viewCount, _isRotable);
    view.superview.center = _vwContent.center;                      // Center view
    
    // If time machine, apply alpha
    if (_type == kCarouselType_TimeMachine || _type == kCarouselType_TimeMachineInverted) {
        view.superview.alpha  = _alphaForOffset(offset, _type);         // Update alpha
    }
    
    // Special case logic for kCarouselType_CoverFlow2
    CGFloat clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
    if (_isDecelerating             ||
        (_isScrolling && !_didDrag) ||
        (_scrollOffset - _rotateOffset(_scrollOffset, _viewCount, _isRotable)) != 0.0f)
    {
        if (offset > 0) _toggleDistance = (offset <= 0.5f) ? -clampedOffset : (1.0f - clampedOffset);
        else            _toggleDistance = (offset > -0.5f) ? -clampedOffset : (- 1.0f - clampedOffset);
    }
    
    // Layout view
    [self _layout_TransformView:view atOffset:offset];
}
- (void)_layout_TransformView:(UIView *)view atOffset:(CGFloat)offset {
    // Set up base transform
    CATransform3D transform3D = CATransform3DIdentity;
    transform3D.m34 = -0.002f;                                                                      // Perspective is an approximate representation, on a flat surface, of an image as it is seen by the eye
    
    // Perform transform
    CGFloat count     = _visibleCount;
    CGFloat spacing   = _spaceBetweenViews(_type, _viewW, _viewH, _isVertical);
    CGFloat viewWidth = !_isVertical ? _viewW : _viewH;
    switch(_type) {
        case kCarouselType_Linear: {
            transform3D = CATransform3DTranslate(transform3D, offset * viewWidth * spacing, 0.0f, 0.0f);
            break;
        }
            
        case kCarouselType_Rotary:
        case kCarouselType_RotaryInverted: {
            CGFloat arc    = 2.9f;
            CGFloat angle  = offset / count * arc;
            CGFloat radius = fmaxf(viewWidth * spacing / 2.0f, viewWidth * spacing / 2.0f / tanf(arc / 2.0f / count)) * 1.035593;
            
            // Perform changed for invert
            if (_type == kCarouselType_RotaryInverted) {
                radius = -radius;
                angle  = -angle;
            }
            
            if (_isVertical) transform3D = CATransform3DTranslate(transform3D, 0.0f, radius * sin(angle), radius * cos(angle) - radius);
            else transform3D = CATransform3DTranslate(transform3D, radius * sin(angle), 0.0f, radius * cos(angle) - radius);
            break;
        }
            
        case kCarouselType_Cylinder:
        case kCarouselType_CylinderInverted: {
            CGFloat arc    = _isRotable ? 6.25f : 3.5f;
            CGFloat radius = fmaxf(0.01f, viewWidth * spacing / 2.0f / tanf(arc / 2.0f / count));
            CGFloat angle  = offset / count * arc;
            
            // Perform changed for invert
            if (_type == kCarouselType_CylinderInverted) {
                radius = -radius;
                angle  = -angle;
            }
            
            if (_isVertical) {
                transform3D = CATransform3DTranslate(transform3D, 0.0f, 0.0f, -radius);
                transform3D = CATransform3DRotate(transform3D, angle, -1.0f, 0.0f, 0.0f);
                transform3D = CATransform3DTranslate(transform3D, 0.0f, 0.0f, radius + 0.01f);
            }
            else {
                transform3D = CATransform3DTranslate(transform3D, 0.0f, 0.0f, -radius);
                transform3D = CATransform3DRotate(transform3D, angle, 0.0f, 1.0f, 0.0f);
                transform3D = CATransform3DTranslate(transform3D, 0.0f, 0.0f, radius + 0.01f);
            }
            break;
        }
            
        case kCarouselType_Wheel:
        case kCarouselType_WheelInverted: {
            CGFloat arc    = 6.5f;
            CGFloat radius = (viewWidth * spacing * count / arc) * 1.284524;
            CGFloat angle  = arc / count;
            
            // Perform changed for invert
            if (_type == kCarouselType_WheelInverted) {
                radius = -radius;
                angle  = -angle;
            }
            
            if (_isVertical) {
                transform3D = CATransform3DTranslate(transform3D, -radius, 0.0f, 0.0f);
                transform3D = CATransform3DRotate(transform3D, angle * offset, 0.0f, 0.0f, 1.0f);
                transform3D = CATransform3DTranslate(transform3D, radius, 0.0f, offset * 0.01f);
            }
            else {
                transform3D = CATransform3DTranslate(transform3D, 0.0f, radius, 0.0f);
                transform3D = CATransform3DRotate(transform3D, angle * offset, 0.0f, 0.0f, 1.0f);
                transform3D = CATransform3DTranslate(transform3D, 0.0f, -radius, offset * 0.01f);
            }
            break;
        }
            
        case kCarouselType_CoverFlow1:
        case kCarouselType_CoverFlow2: {
            CGFloat tilt = 0.9f;
            CGFloat clampedOffset = fmaxf(-1.0f, fminf(1.0f, offset));
            
            // Special case for CoverFlow2
            if (_type == kCarouselType_CoverFlow2) {
                if (_toggleDistance >= 0.0f) {
                    if (offset <= -0.5f)     clampedOffset = -1.0f;
                    else if (offset <= 0.5f) clampedOffset = -_toggleDistance;
                    else if (offset <= 1.5f) clampedOffset = 1.0f - _toggleDistance;
                }
                else {
                    if (offset > 0.5f)       clampedOffset = 1.0f;
                    else if (offset > -0.5f) clampedOffset = -_toggleDistance;
                    else if (offset > -1.5f) clampedOffset = - 1.0f - _toggleDistance;
                }
            }
            
            CGFloat x = (clampedOffset * 0.5f * tilt + offset * spacing) * viewWidth;
            CGFloat z = fabsf(clampedOffset) * -viewWidth * 0.5f;
            
            if (_isVertical) {
                transform3D = CATransform3DTranslate(transform3D, 0.0f, x, z);
                transform3D = CATransform3DRotate(transform3D, -clampedOffset * M_PI_2 * tilt, -1.0f, 0.0f, 0.0f);
            }
            else {
                transform3D = CATransform3DTranslate(transform3D, x, 0.0f, z);
                transform3D = CATransform3DRotate(transform3D, -clampedOffset * M_PI_2 * tilt, 0.0f, 1.0f, 0.0f);
            }
            break;
        }
            
        case kCarouselType_TimeMachine:
        case kCarouselType_TimeMachineInverted: {
            CGFloat tilt = kCarousel_TimeMachineTilt;
            
            // Perform changed for invert
            if (_type == kCarouselType_TimeMachineInverted) {
                tilt   = -tilt;
                offset = -offset;
            }
            
            if (_isVertical) transform3D = CATransform3DTranslate(transform3D, 0.0f, offset * viewWidth * tilt, offset * viewWidth * spacing);
            else transform3D = CATransform3DTranslate(transform3D, offset * viewWidth * tilt, 0.0f, offset * viewWidth * spacing);
            break;
        }
            
        default:
            //shouldn't ever happen
            transform3D = CATransform3DIdentity;
    }
    
    // Apply transform3D
    view.superview.layer.transform = transform3D;
    
    // Backface culling
    BOOL showBackfaces = view.layer.doubleSided;
    if (showBackfaces) {
        switch (_type) {
            case kCarouselType_CylinderInverted: showBackfaces = NO ; break;
            default:                             showBackfaces = YES; break;
        }
    }
    view.superview.hidden = !(showBackfaces ? YES : (transform3D.m33 > 0.0f));
}


#pragma mark - Class's private methods: manage animation
- (void)_animDisable {
    _animDisableCounter++;
    if (_animDisableCounter == 1) [CATransaction setDisableActions:YES];
}
- (void)_animEnable {
    _animDisableCounter--;
    if (_animDisableCounter == 0) [CATransaction setDisableActions:NO];
}
- (void)_animStart {
    /* Condition validation */
    if (_timer) return;
    
    _timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0f/60.0f target:self selector:@selector(_viewAnim_NextFrame) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}
- (void)_animStop {
    /* Condition validation */
    if (!_timer) return;
    
    [_timer invalidate];
    FwiRelease(_timer);
}


#pragma mark - Class's private methods: manage view
- (UIView *)_management_DequeueView {
    __autoreleasing UIView *view = FwiAutoRelease([_viewPool anyObject]);
    if (view) [_viewPool removeObject:view];
    return view;
}
- (UIView *)_management_LoadViewAtIndex:(NSInteger)index {
    [self _animDisable];
    
    // Load view at index
    UIView *view = [_datasource carousel:self viewAtIndex:index reusingView:[self _management_DequeueView]];
    UIView *container = [self _helper_CreateContainerForView:view];
    
    // Create reflection image
    CGFloat alpha = 0.6f;
    CGRect  frame = container.bounds;
    frame.origin.y    += frame.size.height + 5.0f; // Give 5 more pixels
    frame.size.height *= 0.6f;
    
    UIImageView *imvReflection = [[UIImageView alloc] initWithFrame:frame];
    [imvReflection setImage:[UIImage reflectedImageWithView:view height:frame.size.height]];
    [imvReflection setAlpha:alpha];
    
    [container addSubview:imvReflection];
    [container sendSubviewToBack:imvReflection];
    FwiRelease(imvReflection);
    
    // Layout new view
    [self _layout_TransformView:view atIndex:index];
    
    // Add view into carousel
    [self _helper_InsertView:view atIndex:index];
    [_vwContent addSubview:container];
    
    [self _animEnable];
    return view;
}

- (void)_management_QueueView:(UIView *)view {
    if (!view) return;
    [_viewPool addObject:view];
}
- (void)_management_UpdateVisibleCount {
    CGFloat spaceFactor   = _spaceBetweenViews(_type, _viewW, _viewH, _isVertical);
    CGFloat carouselWidth = _carouselWidth(_vwContent, _isVertical);
    CGFloat viewWidth     = !_isVertical ? _viewW : _viewH;
    
    // The views will be line up either vertical or horizontal, we just need to fill  up  the  space
    // until there is no more space left.
    //
    // Note: We always devide by two to get the most accuracy left side and right side plus the  one
    // in the middle.
    CGFloat spaceTaken = spaceFactor * viewWidth;
    switch(_type) {
        case kCarouselType_Linear: {
            _visibleCount = ceilf(((carouselWidth - spaceTaken) / 2) / spaceTaken) * 2 + 1;
            break;
        }
            
        case kCarouselType_CoverFlow1:
        case kCarouselType_CoverFlow2: {
            _visibleCount = ceilf(((carouselWidth - viewWidth) / 2) / spaceTaken) * 2 + 3;
            break;
        }
            
        case kCarouselType_Cylinder:
        case kCarouselType_Rotary: {
            _visibleCount = _circularViewCount();
            break;
        }
            
        case kCarouselType_CylinderInverted:
        case kCarouselType_RotaryInverted: {
            _visibleCount = ceilf(_circularViewCount() / 2.0f);
            break;
        }
            
        case kCarouselType_Wheel:
        case kCarouselType_WheelInverted: {
            CGFloat count  = _circularViewCount();
            CGFloat arc    = M_PI * 2.0f;   // ???
            CGFloat radius = _viewW * spaceFactor * count / arc;
            
            if (radius - _viewW / 2.0f < MIN(self.bounds.size.width, self.bounds.size.height) / 2.0f) {
                _visibleCount = count;
            }
            else {
                _visibleCount = ceilf(count / 2.0f) + 1;
            }
            break;
        }
            
        case kCarouselType_TimeMachine:
        case kCarouselType_TimeMachineInverted:
        default: {
            _visibleCount = 10;
            break;
        }
    }
    _visibleCount = MIN(MAX(_visibleCount, 0), _viewCount);
}
- (void)_management_UpdateVisibleViews {
    [self _animDisable];
    
    NSMutableSet *visibleIndices = [[NSMutableSet alloc] initWithCapacity:_visibleCount];
    NSInteger min = 0;
    NSInteger max = _viewCount - 1;
    NSInteger beginOffset = self.currentIndex - (_visibleCount / 2);
    
    if (!_isRotable) beginOffset = MAX(min, MIN(max - _visibleCount + 1, beginOffset));
    for (NSInteger i = 0; i < _visibleCount; i++) {
        NSInteger index = _rotateIndex(i + beginOffset, _viewCount, _isRotable);
        
        if (_type == kCarouselType_TimeMachine || _type == kCarouselType_TimeMachineInverted) {
            CGFloat alpha = _alphaForOffset(_convertIndex(index, _scrollOffset, _viewCount, _isRotable), _type);
            if (alpha) [visibleIndices addObject:[NSNumber numberWithInteger:index]];
        }
        else {
            [visibleIndices addObject:[NSNumber numberWithInteger:index]];
        }
    }
    
    // Remove offscreen views
    NSArray *keys = [_viewHolder allKeys];
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![visibleIndices containsObject:(NSNumber *)obj]) {
            UIView *view = FwiRetain([_viewHolder objectForKey:(NSNumber *)obj]);
            [_viewHolder removeObjectForKey:(NSNumber *)obj];
            
            [self _management_QueueView:view];
            [view.superview removeFromSuperview];
            FwiRelease(view);
        }
    }];
    
    // Add onscreen views
    for (NSNumber *number in visibleIndices) {
        UIView *view = [_viewHolder objectForKey:number];
        if (view == nil) [self _management_LoadViewAtIndex:[number integerValue]];
    }
    FwiRelease(visibleIndices);
    [self _animEnable];
}


#pragma mark - Class's private methods: view's animation handler
- (BOOL)_viewAnim_ShouldDecelerate {
    return (fabsf(_startVelocity) > kCarousel_Threshold_ScrollSpeed) && (fabsf(_distanceDeceleration(_startVelocity)) > kCarousel_Threshold_Decelerate);
}
- (void)_viewAnim_StartDecelerating {
    // Calculate deceleration distance
    CGFloat decelerationDistance = _distanceDeceleration(_startVelocity);
    
    // Canculate start & end offset
    _startOffset = _scrollOffset;
    _endOffset   = _startOffset + decelerationDistance;
    
    // Calculate destination offset when stop dragging
    if (decelerationDistance > 0.0f) _endOffset = ceilf(_endOffset);
    else _endOffset = floorf(_endOffset);
    
    // Limit destination offset to boundary offset if wrap is not enable
    if (!_isRotable) {
        if (_isBouncing) _endOffset = fmaxf(-kCarousel_BounceDistance, fminf(_viewCount - 1.0f + kCarousel_BounceDistance, _endOffset));
        else _endOffset = _rotateOffset(_endOffset, _viewCount, _isRotable);
    }
    
    // Calculate final distance
    decelerationDistance = _endOffset - _startOffset;
    
    // Calculate scroll duration
    _startTime = CACurrentMediaTime();
    _scrollDuration = fabsf(decelerationDistance) / fabsf(0.5f * _startVelocity);
    
    if (decelerationDistance != 0.0f) {
        _isDecelerating = YES;
        [self _animStart];
    }
}
- (void)_viewAnim_DidScroll {
    // Calculate scrollOffset
    if (_isRotable || !_isBouncing) {
        _scrollOffset = _rotateOffset(_scrollOffset, _viewCount, _isRotable);
    }
    else {
        CGFloat min = -kCarousel_BounceDistance;
        CGFloat max = fmaxf(_viewCount - 1, 0.0f) + kCarousel_BounceDistance;
        
        if (_scrollOffset < min) {
            _scrollOffset  = min;
            _startVelocity = 0.0f;
        }
        else if (_scrollOffset > max) {
            _scrollOffset  = max;
            _startVelocity = 0.0f;
        }
    }
    
    //check if index has changed
    NSInteger currentIndex = roundf(_scrollOffset);
    NSInteger distance = _distanceBetweenIndexes(_prevIdx, currentIndex, _viewCount, _isRotable);
    
    // Perform change to new index animation for coverflow2
    if (distance != 0 && _type == kCarouselType_CoverFlow2) {
        _startToggleTime = CACurrentMediaTime();
        _toggleDistance = fmaxf(-1.0f, fminf(1.0f, -(CGFloat)distance));
        
        [self _animStart];
    }
    
    [self _management_UpdateVisibleViews];
    [self _layout_TransformView];
    
    if (_prevIdx != self.currentIndex) {
        if (_delegate && [_delegate respondsToSelector:@selector(carousel:changedToViewAtIndex:)])
            [_delegate carousel:self changedToViewAtIndex:self.currentIndex];
    }
    
    //update previous index
    _prevIdx = currentIndex;
}
- (void)_viewAnim_NextFrame {
    [self _animDisable];
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    // Special case for coverflow2
    if (_toggleDistance != 0.0f && _type == kCarouselType_CoverFlow2) {
        NSTimeInterval toggleDuration = 0.3f;
        NSTimeInterval time = fminf(1.0f, (currentTime - _startToggleTime) / toggleDuration);
        time = _animationTime(time);
        
        _toggleDistance = (_toggleDistance < 0.0f) ? (time - 1.0f) : (1.0f - time);
        [self _viewAnim_DidScroll];
    }
    
    if (_isScrolling) {
        NSTimeInterval time = fminf(1.0f, (currentTime - _startTime) / _scrollDuration);
        time = _animationTime(time);
        
        _scrollOffset = _startOffset + (_endOffset - _startOffset) * time;
        [self _viewAnim_DidScroll];
        
        if (time == 1.0f) {
            _isScrolling = NO;
            [self _helper_SortDepth];
        }
    }
    else if (_isDecelerating) {
        CGFloat time = fminf(_scrollDuration, currentTime - _startTime);
        CGFloat acceleration = -_startVelocity / _scrollDuration;                                   // Calculate decelerate value
        CGFloat distance = _startVelocity * time + 0.5f * acceleration * powf(time, 2.0f);          // Calculate distance
        _scrollOffset = _startOffset + distance;
        
        [self _viewAnim_DidScroll];
        if (time == (CGFloat)_scrollDuration) {
            _isDecelerating = NO;
            CGFloat offset = _scrollOffset - _rotateOffset(_scrollOffset, _viewCount, _isRotable);
            
            if (offset != 0.0f) {
                [self scrollToViewAtIndex:self.currentIndex];
            }
            else {
                CGFloat difference = (CGFloat)self.currentIndex - _scrollOffset;
                
                if (difference > 0.5) difference = difference - 1.0f;
                else if (difference < -0.5) difference = 1.0 + difference;
                
                _startToggleTime = currentTime - kCarousel_ToggleDuration * fabsf(difference);
                _toggleDistance = fmaxf(-1.0f, fminf(1.0f, -difference));
            }
        }
    }
    else if (_toggleDistance == 0.0f) {
        [self _animStop];
        
        if (_completionBlock) _completionBlock(YES);
        FwiRelease(_completionBlock);
    }
    
    [self _animEnable];
}


#pragma mark - UIGestureRecognizerDelegate's members
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    /* Condition validation */
    if (!_enableScroll) return NO;
    
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        // Ignore vertical swipes
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
        CGPoint translation = [panGesture translationInView:self];
        
        if (_isVertical) return fabsf(translation.x) <= fabsf(translation.y);
        else return fabsf(translation.x) >= fabsf(translation.y);
    }
    else return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    /* Condition validation */
    if (!_enableScroll) return NO;
    
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        // Handle tap
        NSInteger index = [self _helper_FindIndexForView:touch.view];
        if (index == NSNotFound) {                                                                  // View is a container view
            index = [self _helper_FindIndexForView:[touch.view.subviews lastObject]];
        }
        
        if (index != NSNotFound) {
            if ([touch.view rootView:_vwContent isKindOfClasses:[UIControl class], [UITableViewCell class], nil])
                return NO;
        }
    }
    else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        if ([touch.view rootView:_vwContent isKindOfClasses:[UISlider class], [UISwitch class], nil])
            return NO;
    }
    
    return YES;
}

@end