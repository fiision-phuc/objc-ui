#import "FwiTextField.h"


@interface FwiTextFieldDelegate : NSObject <UITextFieldDelegate> {

@private
    NSMutableString *_text;
}

@property (nonatomic, assign) id<UITextFieldDelegate> outerDelegate;
@property (nonatomic, assign) BOOL shouldClear;
@property (nonatomic, retain) NSString *text;

@end


@interface FwiTextField () {

    FwiTextFieldDelegate *_delegate;
    BOOL _isSecured;
    BOOL _shouldClear;
}


/**
 * Initialize class's private variables
 */
- (void)_init;

/**
 * Update text for super view
 */
- (void)_setText:(NSString *)text;

@end


@implementation FwiTextField


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
    FwiRelease(_delegate);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
}
- (void)layoutSubviews {
    [super layoutSubviews];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
	return [self _innerRectForBound:bounds];
}
- (CGRect)editingRectForBounds:(CGRect)bounds {
	return [self _innerRectForBound:bounds];
}
- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	return [self _innerRectForBound:bounds];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(cut:))            return _allowCut;
	else if (action == @selector(copy:))      return _allowCopy;
    else if (action == @selector(paste:))     return _allowPaste;
	else if (action == @selector(select:))    return _allowSelect;
	else if (action == @selector(selectAll:)) return _allowSelectAll;

    return [super canPerformAction:action withSender:sender];
}

- (void)setSecureTextEntry:(BOOL)secureTextEntry {
    [super setSecureTextEntry:secureTextEntry];
    _isSecured = secureTextEntry;

    // Prepare for secured textfield if it is required
    if (_isSecured) {
        _delegate = [[FwiTextFieldDelegate alloc] init];
        _delegate.shouldClear = _shouldClear;
        
        if (self.delegate) [_delegate setOuterDelegate:self.delegate];
        [super setDelegate:_delegate];
    }
    else {
        if (_delegate && _delegate.outerDelegate) [super setDelegate:_delegate.outerDelegate];
        FwiRelease(_delegate);
    }
}


#pragma mark - Class's properties
- (NSString *)text {
    if (_isSecured) {
        return [_delegate text];
    }
    else {
        return super.text;
    }
}
- (void)setText:(NSString *)text {
	if (!text || [text length] == 0) {
		super.text = nil;
		if (_delegate) [_delegate setText:nil];
	}
	else {
        text = [text trim];
        
        if (_isSecured) {
            // Mask the input
            NSMutableString *mask = [[NSMutableString alloc] initWithCapacity:[text length]];
            for (NSUInteger i = 0; i < [text length]; i++) [mask appendString:@"●"];

            [self _setText:mask];
            FwiRelease(mask);

            // Validate input
            NSUInteger matched = 0;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^●+$" options:NSRegularExpressionCaseInsensitive error:nil];
            matched = [regex numberOfMatchesInString:text options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [text length])];
            if (matched == 1) return;

            // Insert input into delegate
            [_delegate setText:text];
        }
        else {
            super.text = text;
        }
	}
}
- (void)setDelegate:(id<UITextFieldDelegate>)delegate {
    if (_delegate) [_delegate setOuterDelegate:delegate];
    else [super setDelegate:delegate];
}

- (void)setResizeBackground:(UIEdgeInsets)resizeBackground {
    _resizeBackground   = resizeBackground;
    UIImage *background = [self background];
    [self setBackground:[background resizableImageWithCapInsets:resizeBackground]];
}


#pragma mark - Class's public methods


#pragma mark - Class's private methods
- (void)_init {
    _allowCut         = YES;
    _allowCopy        = YES;
    _allowPaste       = YES;
    _allowSelect      = YES;
    _allowSelectAll   = YES;
    _shouldClear      = super.clearsOnBeginEditing;
    _resizeBackground = UIEdgeInsetsMake(9.0f, 9.0f, 9.0f, 9.0f);

    // Resize background image if it is available
    UIImage *background = [self background];
    if (background) {
        [self setBorderStyle:UITextBorderStyleNone];
        [self setBackground:[background resizableImageWithCapInsets:_resizeBackground]];
    }
    
    if (_delegate) {
        _delegate.shouldClear = _shouldClear;
    }
}
- (CGRect)_innerRectForBound:(CGRect)bounds {
	UITextFieldViewMode mode = [self clearButtonMode];
    
    CGFloat marginL = _resizeBackground.left;
	CGFloat marginR = (mode == UITextFieldViewModeNever) ? _resizeBackground.right : 35.0f;
	
	CGRect rect = CGRectMake(bounds.origin.x + marginL, bounds.origin.y, bounds.size.width - (marginL + marginR), bounds.size.height);
	return CGRectInset(rect, 0.0f, 0.0f);
}

- (void)_setText:(NSString *)text {
    super.text = text;
}


@end


@implementation FwiTextFieldDelegate


@synthesize shouldClear=_shouldClear;


#pragma mark - Class's constructors
- (id)init {
	self = [super init];
	if (self) {
		_text = [[NSMutableString alloc] initWithCapacity:0];
        _outerDelegate = nil;
        self.shouldClear = NO;
	}
	return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    _outerDelegate = nil;
    FwiRelease(_text);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties
- (NSString *)text {
    NSString *string = [NSString stringWithFormat:@"%@", _text];
	return string;
}
- (void)setText:(NSString *)text {
    FwiRelease(_text);
    
	if (!text || [text length] == 0) {
		_text = [[NSMutableString alloc] initWithCapacity:0];
	}
	else {
		_text = [[NSMutableString alloc] initWithString:text];
	}
}


#pragma mark - UITextFieldDelegate's members
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL shouldBegin = YES;
    
	if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]) {
		shouldBegin = [_outerDelegate textFieldShouldBeginEditing:textField];
    }
    
    if (shouldBegin && _shouldClear) {
        [self setText:nil];
    }
    return shouldBegin;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (_shouldClear) {
        [self setText:nil];
        [(FwiTextField *)textField _setText:nil];
    }
    
	if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)])
		[_outerDelegate textFieldDidBeginEditing:textField];
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
		return [_outerDelegate textFieldShouldEndEditing:textField];
    }
	else {
		return YES;
    }
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textFieldDidEndEditing:)])
		[_outerDelegate textFieldDidEndEditing:textField];
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)])
		[_outerDelegate textField:textField shouldChangeCharactersInRange:range replacementString:string];

	// Update textfield
	[_text replaceCharactersInRange:range withString:string];

	// Create mask text
    NSMutableString *text = [[NSMutableString alloc] initWithCapacity:[_text length]];
	for (NSUInteger i = 0; i < [_text length]; i++) [text appendString:@"●"];

    [(FwiTextField *)textField _setText:text];
    FwiRelease(text);
	return NO;
}
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textFieldShouldClear:)]) {
        BOOL flag = [_outerDelegate textFieldShouldClear:textField];

        if (flag) [_text replaceCharactersInRange:NSMakeRange(0, _text.length) withString:@""];
        return flag;
    }
    else {
        [_text replaceCharactersInRange:NSMakeRange(0, _text.length) withString:@""];
        return YES;
    }
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (_outerDelegate && [_outerDelegate respondsToSelector:@selector(textFieldShouldReturn:)]) {
		return [_outerDelegate textFieldShouldReturn:textField];
    }
	else {
		return YES;
    }
}


@end