#import "FwiKB.h"


@interface FwiKB () {

    BOOL _isRegisterNotification;
}


/**
 * Initialize class's private variables
 */
- (void)_init;

/**
 * Current device's orientation
 */
- (UIDeviceOrientation)_orientation;

/**
 * Handle keyboard will show / will hide event
 */
- (void)_keyboardWillHide:(NSNotification *)notification;
- (void)_keyboardWillShow:(NSNotification *)notification;

@end


@implementation FwiKB


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
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    [self setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin)];
    [self setAutoresizesSubviews:YES];

    if (!_isRegisterNotification) {
        // Register keyboard notification
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(_keyboardWillHide:)
//                                                     name:UIKeyboardWillHideNotification
//                                                   object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(_keyboardWillShow:)
//                                                     name:UIKeyboardWillShowNotification
//                                                   object:nil];
        _isRegisterNotification = YES;
    }

    // Move to the bottom of the view
    CGSize superSize = [[UIScreen mainScreen] applicationFrame].size;
    CGRect ownFrame  = self.frame;
    if (UIDeviceOrientationIsPortrait([self _orientation]) || UIDeviceOrientationIsLandscape([self _orientation])) {
        ownFrame.origin.x = 0.0f;
        ownFrame.origin.y = (_shouldHide ? superSize.height : (superSize.height - ownFrame.size.height));
    }
    else {
        // Do not handle unknown orientation
    }
    [self setFrame:ownFrame];
}
- (void)layoutSubviews {
    [super layoutSubviews];
}
- (void)removeFromSuperview {
    [super removeFromSuperview];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)_init {
    _shouldHide = NO;
    _adjustHeight = 0.0f;
    _isRegisterNotification = NO;
}


#pragma mark - Class's private methods
- (UIDeviceOrientation)_orientation {
    return (UIDeviceOrientation)[[UIApplication sharedApplication] statusBarOrientation];
}


#pragma mark - Class's notification handlers
- (void)_keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];

    // Get animation info
    UIViewAnimationOptions animCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    CGFloat animTime = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    // Calculate new frame
    CGSize superSize = self.superview.bounds.size;
    CGRect  ownFrame = self.frame;

    if (UIDeviceOrientationIsPortrait([self _orientation])) {
        ownFrame.origin.x = 0.0f;
        ownFrame.origin.y = (_shouldHide ? superSize.height : (superSize.height - ownFrame.size.height));
    }
    else if (UIDeviceOrientationIsLandscape([self _orientation])) {
        ownFrame.origin.x = 0.0f;
        ownFrame.origin.y = (_shouldHide ? superSize.height : (superSize.height - ownFrame.size.height));
    }
    [UIView animateWithDuration:animTime delay:0.0f options:animCurve
                     animations:^{
                         [self setFrame:ownFrame];
                     }
                     completion:nil];
}
- (void)_keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];

    // Get animation info
    UIViewAnimationOptions animCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    CGFloat animTime = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    // Calculate new frame
    CGRect kbFrame   = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize superSize = self.superview.bounds.size;
    CGRect ownFrame  = self.frame;

    if (UIDeviceOrientationIsPortrait([self _orientation])) {
        ownFrame.origin.x = 0.0f;
        ownFrame.origin.y = superSize.height - (kbFrame.size.height + ownFrame.size.height) + _adjustHeight;
    }
    else if (UIDeviceOrientationIsLandscape([self _orientation])) {
        ownFrame.origin.x = 0.0f;
        ownFrame.origin.y = superSize.height - (kbFrame.size.width + ownFrame.size.height) + _adjustHeight;
    }
    [UIView animateWithDuration:animTime delay:0.0f options:animCurve
                     animations:^{
                         [self setFrame:ownFrame];
                     }
                     completion:nil];
}


@end
