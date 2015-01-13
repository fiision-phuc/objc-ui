//  Project name: FwiUI
//  File name   : FwiFormController.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 2/18/13
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2013 Monster Group. All rights reserved.
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
#import "FwiMenuAccessory.h"


@interface FwiFormController : UIViewController <UITextFieldDelegate, FwiMenuAccessoryDatasource, FwiMenuAccessoryDelegate> {

@protected
    IBOutlet UIView *_vwMovable;
    FwiMenuAccessory  *_vwKBNavigator;
    NSNotification  *_notificationKB;

    NSMutableArray  *_fieldsCollection;     // A collection of field indexes within a form. Developer must responsible to create this array
}


/**
 * Move movable view to the center of remain view after keyboard show
 */
- (void)updateMovableViewForView:(UIView *)view completion:(void(^)(BOOL finished))completion;

@end