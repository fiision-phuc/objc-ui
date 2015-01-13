#import "FwiFormController.h"


@interface FwiFormController () {

    BOOL _isInitialized;
}

- (void)_keyboardWillHide:(NSNotification *)notification;
- (void)_keyboardWillShow:(NSNotification *)notification;

@end


@implementation FwiFormController


#pragma mark - Class's constructors
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FwiRelease(_fieldsCollection);
    FwiRelease(_notificationKB);
    FwiRelease(_vwMovable);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - View's lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    if (!_isInitialized) {
        _isInitialized  = YES;
        _vwKBNavigator  = nil;
        _notificationKB = nil;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
    }
}
// iOS5 Compatible (Backward compatible with old implementation)
- (void)viewDidUnload {
    FwiRelease(_fieldsCollection);
    FwiRelease(_notificationKB);
    FwiRelease(_vwMovable);
    [super viewDidUnload];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_vwKBNavigator) {
        FwiMenuAccessory *view = FwiRetain([FwiMenuAccessory menuAccessory]);
        [view setDatasource:self];
        [view setDelegate:self];
        [view setCurrentStep:0];

//        [self.view addSubview:view];
        _vwKBNavigator = view;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [self.view findAndResignFirstResponder];
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

    if (_vwKBNavigator) {
        [_vwKBNavigator removeFromSuperview];
        _vwKBNavigator = nil;
    }
}


#pragma mark - View's memory handler
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - View's orientation handler
// iOS6 Compatible
- (BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
}
// iOS5 Compatible (Backward compatible with old implementation)
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


#pragma mark - Class's properties


#pragma mark - Class's public methods
- (void)updateMovableViewForView:(UIView *)view completion:(void(^)(BOOL finished))completion {
    /* Condition validation */
    if (!_notificationKB) return;

    // Find the current step
    [_fieldsCollection enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        if (obj == view) {
            [_vwKBNavigator setCurrentStep:idx];
            *stop = YES;
        }
    }];

    // Get keyboard appear event's info
    NSDictionary *userInfo = [_notificationKB userInfo];
    CGRect  addFrame = [_vwKBNavigator frame];
    CGFloat animTime = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    // Calculate the center of the visible view
    CGRect appFrame          = [[UIScreen mainScreen] bounds];
    CGRect visibleFrame      = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    // For orientation support, we need this
    visibleFrame.origin.y    = appFrame.size.height - visibleFrame.size.height;

    // Continue calculation process
    visibleFrame.size.height = visibleFrame.origin.y - addFrame.size.height;
    visibleFrame.origin.y    = 0.0f;

    CGPoint center = CGPointZero;
    center.x = visibleFrame.size.width  / 2;
//    center.y = visibleFrame.size.height / 2;
    center.y = 76.0f;

    // Calculate position
    CGPoint viewCenter  = [view center];
    CGPoint superCenter = [self.view convertPoint:viewCenter fromView:view.superview];

    // Calculate distance to move up
    CGFloat distance = center.y - superCenter.y;

    // Perform move animation
    CGPoint movableCenter = _vwMovable.center;
    movableCenter.y += distance;
    [UIView animateWithDuration:animTime delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [_vwMovable setCenter:movableCenter];
                     }
                     completion:^(BOOL finished) {
                         if (completion) completion(finished);
                     }];
}


#pragma mark - Class's private methods


#pragma mark - Class's notification handlers
- (void)_keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];

    UIViewAnimationOptions animCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat animTime = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];

    [UIView animateWithDuration:animTime delay:0.0f options:animCurve
                     animations:^{
                         [_vwMovable setFrame:self.view.bounds];
                     }
                     completion:^(BOOL finished) {
                         FwiRelease(_notificationKB);
                     }];
}
- (void)_keyboardWillShow:(NSNotification *)notification {
    /* Condition validation */
    if (_notificationKB) return;
    _notificationKB = FwiRetain(notification);

    /**
     * For case where UITextFieldDelegate was actually call before this, the textfield does not move
     */
    UIView *txtField = [_vwMovable findFirstResponder];
    [self updateMovableViewForView:txtField completion:nil];
}


#pragma mark - UITextFieldDelegate's members
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateMovableViewForView:textField completion:nil];
    [textField setInputAccessoryView:_vwKBNavigator];
}


#pragma mark - FwiKBNavigatorDatasource's members
- (NSUInteger)totalStepsForMenuAccessory:(FwiMenuAccessory *)navigator {
    return (_fieldsCollection ? _fieldsCollection.count : 0);
}


#pragma mark - FwiKBNavigatorDelegate's members
- (void)menuAccessoryDidMoveBackward:(FwiMenuAccessory *)navigator {
    UIView *view = [_fieldsCollection objectAtIndex:navigator.currentStep];

    if ([view canBecomeFirstResponder]) {
        [view becomeFirstResponder];
    }
}
- (void)menuAccessoryDidMoveForward:(FwiMenuAccessory *)navigator {
    UIView *view = [_fieldsCollection objectAtIndex:navigator.currentStep];

    if ([view canBecomeFirstResponder]) {
        [view becomeFirstResponder];
    }
}


@end