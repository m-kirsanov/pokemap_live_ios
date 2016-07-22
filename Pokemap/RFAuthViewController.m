//
//  RFAuthViewController.m
//  Pokemap
//
//  Created by Михаил on 22.07.16.
//  Copyright © 2016 ruffneck. All rights reserved.
//

#import "RFAuthViewController.h"
#import "RFAuthManager.h"
#import <UICKeyChainStore.h>

@interface RFAuthViewController ()

@property (nonatomic, strong) IBOutlet UITextField *loginTextField;
@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;
@property (nonatomic, strong) IBOutlet UIButton *submitButton;
@end

@implementation RFAuthViewController

- (IBAction)submitTap:(id)sender {
    
    [[UICKeyChainStore keyChainStore] setString:_loginTextField.text forKey:@"username"];
    [[UICKeyChainStore keyChainStore] setString:_passwordTextField.text forKey:@"password"];
    
    
    NSString *username = [[UICKeyChainStore keyChainStore] stringForKey:@"username"];
    NSString *password = [[UICKeyChainStore keyChainStore] stringForKey:@"password"];
    
    if (username.length > 0 && password.length > 0) {
        
        if (_completionBlock) {
            _completionBlock(YES);
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login error"
                                                        message:@"Enter login and password"
                                                       delegate:nil
                                              cancelButtonTitle:@"Close"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _loginTextField.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.2];
    _passwordTextField.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:.2];
    
    self.title = @"Pokemap Login";
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
