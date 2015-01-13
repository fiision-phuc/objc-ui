//  Project name: FwiUI
//  File name   : FwiKBNavigator.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 11/6/12
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


@protocol FwiMenuAccessoryDatasource;
@protocol FwiMenuAccessoryDelegate;


@interface FwiMenuAccessory : UIView <UIAppearanceContainer> {
    
@private
    IBOutlet UIButton *_btnDismiss;
    IBOutlet UIButton *_btnBack;
    IBOutlet UIButton *_btnNext;
    IBOutlet UIButton *_btnDone;
}

@property (nonatomic, assign) NSUInteger currentStep;
@property (nonatomic, assign) id<FwiMenuAccessoryDelegate> delegate;
@property (nonatomic, assign) id<FwiMenuAccessoryDatasource> datasource;


// View's key pressed event handlers
- (IBAction)keyPressed:(id)sender;


/** Reload this menu accessory. */
- (void)reload;

@end


@interface FwiMenuAccessory (FwiMenuAccessoryCreation)

+ (FwiMenuAccessory *)menuAccessory;

@end


@protocol FwiMenuAccessoryDatasource <NSObject>

@required
/** Provide number of steps within the form. */
- (NSUInteger)totalStepsForMenuAccessory:(FwiMenuAccessory *)menuAccessory;

@end


@protocol FwiMenuAccessoryDelegate <NSObject>

@optional
/** Send finish event to delegate. */
- (void)menuAccessoryDidFinish:(FwiMenuAccessory *)menuAccessory;
/** Send dismiss event to delegate. */
- (void)menuAccessoryDidDismiss:(FwiMenuAccessory *)menuAccessory;

/** Send forward event to delegate. */
- (void)menuAccessoryDidMoveForward:(FwiMenuAccessory *)menuAccessory;
/** Send backward event to delegate. */
- (void)menuAccessoryDidMoveBackward:(FwiMenuAccessory *)menuAccessory;

@end