//  Project name: FwiUI
//  File name   : FwiXMLFormCell.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 11/14/12
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


// Define key for xml file
#define kTitle                                          @"title"            // Form's title
#define kCorrection                                     @"correction"       // Yes/No
#define kEnable                                         @"enable"           // Yes/No
#define kRequire                                        @"require"          // Yes/No
#define kSecure                                         @"secure"           // Yes/No
#define kCapitalization                                 @"capitalization"   // Value
#define kKeyboard                                       @"keyboard"         // Value
#define kValidation                                     @"validation"       // List of validation rules
// Define capitalization value for kCapitalization
#define kCapitalization_AllCharacters                   @"all_characters"
#define kCapitalization_None                            @"none"
#define kCapitalization_Sentences                       @"sentences"
#define kCapitalization_Words                           @"words"
// Define keyboard value for kKeyboard
#define kKeyboard_ASCII_Capable                         @"ascii_capable"
#define kKeyboard_Custom                                @"custom"
#define kKeyboard_DecimalPad                            @"decimal_pad"
#define kKeyboard_Default                               @"default"
#define kKeyboard_EmailAddress                          @"email_address"
#define kKeyboard_NamePhonePad                          @"name_phone_pad"
#define kKeyboard_NumberPad                             @"number_pad"
#define kKeyboard_Numbers_And_Punctuation               @"numbers_and_punctuation"
#define kKeyboard_PhonePad                              @"phone_pad"
#define kKeyboard_URL                                   @"url"


@protocol FwiXMLFormCellDelegate;


@interface FwiXMLFormCell : UITableViewCell {

@private    
    IBOutlet UILabel      *_lblTitle;
    IBOutlet FwiTextField *_txtValue;
}

@property (nonatomic, assign) id<FwiXMLFormCellDelegate> delegate;

@property (nonatomic, readonly) UILabel      *lblTitle;
@property (nonatomic, readonly) FwiTextField *txtValue;

@property (nonatomic, readonly) NSString     *title;
@property (nonatomic, readonly) NSString     *keyboardType;
@property (nonatomic, readonly) NSString     *errorMessage;


/**
 * Validate input
 */
- (BOOL)isValid;

/**
 * Provide form info & index
 */
- (void)setInfo:(NSDictionary *)info atIndex:(NSIndexPath *)index;

@end


@protocol FwiXMLFormCellDelegate <NSObject>

@optional
- (NSString *)cell:(FwiXMLFormCell *)cell localizeStringForString:(NSString *)string;

@end