//  Project name: FwiUI
//  File name   : FwiKBInput.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 12/27/12
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2013 Trinity 0715. All Rights Reserved.
//  --------------------------------------------------------------
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,  FITNESS  FOR  A  PARTICULAR  PURPOSE  AND
// NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED
// IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR  ANY
// DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
// NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR  PERFORMANCE
// OF THIS SOFTWARE.
//
//
// Disclaimer
// ----------
// Although reasonable care has been taken to ensure the correctness of  this  implementation,  this
// code should never be used in any application without proper verification and testing.  I disclaim
// all liability and responsibility to any person or entity with  respect  to  any  loss  or  damage
// caused, or alleged to be caused, directly or indirectly, by the use of this  class.  However,  if
// you discover any kind of bugs, please feel free to email me at phuc.fwi@gmail.com.

#import <UIKit/UIKit.h>
#import "FwiKB.h"


@protocol FwiKBInputDelegate;


@interface FwiKBInput : FwiKB <UITextViewDelegate> {
	
@private
    IBOutlet UIImageView *_imvBackground;
    IBOutlet UITextView  *_txvInput;
    IBOutlet UIButton    *_btnCamera;
    IBOutlet UIButton    *_btnDone;
}

@property (nonatomic, readonly) UIImageView *imvBackground;
@property (nonatomic, readonly) UITextView  *txvInput;
@property (nonatomic, readonly) UIButton    *btnCamera;
@property (nonatomic, readonly) UIButton    *btnDone;

@property (nonatomic, assign) id<FwiKBInputDelegate> delegate;
@property (nonatomic, assign) NSUInteger minLines;
@property (nonatomic, assign) NSUInteger maxLines;
@property (nonatomic, assign) CGFloat    padding;


/**
 * Create keyboard input view from custom xib file
 */
+ (FwiKBInput *)createViewWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle;


- (IBAction)keyPressed:(id)sender;

@end




@protocol FwiKBInputDelegate <NSObject>

@optional
/**
 * Return new height before changing frame
 */
- (void)keyboardInput:(FwiKBInput *)keyboardInput willChangeHeight:(CGFloat)height;
/**
 * Return new height after changing frame
 */
- (void)keyboardInput:(FwiKBInput *)keyboardInput didChangeHeight:(CGFloat)height;

/**
 * Return action from either btnCamera or btnDone
 */
- (void)keyboardInput:(FwiKBInput *)keyboardInput didReceiveAction:(UIButton *)sender;


// UITextViewDelegate alias
- (BOOL)keyboardInputShouldBeginEditing:(FwiKBInput *)keyboardInput;
- (BOOL)keyboardInputShouldEndEditing:(FwiKBInput *)keyboardInput;

- (void)keyboardInputDidBeginEditing:(FwiKBInput *)keyboardInput;
- (void)keyboardInputDidEndEditing:(FwiKBInput *)keyboardInput;

- (BOOL)keyboardInput:(FwiKBInput *)keyboardInput shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)keyboardInputDidChange:(FwiKBInput *)keyboardInput;

- (void)keyboardInputDidChangeSelection:(FwiKBInput *)keyboardInput;

@end