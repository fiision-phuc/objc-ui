#import "FwiXMLFormCell.h"


@interface FwiXMLFormCell () {

    NSDictionary *_info;
    NSIndexPath  *_index;
}

@end


@implementation FwiXMLFormCell


#pragma mark - Class's constructors
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    FwiRelease(_info);
    FwiRelease(_index);
    FwiRelease(_lblTitle);
    FwiRelease(_txtValue);
    FwiRelease(_errorMessage);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Class's properties
- (NSString *)title {
    if (!_info) return nil;
    return [_info objectForKey:kTitle];
}
- (NSString *)keyboardType {
    if (!_info) return nil;
    return [_info objectForKey:kKeyboard];
}


#pragma mark - Class's public methods
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (BOOL)isValid {
    NSArray *keys = [_info allKeys];
    __block NSString *input = [[_txtValue text] trim];

    // Validate required field
    BOOL passRequired = YES;
    if ([keys containsObject:kRequire] && [[_info objectForKey:kRequire] boolValue]) passRequired = (input.length > 0);

    /* Condition validation: Stop validation if it is not pass required validation */
    if (!passRequired) {
        _errorMessage = [[NSString alloc] initWithFormat:@"%@ is required.", [_info objectForKey:kTitle]];
        return NO;
    }

    // Validate input data
    __block BOOL passValidate = YES;
    if ([keys containsObject:kValidation]) {
        NSDictionary *validations = [_info objectForKey:kValidation];

        [validations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *validation, BOOL *stop) {
            NSError *error = nil;
            NSUInteger matched = 0;

            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:validation options:NSRegularExpressionCaseInsensitive error:&error];
            if (!error) matched = [regex numberOfMatchesInString:input options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [input length])];

            if (matched != 1) {
                *stop = YES;
                passValidate = NO;
                FwiRelease(_errorMessage);
                _errorMessage = FwiRetain(key);
            }
        }];
    }

    return (passRequired & passValidate);
}

- (void)setInfo:(NSDictionary *)info atIndex:(NSIndexPath *)index {
    FwiRelease(_info);
    FwiRelease(_index);
    FwiRelease(_errorMessage);

    // Keep instance
    _info  = FwiRetain(info);
    _index = FwiRetain(index);

    // Disable all textfield actions
    [_txtValue setAllowCopy:NO];
    [_txtValue setAllowCut:NO];
    [_txtValue setAllowPaste:NO];
    [_txtValue setAllowSelect:NO];
    [_txtValue setAllowSelectAll:NO];

    // Apply form
    NSString *title = [_info objectForKey:kTitle];
    if (_delegate && [_delegate respondsToSelector:@selector(cell:localizeStringForString:)]) {
        title = [_delegate cell:self localizeStringForString:title];
    }

    if (_lblTitle) [_lblTitle setText:title];
    else [_txtValue setPlaceholder:title];


    /**
     * Additional config
     */
    NSArray *keys = [_info allKeys];
    
    //  Auto capitalization
    if ([keys containsObject:kCapitalization]) {
        NSString *value = [_info objectForKey:kCapitalization];

        if ([value isEqualToStringIgnoreCase:kCapitalization_AllCharacters]) {
            [_txtValue setAutocapitalizationType:UITextAutocapitalizationTypeAllCharacters];
        }
        else if ([value isEqualToStringIgnoreCase:kCapitalization_Sentences]) {
            [_txtValue setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
        }
        else if ([value isEqualToStringIgnoreCase:kCapitalization_Words]) {
            [_txtValue setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        }
        else {
            [_txtValue setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        }
    }
    else {
        [_txtValue setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    }

    // Auto correction
    if ([keys containsObject:kCorrection]) {
        NSNumber *value = [_info objectForKey:kCorrection];
        [_txtValue setAutocorrectionType:([value boolValue] ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo)];
    }
    else {
        [_txtValue setAutocorrectionType:UITextAutocorrectionTypeNo];
    }

    // Enable edit
    if ([keys containsObject:kEnable]) {
        NSNumber *value = [info objectForKey:kEnable];
        [_txtValue setEnabled:[value boolValue]];
    }
    else {
        [_txtValue setEnabled:YES];
    }

    // Keyboard type
    if ([keys containsObject:kKeyboard]) {
        id value = [_info objectForKey:kKeyboard];

        if ([value isKindOfClass:[NSString class]]) {
            if ([value isEqualToStringIgnoreCase:kKeyboard_ASCII_Capable]) {
                [_txtValue setKeyboardType:UIKeyboardTypeASCIICapable];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_DecimalPad]) {
                [_txtValue setKeyboardType:UIKeyboardTypeDecimalPad];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_EmailAddress]) {
                [_txtValue setKeyboardType:UIKeyboardTypeEmailAddress];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_NamePhonePad]) {
                [_txtValue setKeyboardType:UIKeyboardTypeNamePhonePad];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_NumberPad]) {
                [_txtValue setKeyboardType:UIKeyboardTypeNumberPad];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_Numbers_And_Punctuation]) {
                [_txtValue setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_PhonePad]) {
                [_txtValue setKeyboardType:UIKeyboardTypePhonePad];
            }
            else if ([value isEqualToStringIgnoreCase:kKeyboard_URL]) {
                [_txtValue setKeyboardType:UIKeyboardTypeURL];
            }
            else {
                [_txtValue setKeyboardType:UIKeyboardTypeDefault];
            }
        }
        else {
            [_txtValue setKeyboardType:UIKeyboardTypeDefault];
        }
    }
    else {
        [_txtValue setKeyboardType:UIKeyboardTypeDefault];
    }

    // Enable secure
    if ([keys containsObject:kSecure]) {
        NSNumber *enableSecure = [_info objectForKey:kSecure];
        [_txtValue setSecureTextEntry:([enableSecure boolValue] ? YES : NO)];
    }
    else {
        [_txtValue setSecureTextEntry:NO];
    }
}


#pragma mark - Class's private methods


@end
