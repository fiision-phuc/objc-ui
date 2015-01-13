#import "FwkTable.h"


#define kTable_BounceDistance            0.5f
#define kTable_ScrollDuration            0.5f
#define kTable_Threshold_Decelerate      0.1f
#define kTable_Threshold_ScrollSpeed     1.5f


@interface FwkTable () <UIGestureRecognizerDelegate> {

    UIPanGestureRecognizer *_panGesture;
    UIView                 *_vwContent;
    NSTimer                *_timer;
    
    NSInteger              _disableCount;
    CompletionBlock        _completionBlock;
    
    // Event indicators
    BOOL    _didDrag;
    BOOL    _isDragging;
    BOOL    _isScrolling;
    BOOL    _isDecelerating;
    
    // Offset variables
    CGFloat _endOffset;
    CGFloat _startOffset;
    CGFloat _scrollOffset;
    
    // Physic variables
    CGFloat _startTime;
    CGFloat _startVelocity;
    CGFloat _scrollDuration;
}

@property (nonatomic, readonly) NSInteger maxIndex;
@property (nonatomic, readonly) NSInteger beginIndex;
@property (nonatomic, assign)   NSInteger previousIndex;


/**
 * Initialize class's private variables
 */
- (void)_init;
/**
 * Visualize all view's components
 */
- (void)_visualize;


/**
 * Ask user for custom value for option, also this is centralize all parameters that  will  be  used
 * for this control
 */
- (CGFloat)_valueForOption:(FwkTableOption)option;


/**
 * Temporary disable animation
 */
- (void)_animation_Disable;
/**
 * Enable animation
 */
- (void)_animation_Enable;

/**
 * Start animation
 */
- (void)_animation_Start;
/**
 * Stop animation
 */
- (void)_animation_Stop;

/**
 * Check if table should perform decelerate action after user dragged
 */
- (BOOL)_animation_ShouldDecelerate;
/**
 * Perform decelerating
 */
- (void)_animation_StartDecelerating;

/**
 * Setup all variables value for next frame
 */
- (void)_animation_NextFrame;

/**
 * Scroll to specific index
 */
- (void)_animation_ScrollToIndex:(NSUInteger)index;
- (void)_animation_ScrollToIndex:(NSUInteger)index completion:(void(^)(BOOL finished))completion;


/**
 * Update all parameters after scrollOffset value changed
 */
- (void)_layout_ItemsScrolled;
/**
 * Apply transform for all items
 */
- (void)_layout_TransformItem;
/**
 * Apply transform for item at index
 */
- (void)_layout_TransformItem:(UIView *)item atIndex:(NSUInteger)index;
/**
 * Apply transform for item at offset
 */
- (void)_layout_TransformItem:(UIView *)item atOffset:(CGFloat)offset;


/**
 * Retrieve a queue item from queue pool
 */
- (UIView *)_management_DequeueItem;
/**
 * Queue offscreen item
 */
- (void)_management_QueueItem:(UIView *)item;


/**
 * Create container for item
 */
- (UIView *)_management_ContainerForItem:(UIView *)item;
/**
 * Load item at index
 */
- (UIView *)_management_LoadItemAtIndex:(NSUInteger)index;
/**
 * Insert item into table at index
 */
- (void)_management_InsertItem:(UIView *)item atIndex:(NSUInteger)index;


/**
 * Update number of visible items within view container
 */
- (void)_management_UpdateVisibleCount;
/**
 * Update visible items within table
 */
- (void)_management_UpdateVisibleItems;


/**
 * Handle drag event
 */
- (void)_handlePan:(UIPanGestureRecognizer *)gesture;


/**
 * Update layout everytime device changes orientation
 */
- (void)_updateOrientation:(NSNotification *)notification;

@end


@implementation FwkTable


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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FwiRelease(_itemHolder);
    FwiRelease(_itemQueue);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self _visualize];
    
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
        FwiRelease(_panGesture);
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [_vwContent setFrame:self.bounds];
}


#pragma mark - Class's properties
- (NSInteger)maxIndex {
    NSInteger maxIndex = _itmCnt - _visibleCount + 2;
    return MAX(0, maxIndex);
}
- (NSInteger)beginIndex {
    NSInteger beginIndex = MAX(0, floorf(_scrollOffset));
    return beginIndex;
}

- (void)setDatasource:(id<FwkTableDataSource>)datasource {
    if (_datasource == datasource) return;
    
    _datasource = datasource;
    [self reload];
}

- (void)setIsRotable:(BOOL)isRotable {
    _isRotable = isRotable;
    [self render];
}


#pragma mark - Class's public methods
- (NSArray *)visibleIndexes {
    return [[_itemHolder allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)visibleItems {
    return [_itemHolder objectsForKeys:[self visibleIndexes] notFoundMarker:[NSNull null]];
}

- (void)reload {
    // Stop reloading if datasource is no longer available
    if (!_datasource) return;
    
    // Re-initial all parameters
    _itmCnt = [_datasource itemCount:self];
    _itmW   = [_datasource respondsToSelector:@selector(itemWidth:)] ? [_datasource itemWidth:self] : 0.0f;
    
    // Additional step: load item's width & height if it is not yet defined
    if (_itmW == 0.0f) {
        UIView *item = [self _management_LoadItemAtIndex:0];
        _itmW = item.superview.frame.size.width;
        
        [item.superview removeFromSuperview];
        [self _management_QueueItem:item];
        [_itemHolder removeAllObjects];
    }
    
    // Create new item collection
    _itemHolder = [[NSMutableDictionary alloc] initWithCapacity:0];
    _itemQueue  = [[NSMutableSet alloc] initWithCapacity:_itmCnt];
    
    // Insert item view container
    [self _management_UpdateVisibleCount];
    
    // Render all subviews
    _scrollOffset  = 0.0f;
    _previousIndex = 0;
    [self render];
}
- (void)render {
    // Stop rendering if datasource is no longer available
    if (!_datasource) return;
    
    [self _management_UpdateVisibleItems];  // Load visible items
    [self _layout_ItemsScrolled];           // Update views
}

- (void)insertItem {
    [self insertItemWithCompletion:nil];
}
- (void)insertItemWithCompletion:(CompletionBlock)completion {
    __block NSInteger idx = _itmCnt;
    
    // Ask user's permission to remove item
    BOOL shouldInsert = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(table:shouldInsertItemAtIndex:)])
        shouldInsert = [_delegate table:self shouldInsertItemAtIndex:idx];

    /* Condition validation: Should not insert new item if user say no */
    if (!shouldInsert) return;

    
    // Update visible items first
    _itmCnt++;
    UIView *newItem = [self _management_LoadItemAtIndex:idx];
    newItem.superview.layer.opacity = 0.0f;

    // Notify user item will be removed
    if (_delegate) [_delegate table:self willInsertItem:newItem atIndex:idx];
    
    // Copy completion block
    __block CompletionBlock block1 = [completion copy];
    __block CompletionBlock block2 = [^(BOOL finished) {
        if (_delegate) [_delegate table:self didInsertItem:newItem atIndex:idx];
        if (block1) block1(finished);
        FwiRelease(block1);
    } copy];

    // Always scroll to last index
    NSUInteger index = self.maxIndex;
    [self _animation_ScrollToIndex:index completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             newItem.superview.layer.opacity = 1.0f;
                         }
                         completion:^(BOOL finished) {
                             if (block2) block2(finished);
                             FwiRelease(block2);
                         }];
    }];
}

- (void)removeItem {
    if (_itmCnt == 0) return;
    [self removeItemAtIndex:(_itmCnt - 1)];
}
- (void)removeItemAtIndex:(NSInteger)index {
    [self removeItemAtIndex:index completion:nil];
}
- (void)removeItemAtIndex:(NSInteger)index completion:(CompletionBlock)completion {
    /* Condition validation: If */
    if (index >= _itmCnt) { if (completion) completion(YES); return; }
    __block UIView *item = [_itemHolder objectForKey:[NSNumber numberWithInteger:index]];
    
    // Ask user's permission to remove item
    BOOL shouldRemove = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(table:shouldRemoveItem:atIndex:)])
        shouldRemove = [_delegate table:self shouldRemoveItem:item atIndex:index];
    
    /* Condition validation: Should not remove item if user say no */
    if (!shouldRemove) return;
    
    __block CompletionBlock block1 = [completion copy];
    __block CompletionBlock block2 = [^(BOOL finished) {
        if (_delegate) [_delegate table:self didRemoveItem:item atIndex:index];    
        if (block1) block1(finished);
        FwiRelease(block1);
    } copy];
    
    
    // Notify user item will be removed
    if (_delegate) [_delegate table:self willRemoveItem:item atIndex:index];
    
    [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         if (item) item.superview.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         if (item) [self _management_QueueItem:item];
                         if (item) [item.superview removeFromSuperview];
                         
                         _itmCnt--;
                         _scrollOffset = self.beginIndex;
                         
                         // Create new itemHolder
                         NSMutableDictionary *newItemHolder = [[NSMutableDictionary alloc] initWithCapacity:([_itemHolder count] - 1)];
                         NSArray *visibleIndexes = [self visibleIndexes];
                         
                         [visibleIndexes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                             NSInteger i = [(NSNumber *)obj integerValue];
                             
                             if (i > index) [newItemHolder setObject:[_itemHolder objectForKey:obj] forKey:[NSNumber numberWithInteger:i - 1]];
                             else if (i < index) [newItemHolder setObject:[_itemHolder objectForKey:obj] forKey:obj];
                         }];
                         FwiRelease(_itemHolder);
                         _itemHolder = newItemHolder;
                         
                         // Update visible items
                         [self _management_UpdateVisibleItems];
                         [UIView animateWithDuration:0.2f
                                          animations:^{
                                              [self _layout_TransformItem];
                                          }
                                          completion:^(BOOL finished) {
                                              if (block2) block2(finished);
                                              FwiRelease(block2);
                                          }];
                     }];
}


#pragma mark - Class's private methods
- (void)_init {
    _datasource   = nil;
    _delegate     = nil;
    _enableScroll = YES;
    _isBouncing   = YES;
    _isRotable    = NO;
    
    _scrollOffset = 0.0f;
    _disableCount = 0;
    
    _didDrag        = NO;
    _isDragging     = NO;
    _isScrolling    = NO;
    _isDecelerating = NO;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updateOrientation:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}
- (void)_visualize {
}

- (CGFloat)_valueForOption:(FwkTableOption)option {
    CGFloat defaultValue = 0.0f;
    
    // Define default value
    switch (option) {
        case kTableOption_SpaceFactor:
            defaultValue = 1.1f;
            break;
            
        default:
            break;
    }
    
    // Ask user's approval for option value
    if (_delegate && [_delegate respondsToSelector:@selector(table:valueForOption:defaultValue:)]) {
        defaultValue = [_delegate table:self valueForOption:option defaultValue:defaultValue];
    }
    return defaultValue;
}


#pragma mark - Class's private methods: animation management
- (void)_animation_Disable {
    _disableCount++;
    if (_disableCount == 1)
        [CATransaction setDisableActions:YES];
}
- (void)_animation_Enable {
    _disableCount--;
    
    if (_disableCount == 0)
        [CATransaction setDisableActions:NO];
}

- (void)_animation_Start {
    /* Condition validation */
    if (_timer) return;
    
    _timer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                      interval:1.0f/60.0f
                                        target:self
                                      selector:@selector(_animation_NextFrame)
                                      userInfo:nil
                                       repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
}
- (void)_animation_Stop {
    /* Condition validation */
    if (!_timer) return;
    
    [_timer invalidate];
    FwiRelease(_timer);
}

- (BOOL)_animation_ShouldDecelerate {
    CGFloat startVelocity = fabsf(_startVelocity);
    CGFloat decelerationDistance = FwkCalculateDecelerationDistance(_startVelocity);
    
    // Canculate start & end offset
    _startOffset = _scrollOffset;
    _endOffset   = _startOffset + decelerationDistance;
    
    // Finalize end offset
    if (decelerationDistance > 0.0f) _endOffset = ceilf(_endOffset);
    else _endOffset = floorf(_endOffset);
    
    // Limit destination offset to boundary
    if (!_isRotable) {
        if (_isBouncing) _endOffset = fmaxf(-kTable_BounceDistance, fminf(_endOffset, (self.maxIndex + kTable_BounceDistance)));
        else _endOffset = fmaxf(0.0f, fminf(_endOffset, (_itmCnt - _visibleCount)));
    }
    
    // Calculate final distance
    decelerationDistance = fabsf(_endOffset - _startOffset);
    
    return ((startVelocity > kTable_Threshold_ScrollSpeed) &&
            (decelerationDistance > kTable_Threshold_Decelerate));
}
- (void)_animation_StartDecelerating {
    // Calculate deceleration distance
    CGFloat decelerationDistance = FwkCalculateDecelerationDistance(_startVelocity);
    
    // Canculate start & end offset
    _startOffset = _scrollOffset;
    _endOffset   = _startOffset + decelerationDistance;
    
    // Finalize end offset
    if (decelerationDistance > 0.0f) _endOffset = ceilf(_endOffset);
    else _endOffset = floorf(_endOffset);
    
    // Limit destination offset to boundary
    if (!_isRotable) {
        if (_isBouncing) _endOffset = fmaxf(-kTable_BounceDistance, fminf(_endOffset, (self.maxIndex + kTable_BounceDistance)));
        else _endOffset = fmaxf(0.0f, fminf(_endOffset, (_itmCnt - _visibleCount)));
    }
    
    // Calculate final distance
    decelerationDistance = _endOffset - _startOffset;
    
    // Calculate scroll duration
    _startTime = CACurrentMediaTime();
    _scrollDuration = fabsf(decelerationDistance) / fabsf(0.5f * _startVelocity);
    
    // Start decelerate if distance is not zero
    if (decelerationDistance && _scrollDuration) [self _animation_Start];
}

- (void)_animation_NextFrame {
    NSTimeInterval currentTime = CACurrentMediaTime();
    
    if (_isDecelerating) {
        // Calculate distance
        CGFloat time         = fminf(_scrollDuration, (currentTime - _startTime));
        CGFloat deceleration = -_startVelocity / _scrollDuration;                                   // Calculate decelerate value
        CGFloat distance     = _startVelocity * time + 0.5f * deceleration * powf(time, 2.0f);      // Calculate distance
        
        // Calculate scroll offset
        _scrollOffset = _startOffset + distance;
        [self _layout_ItemsScrolled];
        
        if (time >= _scrollDuration) {
            _didDrag        = NO;
            _isDragging     = NO;
            _isScrolling    = NO;
            _isDecelerating = NO;
            
            // Fix position for all visible items
            CGFloat offset     = _scrollOffset - FwiRotateOffset(_scrollOffset, _itmCnt, _isRotable);
            CGFloat difference = fabsf(self.beginIndex - _scrollOffset);
            if (offset || difference) {
                [self _animation_ScrollToIndex:self.beginIndex];
            }
        }
    }
    else if (_isScrolling) {
        NSTimeInterval time = fminf(1.0f, (currentTime - _startTime) / _scrollDuration);
        time = FwkCalculateAnimationTime(time);
        
        // Calculate scroll offset
        _scrollOffset = _startOffset + (_endOffset - _startOffset) * time;
        [self _layout_ItemsScrolled];
        
        if (time == 1.0f) {
            _didDrag        = NO;
            _isDragging     = NO;
            _isScrolling    = NO;
            _isDecelerating = NO;
        }
    }
    
    // Check if animation is completely finished
    if (!(_didDrag || _isDragging || _isScrolling || _isDecelerating)) {
        [self _animation_Stop];
        
        if (_completionBlock) _completionBlock(YES);
        FwiRelease(_completionBlock);
    }
}
- (void)_animation_ScrollToIndex:(NSUInteger)index {
    [self _animation_ScrollToIndex:index completion:nil];
}
- (void)_animation_ScrollToIndex:(NSUInteger)index completion:(void(^)(BOOL finished))completion {
    // Control scroll flags
    _isScrolling    = YES;
    _didDrag        = NO;
    _isDragging     = NO;
    _isDecelerating = NO;
    
    // Setup scrollOffset
    _startOffset = _scrollOffset;
    _endOffset   = _startOffset + FwkCalculateDistanceBetweenOffsets(_scrollOffset, index, _itmCnt, _isRotable);
    if (!_isRotable) _endOffset = FwiRotateOffset(_endOffset, _itmCnt, _isRotable);
    
    // Setup animation time
    _startTime      = CACurrentMediaTime();
    _scrollDuration = kTable_ScrollDuration;
    
    // Prepare completion action
    if (_completionBlock) _completionBlock(YES);
    FwiRelease(_completionBlock);
    
    __block CompletionBlock block = nil;
    if (completion) block = [completion copy];
    
    _completionBlock = [^(BOOL finished) {
        //        if (_delegate && [_delegate respondsToSelector:@selector(carousel:didScrollToViewAtIndex:)])
        //            [_delegate carousel:self didScrollToViewAtIndex:index];
        
        if (block) block(finished);
        FwiRelease(block);
    } copy];
    
    // Perform scroll animation if neccessary
    if (_startOffset != _endOffset) [self _animation_Start];
    else {
        _isScrolling    = NO;
        _didDrag        = NO;
        _isDragging     = NO;
        _isDecelerating = NO;
        if (_completionBlock) _completionBlock(YES);
        FwiRelease(_completionBlock);
    }
}


#pragma mark - Class's private methods: layout management
- (void)_layout_ItemsScrolled {
    if (_isRotable || !_isBouncing) {
        _scrollOffset = FwiRotateOffset(_scrollOffset, _itmCnt, _isRotable);
    }
    else {
        CGFloat min = -kTable_BounceDistance;
        CGFloat max = fmaxf(0.0f, self.maxIndex) + kTable_BounceDistance;
        
        if (_scrollOffset < min) {
            _scrollOffset  = min;
            _startVelocity = 0.0f;
        }
        else if (_scrollOffset > max) {
            _scrollOffset  = max;
            _startVelocity = 0.0f;
        }
    }
    
    // Only update visible items when needed
    if (self.previousIndex != self.beginIndex) {
        [self _management_UpdateVisibleItems];
        self.previousIndex = self.beginIndex;
    }
    
    // Layout all visible items
    [self _layout_TransformItem];
}
- (void)_layout_TransformItem {
    [_itemHolder enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, UIView *item, BOOL *stop) {
        [self _layout_TransformItem:item atIndex:index.unsignedIntegerValue];
    }];
}
- (void)_layout_TransformItem:(UIView *)item atIndex:(NSUInteger)index {
    // Calculate offset
    CGFloat offset = FwkOffsetForIndex(index, _scrollOffset, _itmCnt, _isRotable);
    [self _layout_TransformItem:item atOffset:offset];
}
- (void)_layout_TransformItem:(UIView *)item atOffset:(CGFloat)offset {
    // Set center
    CGFloat factor = [self _valueForOption:kTableOption_SpaceFactor];
    CGPoint center = _vwContent.center;
    center.x = (_itmW * factor) / 2;
    item.superview.center = center;
    
    // Transform 3D
    CATransform3D transform3D = CATransform3DIdentity;
    
    CGFloat tx  = offset * _itmW * [self _valueForOption:kTableOption_SpaceFactor];
    transform3D = CATransform3DMakeTranslation(tx, 0.0f, 0.0f);
    
    // Apply transform3D
    [item.superview.layer setTransform:transform3D];
}


#pragma mark - Class's private methods: items management
- (UIView *)_management_DequeueItem {
    __autoreleasing UIView *item = FwiAutoRelease([_itemQueue anyObject]);
    if (item) [_itemQueue removeObject:item];
    return item;
}
- (void)_management_QueueItem:(UIView *)item {
    if (!item) return;
    [_itemQueue addObject:item];
}

- (UIView *)_management_ContainerForItem:(UIView *)item {
    // Set container frame
    CGRect containerFrame = item.bounds;
    
    __autoreleasing UIView *vwContainer = FwiAutoRelease([[UIView alloc] initWithFrame:containerFrame]);
    [vwContainer setBackgroundColor:[UIColor clearColor]];
    
//    // Add tap gesture recogniser
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)];
//    [containerView addGestureRecognizer:tapGesture];
//    [tapGesture setDelegate:self];
//    [tapGesture release];
    
    // Add item into container
    [item setCenter:vwContainer.center];
    [vwContainer addSubview:item];
    return vwContainer;
}
- (UIView *)_management_LoadItemAtIndex:(NSUInteger)index {
    // Load view at index
    UIView *item = [_datasource table:self itemAtIndex:index reusingItem:[self _management_DequeueItem]];
    UIView *container = [self _management_ContainerForItem:item];
    
    // Add view into table
    [self _management_InsertItem:item atIndex:index];
    [self _layout_TransformItem:item atIndex:index];
    [_vwContent addSubview:container];
    
    return item;
}
- (void)_management_InsertItem:(UIView *)item atIndex:(NSUInteger)index {
    [_itemHolder setObject:item forKey:[NSNumber numberWithInteger:index]];
}

- (void)_management_UpdateVisibleCount {
    CGFloat spaceFactor = [self _valueForOption:kTableOption_SpaceFactor];
    CGFloat tableWidth  = _vwContent.bounds.size.width;
    CGFloat viewWidth   = _itmW * spaceFactor;

    _visibleCount = ceilf(tableWidth / viewWidth) + 1;
}
- (void)_management_UpdateVisibleItems {
    [self _animation_Disable];

    NSMutableSet *visibleIndices = [[NSMutableSet alloc] initWithCapacity:_visibleCount];
    NSUInteger step = MIN(_itmCnt, _visibleCount);
    
    for (NSInteger i = 0; i < step; i++) {
        NSUInteger index = FwiRotateIndex(self.beginIndex + i, _itmCnt, _isRotable);
        [visibleIndices addObject:[NSNumber numberWithInteger:index]];
    }
    
    // Remove offscreen items
    NSArray *keys = [_itemHolder allKeys];
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![visibleIndices containsObject:obj]) {
            UIView *item = FwiRetain([_itemHolder objectForKey:obj]);
            [_itemHolder removeObjectForKey:obj];
            
            [item.superview removeFromSuperview];
            [self _management_QueueItem:item];
            FwiRelease(item);
        }
    }];
    
    // Add onscreen views
    [visibleIndices enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UIView *item = [_itemHolder objectForKey:obj];
        if (!item) [self _management_LoadItemAtIndex:[(NSNumber *)obj unsignedIntegerValue]];
    }];
    
    FwiRelease(visibleIndices);
    [self _animation_Enable];
}


#pragma mark - Class's private methods: gesture handlers
- (void)_handlePan:(UIPanGestureRecognizer *)gesture {
    /* Condition validation */
    if (!_enableScroll) return;
    
    // Get physical info
    CGPoint v = [gesture velocityInView:self];      // Velocity
    CGPoint t = [gesture translationInView:self];   // Translation
    CGFloat w = _itmW * [self _valueForOption:kTableOption_SpaceFactor];
    
    // Handle gesture state
    switch ([gesture state]) {
        case UIGestureRecognizerStateBegan: {
            _isDragging     = YES;
            _didDrag        = NO;
            _isScrolling    = NO;
            _isDecelerating = NO;
            break;
        }
        
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            _didDrag        = YES;
            _isDragging     = NO;
            _isScrolling    = NO;
            _isDecelerating = NO;
            
            // Validate if user is using swip or not
            CGFloat translationFactor = FwkCalculateTranslationFactor(_scrollOffset, kTable_BounceDistance, _itmCnt, _isBouncing, NO);
            _startVelocity = FwkCalculateTranslationVelocity(v, translationFactor, w, NO);
            
            // Validate velocity to decide we should decelerate or not
            if ([self _animation_ShouldDecelerate]) {
                _didDrag        = NO;
                _isDragging     = NO;
                _isScrolling    = NO;
                _isDecelerating = YES;
                [self _animation_StartDecelerating];
            }
            
            // If user is not using swip, return to original index
            if (!_isDecelerating) {
                [self _animation_ScrollToIndex:self.beginIndex];
            }
            break;
        }
            
        default: {
            CGFloat translation = t.x;
            CGFloat translationFactor = FwkCalculateTranslationFactor(_scrollOffset, kTable_BounceDistance, _itmCnt, _isBouncing, NO);
            
            _scrollOffset -= translation * translationFactor / w;
            [self _layout_ItemsScrolled];
            break;
        }
    }
    
    // Reset translation value
    [gesture setTranslation:CGPointZero inView:self];
}


#pragma mark - Class's notification handlers
- (void)_updateOrientation:(NSNotification *)notification {
    // Insert item view container
    [self _management_UpdateVisibleCount];
    [self render];
}


#pragma mark - UIGestureRecognizerDelegate's members
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        /* Condition validation: do not scroll if this flag is turn off */
        if (!_enableScroll) return NO;
        
        /* Condition validation: do not scroll if item count is less than visible items */
        if (_itmCnt < (_visibleCount - 1)) return NO;
        
        UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gesture;
        CGPoint t = [panGesture translationInView:self];
        
        BOOL shouldBegin = (fabsf(t.x) >= fabsf(t.y));
        return shouldBegin;
    }
    else return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    /* Condition validation */
    if (!_enableScroll) return NO;
    
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        if ([touch.view rootView:_vwContent isKindOfClasses:[UISlider class], [UISwitch class], nil])
            return NO;
    }
    return YES;
}

@end
