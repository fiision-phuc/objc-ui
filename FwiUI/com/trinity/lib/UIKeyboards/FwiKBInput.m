#import "FwiKBInput.h"


@interface FwiKBInput() {

    NSUInteger _minHeight;
	NSUInteger _maxHeight;
}

/**
 * Initialize class's private variables
 */
- (void)_init;
/**
 * Visualize all view's components
 */
- (void)_visualize;

-(void)_updateHeight:(CGFloat)newHeight;

@end

@implementation FwiKBInput


#pragma mark - Class's static constructors
+ (FwiKBInput *)createViewWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle {
    if (!bundle)  bundle  = [NSBundle mainBundle];
    
    FwiKBInput *inputView = [[bundle loadNibNamed:nibName owner:nil options:nil] objectAtIndex:0];
    return inputView;
}


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
    _delegate = nil;
    
    FwiRelease(_txvInput);
    FwiRelease(_btnCamera);
    FwiRelease(_btnDone);
    FwiRelease(_imvBackground);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's override methods
- (CGSize)sizeThatFits:(CGSize)size {
    NSString *text = _txvInput.text;
    if ([text length] <= 0) {
        size.height = _minHeight + _padding;
    }
    return size;
}

- (void)didMoveToSuperview {
    [self setMinLines:1];
    [self setMaxLines:3];
    
    [_txvInput setDelegate:self];
    [_txvInput setScrollEnabled:NO];
    [_txvInput setContentInset:UIEdgeInsetsZero];
    [_txvInput setShowsVerticalScrollIndicator:NO];
    [_txvInput setShowsHorizontalScrollIndicator:NO];
    
    [super didMoveToSuperview];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bgFrame    = _imvBackground.frame;
    CGRect inputFrame = _txvInput.frame;
    
    bgFrame.origin.y    = _padding / 2;
    bgFrame.size.height = self.frame.size.height - _padding;
    
    [_imvBackground setFrame:bgFrame];
    [_txvInput setFrame:inputFrame];
}


#pragma mark - Class's properties
- (void)setMaxLines:(NSUInteger)maxLines {
    [_txvInput setHidden:YES];
    [_txvInput setDelegate:nil];

    // Create temp string
    NSString *saveText = FwiRetain([_txvInput text]);
    NSMutableString *newText = [[NSMutableString alloc] initWithString:@"-"];
    for (NSUInteger i = 1; i < maxLines; i++) {
        [newText appendFormat:@"%@", @"\n|W|"];
    }
    
    // Calculate max height
    [_txvInput setText:newText];
    _maxLines  = maxLines;
    _maxHeight = _txvInput.contentSize.height;
    
    // Restore txvInput to default
    [_txvInput setText:saveText];
    [_txvInput setDelegate:self];
    [_txvInput setHidden:NO];
    
    // Restore size
    [self sizeToFit];
    FwiRelease(saveText);
    FwiRelease(newText);
}
- (void)setMinLines:(NSUInteger)minLines {
    [_txvInput setHidden:YES];
    [_txvInput setDelegate:nil];
    
    // Create temp string
    NSString *saveText = FwiRetain([_txvInput text]);
    NSMutableString *newText = [[NSMutableString alloc] initWithString:@"-"];
    for (NSUInteger i = 1; i < minLines; i++) {
        [newText appendFormat:@"%@", @"\n|W|"];
    }
    
    // Calculate min height
    [_txvInput setText:newText];
    _minLines  = minLines;
    _minHeight = _txvInput.contentSize.height;
    _minHeight = MAX(_minHeight, MAX(_btnCamera.frame.size.height, _btnDone.frame.size.height));
    
    // Restore txvInput to default
    [_txvInput setText:saveText];
    [_txvInput setDelegate:self];
    [_txvInput setHidden:NO];
    
    // Restore size
    [self sizeToFit];
    FwiRelease(saveText);
    FwiRelease(newText);
}


#pragma mark - Class's event handlers
- (IBAction)keyPressed:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(keyboardInput:didReceiveAction:)])
        [_delegate keyboardInput:self didReceiveAction:sender];
}


#pragma mark - Class's public methods


#pragma mark - Class's private methods
-(void)_init {
    _shouldHide = NO;
    
    _minHeight  = 0.0f;
    _maxHeight  = 0.0f;
    _padding    = 10.0f;
    _minLines   = 0;
    _maxLines   = 0;
}
- (void)_visualize {
}

-(void)_updateHeight:(CGFloat)newHeight {
    // Calculate new frame
    newHeight += _padding;
    CGRect  ownFrame   = self.frame;
    CGFloat transalate = newHeight - self.frame.size.height;
    
    ownFrame.size.height  = newHeight;
    ownFrame.origin.y    -= transalate;
    
    // Apply new frame
    [self setFrame:ownFrame];
}


#pragma mark - UITextViewDelegate's members
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(keyboardInputShouldBeginEditing:)]) {
		return [_delegate keyboardInputShouldBeginEditing:self];
	}
    else {
		return YES;
	}
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(keyboardInputShouldEndEditing:)]) {
		return [_delegate keyboardInputShouldEndEditing:self];
	}
    else {
		return YES;
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(keyboardInputDidBeginEditing:)]) {
		[_delegate keyboardInputDidBeginEditing:self];
	}
}
- (void)textViewDidEndEditing:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(keyboardInputDidEndEditing:)]) {
		[_delegate keyboardInputDidEndEditing:self];
	}
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if(![textView hasText] && [text isEqualToString:@""]) return NO;

    if ([_delegate respondsToSelector:@selector(keyboardInput:shouldChangeTextInRange:replacementText:)])
        return [_delegate keyboardInput:self shouldChangeTextInRange:range replacementText:text];
	return YES;
}
- (void)textViewDidChange:(UITextView *)textView {
	NSInteger newHeight = _txvInput.contentSize.height;
    newHeight = MIN(MAX(newHeight, _minHeight), _maxHeight);
    if ([_delegate respondsToSelector:@selector(keyboardInput:willChangeHeight:)])
        [_delegate keyboardInput:self willChangeHeight:newHeight];
    
    [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self _updateHeight:newHeight];
                     }
                     completion:^(BOOL finished) {
                         // Scroll textview to current cursor
                         if (newHeight >= _maxHeight) {
                             if(!_txvInput.scrollEnabled) {
                                 _txvInput.scrollEnabled = YES;
                                 [_txvInput flashScrollIndicators];
                             }
                         }
                         else {
                             _txvInput.scrollEnabled = NO;
                         }
                         
                         // Notify delegate
                         if ([_delegate respondsToSelector:@selector(keyboardInput:didChangeHeight:)])
                             [_delegate keyboardInput:self didChangeHeight:newHeight];
                     }];
    
    if ([_delegate respondsToSelector:@selector(keyboardInputDidChange:)])
        [_delegate keyboardInputDidChange:self];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
	if ([_delegate respondsToSelector:@selector(keyboardInputDidChangeSelection:)])
		[_delegate keyboardInputDidChangeSelection:self];
}

@end
