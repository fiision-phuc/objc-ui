//  Project name: FwiUI
//  File name   : FwiXMLFormController.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 3/23/13
//  Version     : 1.01
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
#import "FwiXMLFormCell.h"
#import "FwiFormController.h"


@protocol FwiXMLFormDelegate;
@protocol FwiXMLFormDatasource;


@interface FwiXMLFormController : FwiFormController <UITableViewDataSource, UITableViewDelegate> {

@protected
    IBOutlet UIView      *_vwForm;
    IBOutlet UITableView *_vwForm_tbvFormA;
    IBOutlet UITableView *_vwForm_tbvFormB;
    
    IBOutlet UIButton    *_btnBack;
    IBOutlet UIButton    *_btnNext;
    IBOutlet UIButton    *_btnDone;
    IBOutlet UIButton    *_btnCancel;
    
    NSMutableDictionary  *_formData;
}

@property (nonatomic, assign) id<FwiXMLFormDelegate> delegate;
@property (nonatomic, assign) id<FwiXMLFormDatasource> datasource;


// View's key pressed event handlers
- (IBAction)handleBtnBack:(id)sender;
- (IBAction)handleBtnNext:(id)sender;
- (IBAction)handleBtnDone:(id)sender;
- (IBAction)handleBtnCancel:(id)sender;

// Reload datasource
- (void)reloadData;

@end


@protocol FwiXMLFormDatasource <NSObject>

@required
/**
 * Return the pre-define '.plist' file
 */
- (NSString *)templateForXMLFormController:(FwiXMLFormController *)controller;

@optional
- (NSString *)xmlFormController:(FwiXMLFormController *)controller localizeStringForString:(NSString *)string;

@end


@protocol FwiXMLFormDelegate <NSObject>

@optional
- (void)xmlFormController:(FwiXMLFormController *)controller customKeyboardForField:(NSString *)fieldName withInput:(UITextField *)input;
- (void)xmlFormController:(FwiXMLFormController *)controller didFinishEditingForField:(NSString *)fieldName withInput:(NSString *)input;
- (void)xmlFormController:(FwiXMLFormController *)controller errorMessage:(NSString *)message input:(UITextField *)input;

- (void)xmlFormControllerDidCancel:(FwiXMLFormController *)controller;
- (void)xmlFormController:(FwiXMLFormController *)controller didFinishWithData:(NSDictionary *)formData;

- (BOOL)xmlFormController:(FwiXMLFormController *)controller shouldMoveForwardWithData:(NSDictionary *)formData;
- (void)xmlFormControllerWillMoveForward:(FwiXMLFormController *)controller;
- (void)xmlFormControllerDidMoveForward:(FwiXMLFormController *)controller;

- (BOOL)xmlFormController:(FwiXMLFormController *)controller shouldMoveBackwardWithData:(NSDictionary *)formData;
- (void)xmlFormControllerWillMoveBackward:(FwiXMLFormController *)controller;
- (void)xmlFormControllerDidMoveBackward:(FwiXMLFormController *)controller;

@end