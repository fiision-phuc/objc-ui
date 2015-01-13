#import "FwiMenuAccessory.h"


@interface FwiMenuAccessory () {

    NSUInteger _totalSteps;
}


/** Initialize class's private variables. */
- (void)_init;
/** Visualize all view's components. */
- (void)_visualize;

@end


@implementation FwiMenuAccessory


#pragma mark - Class's constructors
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
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
    self.delegate   = nil;
    self.datasource = nil;
    
    FwiRelease(_btnDismiss);
    FwiRelease(_btnBack);
    FwiRelease(_btnNext);
    FwiRelease(_btnDone);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties
- (void)setDatasource:(id<FwiMenuAccessoryDatasource>)datasource {
    /* Condition validation */
    if (_datasource == datasource) return;
    
    _datasource = datasource;
    [self reload];
}


#pragma mark - Class's event handlers
- (IBAction)keyPressed:(id)sender {
    if (sender == _btnDismiss) {
        [[[[UIApplication sharedApplication] delegate] window] findAndResignFirstResponder];
        
        // Call delegate
        if (_delegate && [_delegate respondsToSelector:@selector(menuAccessoryDidDismiss:)])
            [_delegate menuAccessoryDidDismiss:self];
    }
    else if (sender == _btnBack) {
        /* Condition validation */
        if (_currentStep == 0) return;
        [self setCurrentStep:--_currentStep];
        
        // Call delegate
        if (_delegate && [_delegate respondsToSelector:@selector(menuAccessoryDidMoveBackward:)])
            [_delegate menuAccessoryDidMoveForward:self];
    }
    else if (sender == _btnNext) {
        /* Condition validation */
        if (_currentStep >= (_totalSteps - 1)) return;
        [self setCurrentStep:++_currentStep];
        
        // Call delegate
        if (_delegate && [_delegate respondsToSelector:@selector(menuAccessoryDidMoveForward:)])
            [_delegate menuAccessoryDidMoveBackward:self];
    }
    else if (sender == _btnDone) {
        [[[[UIApplication sharedApplication] delegate] window] findAndResignFirstResponder];

        // Call delegate
        if (_delegate && [_delegate respondsToSelector:@selector(menuAccessoryDidFinish:)])
            [_delegate menuAccessoryDidFinish:self];
    }
}


#pragma mark - Class's public methods
- (void)reload {
    /* Condition validation */
    if (!_datasource) return;

    // Load total step & reset step count
    _currentStep = 0;
    _totalSteps  = [_datasource totalStepsForMenuAccessory:self];
}


#pragma mark - Class's private methods
- (void)_init {
    _currentStep = 0;
    _totalSteps  = 0;
}
- (void)_visualize {
}


@end


@implementation FwiMenuAccessory (FwiKBNavigatorCreation)


#pragma mark - Class's static constructors
+ (FwiMenuAccessory *)menuAccessory {
    NSBundle *bundle = kFwiBundle;
    if (!bundle) return nil;
    
    FwiMenuAccessory *view = [[bundle loadNibNamed:@"FwiMenuAccessory" owner:nil options:nil] objectAtIndex:0];
    return view;
}


@end
