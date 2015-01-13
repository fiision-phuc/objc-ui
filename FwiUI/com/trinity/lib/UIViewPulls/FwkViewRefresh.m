#import "FwkViewRefresh.h"


@interface FwkViewRefresh () {

    NSDateFormatter *_dateFormatter;
}

@property (nonatomic, retain) NSDate *lastUpdate;

/**
 * Initialize class's private variables
 */
- (void)_init;
/**
 * Visualize all view's components
 */
- (void)_visualize;

@end


@implementation FwkViewRefresh


#pragma mark - Class's static constructors
+ (FwkViewRefresh *)createViewWithTable:(UITableView *)tbvTable delegate:(id<FwkViewPullDelegate>)delegate {
    FwkViewRefresh *view = (FwkViewRefresh *)[[kFwiBundle loadNibNamed:@"FwkViewRefresh" owner:nil options:nil] objectAtIndex:0];
//    [view.imvArrow setImage:[UIImage imageWithName:@"icnArrow.png" bundle:kFwiBundle]];
    [view setScrollView:tbvTable];
    [view setDelegate:delegate];
    
    // Resize view
    CGRect ownFrame     = view.frame;
    ownFrame.origin.y  -= ownFrame.size.height;
    ownFrame.size.width = tbvTable.bounds.size.width;
    
    // Add view to table
    [view setFrame:ownFrame];
    [tbvTable addSubview:view];
    
    return view;
}


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
    FwiRelease(_lastUpdate);
    FwiRelease(_dateFormatter);
    FwiRelease(_indicator);
    FwiRelease(_imvArrow);
    FwiRelease(_lblLastUpdate);
    FwiRelease(_lblInstruction);
    FwiRelease(_loading);
    FwiRelease(_pull);
    FwiRelease(_release);
    FwiRelease(_update);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    _maxHeight = self.frame.size.height;
}
- (void)layoutSubviews {
    [super layoutSubviews];
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)finishLoadingWithCompletion:(void(^)(BOOL finished))completion {
    [super finishLoadingWithCompletion:^(BOOL finished) {
        [self setLastUpdate:[NSDate date]];
        [self switchState:kPullViewState_Idle offset:0.0f];
        
        if (completion) completion(finished);
    }];
}
- (void)switchState:(PullViewState)state offset:(CGFloat)offset {
    [super switchState:state offset:offset];

    switch (self.currentState) {
        case kPullViewState_Idle: {
            [_imvArrow setHidden:NO];
            [_imvArrow setTransform:CGAffineTransformIdentity];
            [_indicator stopAnimating];
            
            if (_lastUpdate) [_lblLastUpdate setText:[NSString stringWithFormat:@"%@ %@", _update, [_dateFormatter stringFromDate:_lastUpdate]]];
            else [_lblLastUpdate setText:nil];
            [_lblInstruction setText:_pull];
            break;
            
        }
        case kPullViewState_Loading: {
            [_imvArrow setHidden:YES];
            [_imvArrow setTransform:CGAffineTransformIdentity];
            [_indicator startAnimating];
            [_lblInstruction setText:_loading];
            break;
            
        }
        case kPullViewState_Pull: {
            CGFloat angle = (-offset * M_PI) / self.frame.size.height;
            
            [_imvArrow setTransform:CGAffineTransformRotate(CGAffineTransformIdentity, angle)];
            [_lblInstruction setText:_pull];
            break;
            
        }
        case kPullViewState_Release: {
            _imvArrow.transform = CGAffineTransformMakeRotation(M_PI);
            [_lblInstruction setText:_release];
            break;
            
        }
        default:
            break;
    }
    [self setNeedsLayout];
}


#pragma mark - Class's private methods
- (void)_init {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    _dateFormatter   = [[NSDateFormatter alloc] init];
    _lastUpdate      = nil;
    
    [_dateFormatter setDateFormat:@"MM/dd/yyyy  hh:mm a"];
    [_dateFormatter setLocale:locale];
    FwiRelease(locale);
    
    self.loading = @"Loading...";
    self.pull    = @"Pull to refresh...";
    self.release = @"Release to refresh...";
    self.update  = @"Last updated:";
}
- (void)_visualize {
}


#pragma mark - Class's notification handlers


@end
