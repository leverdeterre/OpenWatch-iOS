//
//  OWLoginViewController.m
//  OpenWatch
//
//  Created by Christopher Ballinger on 11/12/12.
//  Copyright (c) 2012 OpenWatch FPC. All rights reserved.
//

#import "OWLoginViewController.h"
#import "OWStrings.h"
#import "OWSettingsController.h"
#import "OWAccountAPIClient.h"
#import "MBProgressHUD.h"
#import "OWUtilities.h"
#import "OWAppDelegate.h"
#import "OWConstants.h"
#import "OWStrings.h"

#define PADDING 10.0f

@interface OWLoginViewController ()
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@end

@implementation OWLoginViewController
@synthesize emailTextField, passwordTextField, loginButton, helpLabel;
@synthesize headerImageView, account, loginOrSignupSegmentedControl, logoutButton, cancelButton;
@synthesize showCancelButton, forgotPasswordButton;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = LOGIN_STRING;
        OWSettingsController *settingsController = [OWSettingsController sharedInstance];
        self.account = settingsController.account;
        
        self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:CANCEL_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed:)];
        self.showCancelButton = YES;
        
        self.forgotPasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.forgotPasswordButton setTitle:FORGOT_PASSWORD_STRING forState:UIControlStateNormal];
        self.forgotPasswordButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        self.forgotPasswordButton.titleLabel.textColor = [UIColor darkGrayColor];
        self.forgotPasswordButton.titleLabel.shadowColor = [UIColor whiteColor];
        self.forgotPasswordButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
        self.forgotPasswordButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.forgotPasswordButton addTarget:self action:@selector(forgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void) forgotPassword:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kPasswordResetURL] forceOpenInSafari:YES];
    [[Mixpanel sharedInstance] track:@"Forgot Password"];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    
    self.loginOrSignupSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[LOGIN_STRING, SIGNUP_STRING]];
    [self.loginOrSignupSegmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.loginOrSignupSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.loginOrSignupSegmentedControl.selectedSegmentIndex = 0;
    [self.scrollView addSubview:loginOrSignupSegmentedControl];
    [self.scrollView addSubview:forgotPasswordButton];

    
    [self setupFields];

    self.helpLabel = [[UILabel alloc] init];
    self.helpLabel.textAlignment = NSTextAlignmentCenter;
    self.helpLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.helpLabel.numberOfLines = 0;
    self.helpLabel.text = SIGNUP_HELP_STRING;
    self.helpLabel.shadowColor = [UIColor whiteColor];
    self.helpLabel.shadowOffset = CGSizeMake(0, 1);
    self.helpLabel.textColor = [UIColor darkGrayColor];
    self.helpLabel.backgroundColor = [UIColor clearColor];
    self.helpLabel.font = [UIFont systemFontOfSize:16.0f];
    

    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:SUBMIT_STRING style:UIBarButtonItemStyleDone target:self action:@selector(loginButtonPressed:)];
    self.loginButton.tintColor = [OWUtilities doneButtonColor];
    
    self.logoutButton = [[UIBarButtonItem alloc] initWithTitle:LOGOUT_STRING style:UIBarButtonItemStyleDone target:self action:@selector(logoutButtonPressed:)];
    self.logoutButton.tintColor = [OWUtilities doneButtonColor];
    
    self.headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"openwatch.png"]];
    self.headerImageView.contentMode = UIViewContentModeCenter;
    [self.scrollView addSubview:headerImageView];

    
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[Mixpanel sharedInstance] track:@"Viewing Old Login Screen"];
    
    self.scrollView.frame = self.view.bounds;
    self.scrollView.contentSize = self.view.bounds.size;
    
    CGFloat padding = PADDING;
    self.headerImageView.frame = CGRectMake(padding, 0, self.view.frame.size.width-(padding*2), headerImageView.image.size.height+(padding*2));

    self.loginOrSignupSegmentedControl.frame = CGRectMake(padding, self.headerImageView.frame.size.height, self.view.frame.size.width-(padding*2), 35.0f);
    self.loginOrSignupSegmentedControl.selectedSegmentIndex = 1;
    CGFloat loginTableViewYOrigin = loginOrSignupSegmentedControl.frame.size.height + loginOrSignupSegmentedControl.frame.origin.y;
    self.groupedTableView.frame = CGRectMake(0, loginTableViewYOrigin, self.view.frame.size.width, self.view.frame.size.height-loginTableViewYOrigin);
    
    CGFloat buttonWidth = 200.0f;
    CGFloat buttonHeight = 30.0f;
    self.forgotPasswordButton.frame = CGRectMake(self.view.frame.size.width/2 - buttonWidth / 2, self.view.frame.size.height - buttonHeight - 30, buttonWidth, buttonHeight);
    
    self.forgotPasswordButton.titleLabel.textColor = [UIColor lightTextColor];
    
    self.forgotPasswordButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view bringSubviewToFront:forgotPasswordButton];
    
    [self refreshLoginButtons];
}

- (void) refreshLoginButtons {
    if (![account isLoggedIn]) {
        showCancelButton = NO;
    }
    if (showCancelButton) {
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = logoutButton;
        self.emailTextField.enabled = NO;
        self.emailTextField.textColor = [UIColor lightGrayColor];
        self.passwordTextField.enabled = NO;
        self.passwordTextField.textColor = [UIColor lightGrayColor];
        self.loginOrSignupSegmentedControl.hidden = YES;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = loginButton;
        self.emailTextField.enabled = YES;
        self.emailTextField.textColor = self.textFieldTextColor;
        self.passwordTextField.enabled = YES;
        self.passwordTextField.textColor = self.textFieldTextColor;
        self.loginOrSignupSegmentedControl.hidden = NO;
    }
}



-(void)setupFields
{
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.delegate = self;
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailTextField.returnKeyType = UIReturnKeyDone;
    self.emailTextField.textColor = self.textFieldTextColor;
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.placeholder = REQUIRED_STRING;
    NSString *email = account.email;
    if (email) {
        self.emailTextField.text = email;
        self.loginOrSignupSegmentedControl.selectedSegmentIndex = 0;
    }
    
    [self addCellInfoWithSection:0 row:0 labelText:EMAIL_STRING cellType:kCellTypeTextField userInputView:self.emailTextField];
    
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.textColor = self.textFieldTextColor;
    self.passwordTextField.placeholder = REQUIRED_STRING;
    
    NSString *password = account.password;
    if (password) {
        self.passwordTextField.text = password;
    }
    
    [self addCellInfoWithSection:0 row:1 labelText:PASSWORD_STRING cellType:kCellTypeTextField userInputView:self.passwordTextField];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showHUD {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.loginButton.enabled = NO;
}

- (void) hideHUD {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    self.loginButton.enabled = YES;
}


- (void)loginButtonPressed:(id)sender {
    BOOL fields = [self checkFields];
    if(fields)
    {
        account.email = self.emailTextField.text;
        account.password = self.passwordTextField.text;
        [self.emailTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        [self showHUD];
        if (loginOrSignupSegmentedControl.selectedSegmentIndex == 0) {
            [[OWAccountAPIClient sharedClient] loginWithAccount:account success:^{
                [self loginSuccess];
            } failure:^(NSString *reason) {
                [self loginFailure:reason];
            }];
        } else {
            [[OWAccountAPIClient sharedClient] signupWithAccount:account success:^{
                [self loginSuccess];
            } failure:^(NSString *reason) {
                [self loginFailure:reason];
            }];
        }
    }
}

- (void) loginFailure:(NSString*)reason {
    NSLog(@"Login failure: %@", reason);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:USER_PASS_WRONG_STRING delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
    [alert show];
    [self hideHUD];
    [[Mixpanel sharedInstance] track:@"Login Failure"];
}

- (void) loginSuccess {
    NSLog(@"Login Success");
    [self refreshLoginButtons];
    [self hideHUD];
    [OW_APP_DELEGATE.dashboardViewController.navigationController popToRootViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    [[Mixpanel sharedInstance] track:@"Login Success"];

}

- (void)logoutButtonPressed:(id)sender {
    [self.account clearAccountData];
    [self refreshLoginButtons];
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
    
    [[Mixpanel sharedInstance] track:@"Logout"];
}


-(BOOL)checkFields
{
    BOOL fields = emailTextField.text && ![emailTextField.text isEqualToString:@""] && passwordTextField.text && ![passwordTextField.text isEqualToString:@""];
    
    if(!fields)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:USER_PASS_BLANK_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
    
    return fields;
}

- (UIView*) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return helpLabel;
    }
    return nil;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 50.0f;
    }
    return 0.0f;
}

- (void) segmentedControlValueChanged:(id)sender {
    
}

- (void)keyboardWillShow: (NSNotification *) notif{
    [self.scrollView setContentOffset:CGPointMake(0, self.headerImageView.frame.size.height-PADDING) animated:YES];
}

@end
