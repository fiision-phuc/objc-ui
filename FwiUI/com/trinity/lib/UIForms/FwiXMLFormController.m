#import "FwiXMLFormController.h"


@interface FwiXMLFormController () <FwiXMLFormCellDelegate> {

    NSArray    *_templateCurrent;

    NSUInteger _step;
    NSUInteger _totalSteps;
}

@property (nonatomic, readonly) UITableView *tbvCurrent;

@property (nonatomic, retain) NSDictionary  *template;
@property (nonatomic, retain) NSString *templateStyle;


/** Initialize class's private variables. */
- (void)_init;
/** Localize UI components. */
- (void)_localize;
/** Visualize all view's components. */
- (void)_visualize;

/** Validate form. */
- (BOOL)_validateForm;

/** Generate form. */
- (void)_generateForm;
/* Reset forms' positions. */
- (void)_resetForms;

/** Display new form. */
- (void)_switchFormWithDirection:(FwiDirection)direction
                      animations:(void(^)(void))animations
                      completion:(void(^)(BOOL finished))completion;

@end


@implementation FwiXMLFormController


static NSString * const _Identifier = @"FwiXMLForm";


#pragma mark - Class's constructors
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _init];
    }
    return self;
}


#pragma mark - Cleanup memory
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    FwiRelease(_formData);
    
    self.templateStyle = nil;
    self.template = nil;
    
#if !__has_feature(objc_arc)
    [_vwForm release];
    [_vwForm_tbvFormA release];
    [_vwForm_tbvFormB release];
    [_btnCancel release];
    [_btnBack release];
    [_btnNext release];
    [_btnDone release];
    [super dealloc];
#endif
}


#pragma mark - View's lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self _localize];
    [self _visualize];
    [self _resetForms];
    
    // Assigned datasource & delegate
    if (_vwForm_tbvFormA) {
        [_vwForm_tbvFormA setDataSource:self];
        [_vwForm_tbvFormA setDelegate:self];
    }
    
    if (_vwForm_tbvFormB) {
        [_vwForm_tbvFormB setDataSource:self];
        [_vwForm_tbvFormB setDelegate:self];
    }

    // Hide all components
    if (_vwForm) [_vwForm setHidden:YES];
    if (_btnBack) [_btnBack setHidden:YES];
    if (_btnNext) [_btnNext setHidden:YES];
    if (_btnDone) [_btnDone setHidden:YES];
    if (_btnCancel) [_btnCancel setHidden:YES];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


#pragma mark - View's memory handler
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - View's orientation handler
- (BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


#pragma mark - View's transition event handler
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


#pragma mark - View's key pressed event handlers
- (IBAction)handleBtnBack:(id)sender {
    BOOL shouldBackward = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(xmlFormController:shouldMoveBackwardWithData:)])
        shouldBackward = [_delegate xmlFormController:self shouldMoveBackwardWithData:_formData];

    /* Condition validation: Stop moving backward if it is required */
    if (!shouldBackward) return;

    if (_step > 0) {
        _step--;
        // Enable next button
        if ([_btnNext isHidden]) {
            [_btnNext setHidden:NO];
            [_btnNext setAlpha:0.0f];
        }
    }

    // Hide keyboard & prepare new form
    [self.view findAndResignFirstResponder];
    [self _generateForm];

    // Present form
    if (_delegate && [_delegate respondsToSelector:@selector(xmlFormControllerWillMoveBackward:)])
        [_delegate xmlFormControllerWillMoveBackward:self];

    [self _switchFormWithDirection:kDirection_LR
                        animations:^{
                            [_btnNext setAlpha:1.0f];
                            if (_step == 0) [_btnBack setAlpha:0.0f];
                            if (![_btnDone isHidden]) [_btnDone setAlpha:0.0f];
                        }
                        completion:^(BOOL finished) {
                            if (_step == 0) [_btnBack setHidden:YES];
                            if (![_btnDone isHidden]) [_btnDone setHidden:YES];

                            if (_delegate && [_delegate respondsToSelector:@selector(xmlFormControllerDidMoveBackward:)])
                                [_delegate xmlFormControllerDidMoveBackward:self];
                        }];
}
- (IBAction)handleBtnNext:(id)sender {
    /* Condition validation: Stop moving to next form if the current form is incorrect */
    BOOL isValidated = [self _validateForm];
    if (!isValidated) return;

    BOOL shouldForward = YES;
    if (_delegate && [_delegate respondsToSelector:@selector(xmlFormController:shouldMoveForwardWithData:)])
        shouldForward = [_delegate xmlFormController:self shouldMoveForwardWithData:_formData];

    /* Condition validation: Stop moving forward if it is required */
    if (!shouldForward) return;

    if (_step < (_totalSteps - 1)) {
        _step++;
        // Enable back button
        if ([_btnBack isHidden]) {
            [_btnBack setHidden:NO];
            [_btnBack setAlpha:0.0f];
        }
        // Control done button & next button
        if (_step >= (_totalSteps - 1)) {
            [_btnDone setHidden:NO];
            [_btnDone setAlpha:0.0f];
        }
    }

    // Hide keyboard & prepare new form
    [self.view findAndResignFirstResponder];
    [self _generateForm];

    // Present form
    if (_delegate && [_delegate respondsToSelector:@selector(xmlFormControllerWillMoveForward:)])
        [_delegate xmlFormControllerWillMoveForward:self];

    [self _switchFormWithDirection:kDirection_RL
                        animations:^{
                            [_btnBack setAlpha:1.0f];

                            if (_step >= (_totalSteps - 1)) {
                                [_btnNext setAlpha:0.0f];
                                [_btnDone setAlpha:1.0f];
                            }
                        }
                        completion:^(BOOL finished) {
                            if (_step >= (_totalSteps - 1)) [_btnNext setHidden:YES];

                            if (_delegate && [_delegate respondsToSelector:@selector(xmlFormControllerDidMoveForward:)])
                                [_delegate xmlFormControllerDidMoveForward:self];
                        }];
}
- (IBAction)handleBtnDone:(id)sender {
    /* Condition validation: Stop moving to next form if the current form is incorrect */
    BOOL isValidated = [self _validateForm];
    if (!isValidated) return;

    if (_delegate && [_delegate respondsToSelector:@selector(xmlFormController:didFinishWithData:)])
        [_delegate xmlFormController:self didFinishWithData:_formData];
}
- (IBAction)handleBtnCancel:(id)sender {
    if (_delegate && [_delegate respondsToSelector:@selector(xmlFormControllerDidCancel:)])
        [_delegate xmlFormControllerDidCancel:self];
}


#pragma mark - Class's properties
- (UITableView *)tbvCurrent {
    return (_step % 2 == 0 ? _vwForm_tbvFormA : _vwForm_tbvFormB);
}

- (void)setDatasource:(id<FwiXMLFormDatasource>)datasource {
    /* Condition validation */
    if (!datasource || _datasource == datasource) return;
    
    _datasource = datasource;
    [self reloadData];
}


#pragma mark - Class's public methods
- (void)reloadData {
    /* Condition validation: If the plist file is not available, do not need to execute */
    NSString *plistFile = [_datasource templateForXMLFormController:self];
    if (!plistFile) return;

    // Load plist file
    NSDictionary *form = [NSDictionary loadPlist:plistFile];

    /* Condition validation: If there is no value inside dictionary, do not need to execute */
    if (!form || [form count] == 0) return;
    
    // Reset form's data
    FwiRelease(_formData);
    _formData = [[NSMutableDictionary alloc] init];
    
    // Get template style
    self.template      = [form objectForKey:@"TemplateElement"];
    self.templateStyle = [form objectForKey:@"TemplateStyle"];
    if (_vwForm_tbvFormA) [_vwForm_tbvFormA registerNib:[UINib nibWithNibName:self.templateStyle bundle:nil] forCellReuseIdentifier:_Identifier];
    if (_vwForm_tbvFormB) [_vwForm_tbvFormB registerNib:[UINib nibWithNibName:self.templateStyle bundle:nil] forCellReuseIdentifier:_Identifier];

    // Get template element
    _step          = 0;
    _totalSteps    = [_template count];

    // Visualize Form
    [self _resetForms];
    if (_vwForm) [_vwForm setHidden:NO];
    if (_btnBack) [_btnBack setHidden:YES];
    if (_btnCancel) [_btnCancel setHidden:NO];

    if (_totalSteps > 1) {
        if (_btnNext) [_btnNext setHidden:NO];
        if (_btnDone) [_btnDone setHidden:YES];
    }
    else {
        if (_btnNext) [_btnNext setHidden:YES];
        if (_btnDone) [_btnDone setHidden:NO];
    }

    // Generate form
    [self _generateForm];
}


#pragma mark - Class's private methods
- (void)_init {
    _formData = nil;
    _templateCurrent = nil;
    
    _step = 0;
    _totalSteps = 0;
}
- (void)_localize {
}
- (void)_visualize {
    // Visualize form
    if (_vwForm) [_vwForm setClipsToBounds:YES];
    
    if (_vwForm_tbvFormA) {
        [_vwForm_tbvFormA setBounces:NO];
        [_vwForm_tbvFormA setBackgroundColor:[UIColor clearColor]];
        [_vwForm_tbvFormA setAllowsSelection:NO];
        [_vwForm_tbvFormA setAllowsSelectionDuringEditing:NO];
        [_vwForm_tbvFormA setAllowsMultipleSelection:NO];
        [_vwForm_tbvFormA setAllowsMultipleSelectionDuringEditing:NO];
        [_vwForm_tbvFormA setShowsHorizontalScrollIndicator:NO];
        [_vwForm_tbvFormA setShowsVerticalScrollIndicator:NO];
        [_vwForm_tbvFormA setSeparatorColor:[UIColor clearColor]];
        [_vwForm_tbvFormA setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
    
    if (_vwForm_tbvFormB) {
        [_vwForm_tbvFormB setBounces:NO];
        [_vwForm_tbvFormB setBackgroundColor:[UIColor clearColor]];
        [_vwForm_tbvFormB setAllowsSelection:NO];
        [_vwForm_tbvFormB setAllowsSelectionDuringEditing:NO];
        [_vwForm_tbvFormB setAllowsMultipleSelection:NO];
        [_vwForm_tbvFormB setAllowsMultipleSelectionDuringEditing:NO];
        [_vwForm_tbvFormB setShowsHorizontalScrollIndicator:NO];
        [_vwForm_tbvFormB setShowsVerticalScrollIndicator:NO];
        [_vwForm_tbvFormB setSeparatorColor:[UIColor clearColor]];
        [_vwForm_tbvFormB setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    }
}

- (BOOL)_validateForm {
    // Validate required fields
    __block BOOL isValidated = YES;
    NSArray *cells = [self.tbvCurrent visibleCells];
    
    [cells enumerateObjectsUsingBlock:^(FwiXMLFormCell *cell, NSUInteger idx, BOOL *stop) {
        if (![cell isValid]) {
            *stop = YES;
            isValidated = NO;
            
            if (_delegate && [_delegate respondsToSelector:@selector(xmlFormController:errorMessage:input:)])
                [_delegate xmlFormController:self errorMessage:cell.errorMessage input:cell.txtValue];
        }
    }];
    return isValidated;
}

- (void)_generateForm {
    // Get form data
    NSString *index  = [NSString stringWithFormat:@"%zi", _step];
    _templateCurrent = [[_template objectForKey:index] objectAtIndex:1];
    _step % 2 == 0 ? [_vwForm_tbvFormA reloadData] : [_vwForm_tbvFormB reloadData];
}
- (void)_resetForms {
    // Layout form if neccessary
    if (!(_vwForm && _vwForm_tbvFormA && _vwForm_tbvFormB)) return;
    
    [_vwForm_tbvFormA removeFromSuperview];
    [_vwForm_tbvFormB removeFromSuperview];
    [_vwForm addSubview:_vwForm_tbvFormA];
    [_vwForm addSubview:_vwForm_tbvFormB];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_vwForm_tbvFormA, _vwForm_tbvFormB);
    NSArray *tbvAConstraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_vwForm_tbvFormA]|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:views];
    NSArray *tbvAConstraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_vwForm_tbvFormA]|"
                                                                        options:0
                                                                        metrics:nil
                                                                          views:views];
    NSArray *tbvBConstraints  = [NSLayoutConstraint constraintsWithVisualFormat:@"[_vwForm_tbvFormA][_vwForm_tbvFormB(==_vwForm_tbvFormA)]"
                                                                        options:(NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom)
                                                                        metrics:nil
                                                                          views:views];
    [_vwForm addConstraints:tbvAConstraints1];
    [_vwForm addConstraints:tbvAConstraints2];
    [_vwForm addConstraints:tbvBConstraints];
    [self.view layoutIfNeeded];
}

- (void)_switchFormWithDirection:(FwiDirection)direction
                      animations:(void(^)(void))animations
                      completion:(void(^)(BOOL finished))completion
{
    /* Condition validation */
    if (!_vwForm || !_vwForm_tbvFormA || !_vwForm_tbvFormB) return;
    __block UITableView *visibleForm = (_step % 2 != 0 ? _vwForm_tbvFormA : _vwForm_tbvFormB);
    __block UITableView *hiddenForm  = (_step % 2 != 0 ? _vwForm_tbvFormB : _vwForm_tbvFormA);
    
    // Temporary disable autolayout
    _vwForm.translatesAutoresizingMaskIntoConstraints     = YES;
    hiddenForm.translatesAutoresizingMaskIntoConstraints  = YES;
    visibleForm.translatesAutoresizingMaskIntoConstraints = YES;
    
    // Perform frame calculation
    CGPoint c = visibleForm.center;
    CGPoint l = visibleForm.center;
    CGPoint r = visibleForm.center;
    l.x -= visibleForm.frame.size.width;
    r.x += visibleForm.frame.size.width;
    hiddenForm.center = (direction == kDirection_RL ? r : l);
    
    // Perform animation
    [self.view setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         visibleForm.center = (direction == kDirection_RL ? l : r);
                         hiddenForm.center  = c;
                         
                         if (animations) animations();
                     }
                     completion:^(BOOL finished) {
                         _vwForm.translatesAutoresizingMaskIntoConstraints     = NO;
                         hiddenForm.translatesAutoresizingMaskIntoConstraints  = NO;
                         visibleForm.translatesAutoresizingMaskIntoConstraints = NO;
                         NSDictionary *views = NSDictionaryOfVariableBindings(_vwForm, hiddenForm, visibleForm);
                         
                         [_vwForm_tbvFormA removeFromSuperview];
                         [_vwForm_tbvFormB removeFromSuperview];
                         [_vwForm addSubview:visibleForm];
                         [_vwForm addSubview:hiddenForm];
                         
                         // Update position
                         NSString *visibleFormat = (direction == kDirection_RL ? @"[visibleForm(==hiddenForm)][hiddenForm]" : @"[hiddenForm][visibleForm(==hiddenForm)]");
                         NSArray *hiddenFormConstraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[hiddenForm]|"
                                                                                                   options:0
                                                                                                   metrics:nil
                                                                                                     views:views];
                         NSArray *hiddenFormConstraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[hiddenForm]|"
                                                                                                   options:0
                                                                                                   metrics:nil
                                                                                                     views:views];
                         NSArray *visibleFormConstraints = [NSLayoutConstraint constraintsWithVisualFormat:visibleFormat
                                                                                                   options:(NSLayoutFormatAlignAllTop|NSLayoutFormatAlignAllBottom)
                                                                                                   metrics:nil
                                                                                                     views:views];
                         [_vwForm addConstraints:hiddenFormConstraints1];
                         [_vwForm addConstraints:hiddenFormConstraints2];
                         [_vwForm addConstraints:visibleFormConstraints];
                         [self.view layoutIfNeeded];
                         
                         // Finalize animation
                         [self.view setUserInteractionEnabled:YES];
                         if (completion) completion(finished);
                     }];
}


#pragma mark - Class's notification handlers


#pragma mark - UITableViewDataSource's members
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.tbvCurrent == tableView) {
        if (_templateCurrent && [_templateCurrent count] > 0) {
            FwiRelease(_fieldsCollection);
            
            _fieldsCollection = [[NSMutableArray alloc] initWithCapacity:[_templateCurrent count]];
            return [_templateCurrent count];
        }
    }
    return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.tbvCurrent == tableView) {
        NSString *index = [NSString stringWithFormat:@"%zi", _step];
        NSString *title = [[_template objectForKey:index] objectAtIndex:0];
        return (title.length > 0 ? title : nil);
    }
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FwiXMLFormCell *cell = (FwiXMLFormCell *)[tableView dequeueReusableCellWithIdentifier:_Identifier];
    NSDictionary   *info = [_templateCurrent objectAtIndex:indexPath.row];

    [cell setDelegate:self];
    [cell setInfo:info atIndex:indexPath];
    [cell.txtValue setText:[_formData objectForKey:[info objectForKey:kTitle]]];
    
    if (self.tbvCurrent == tableView) {
        if ([cell.txtValue isEnabled]) [_fieldsCollection addObject:cell.txtValue];
        [cell.txtValue setReturnKeyType:(indexPath.row < (_templateCurrent.count - 1) ? UIReturnKeyNext : UIReturnKeyDone)];
        [cell.txtValue setDelegate:self];
        [_vwKBNavigator reload];
    }
    return cell;
}


#pragma mark - UITableViewDelegate's members
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40.0f;
}


#pragma mark - UITextFieldDelegate's members
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyNext) {
        [[_fieldsCollection objectAtIndex:(_vwKBNavigator.currentStep + 1)] becomeFirstResponder];
    }
    else if (textField.returnKeyType == UIReturnKeyDone) {
        [self.view findAndResignFirstResponder];
        [self handleBtnDone:nil];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // Lookup FormCell
    __block FwiXMLFormCell *focusCell = nil;
    NSArray *cells = [self.tbvCurrent visibleCells];
    [cells enumerateObjectsUsingBlock:^(FwiXMLFormCell *cell, NSUInteger idx, BOOL *stop) {
        if (cell.txtValue == textField) {
            focusCell = cell;
            *stop = YES;
        }
    }];
    
    // Request delegate for custom keyboard
    if ([[focusCell keyboardType] isEqualToString:kKeyboard_Custom]) {
        [textField setKeyboardType:UIKeyboardTypeDefault];
        
        // Try to ask delegate if it could provide custom keyboard
        if (_delegate && [_delegate respondsToSelector:@selector(xmlFormController:customKeyboardForField:withInput:)])
            [_delegate xmlFormController:self customKeyboardForField:[focusCell title] withInput:textField];
    }
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSArray *array = [self.tbvCurrent visibleCells];
    
    [array enumerateObjectsUsingBlock:^(FwiXMLFormCell *cell, NSUInteger idx, BOOL *stop) {
        if (cell.txtValue == textField) {
            *stop = YES;

            NSString *input = [[(FwiTextField *)textField text] trim];
            NSDictionary *info = [_templateCurrent objectAtIndex:idx];
            if (textField.text.length > 0) {
                [_formData setObject:[textField.text trim] forKey:[info objectForKey:kTitle]];
                
                if (_delegate && [_delegate respondsToSelector:@selector(xmlFormController:didFinishEditingForField:withInput:)])
                    [_delegate xmlFormController:self didFinishEditingForField:[info objectForKey:kTitle] withInput:input];
            }
        }
    }];
}


#pragma mark - FwiXMLFormCellDelegate's members
- (NSString *)cell:(FwiXMLFormCell *)cell localizeStringForString:(NSString *)string {
    if (_datasource && [_datasource respondsToSelector:@selector(xmlFormController:localizeStringForString:)]) {
        return [_datasource xmlFormController:self localizeStringForString:string];
    }
    else {
        return string;
    }
}


@end
