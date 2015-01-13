#import "FwiButton.h"


@interface FwiButton () {

}

/**
 * Initialize class's private variables
 */
- (void)_init;

@end


@implementation FwiButton


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


#pragma mark - Class's properties
- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    if (image) [super setBackgroundImage:[image resizableImageWithCapInsets:_resizeBackground] forState:state];
}
- (void)setResizeBackground:(UIEdgeInsets)resizeBackground {
    _resizeBackground = resizeBackground;
    [self _init];
}


#pragma mark - Class's public methods


#pragma mark - Class's private methods
- (void)_init {
    _resizeBackground = UIEdgeInsetsMake(9.0f, 9.0f, 9.0f, 9.0f);

//    UIImage *bgDisabled = [self backgroundImageForState:UIControlStateDisabled];
//    UIImage *bgHighlighted = [self backgroundImageForState:UIControlStateHighlighted];
    UIImage *bgNormal = [self backgroundImageForState:UIControlStateNormal];
//    UIImage *bgReserved = [self backgroundImageForState:UIControlStateReserved];
//    UIImage *bgSelected = [self backgroundImageForState:UIControlStateSelected];

//    if (bgDisabled) [self setBackgroundImage:[bgDisabled resizableImageWithCapInsets:_resizeBackground] forState:UIControlStateDisabled];
//    if (bgHighlighted) [self setBackgroundImage:[bgHighlighted resizableImageWithCapInsets:_resizeBackground] forState:UIControlStateHighlighted];
    if (bgNormal) [self setBackgroundImage:[bgNormal resizableImageWithCapInsets:_resizeBackground] forState:UIControlStateNormal];
//    if (bgReserved) [self setBackgroundImage:[bgReserved resizableImageWithCapInsets:_resizeBackground] forState:UIControlStateReserved];
//    if (bgSelected) [self setBackgroundImage:[bgSelected resizableImageWithCapInsets:_resizeBackground] forState:UIControlStateSelected];
}


#pragma mark - Class's notification handlers


@end
