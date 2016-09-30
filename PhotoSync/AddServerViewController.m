//
//  AddServerViewController.m
//  PhotoSync
//
//  Created by Hong on 9/30/16.
//  Copyright © 2016 Hong. All rights reserved.
//

#import "AddServerViewController.h"
#import "DAVKit.h"

@interface AddServerViewController ()<DAVRequestDelegate>

@end

@implementation AddServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _name.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"NAME"];
    _passwd.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"PASS"];
    _server.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SERVER"];
    
    if (_server.text.length == 0) {
        _server.text = @"http://cloud.vniapp.com/remote.php/webdav";
    }
    
}

- (IBAction)checkAndSave:(id)sender
{
    NSString *name = [_name text];
    NSString *pass = [_passwd text];
    NSString *url  = [_server text];
    
    DAVCredentials *credentials = [DAVCredentials credentialsWithUsername:name password:pass];
    NSString *root = url; // don't include the trailing / (slash)
    DAVSession * session = [[DAVSession alloc] initWithRootURL:[NSURL URLWithString:root] credentials:credentials];
    [session resetCredentialsCache];
    
    DAVListingRequest *request = [[DAVListingRequest alloc] initWithPath:@"/"];
    [session enqueueRequest:request];
    request.delegate = self;
    
}

- (void)request:(DAVRequest *)aRequest didFailWithError:(NSError *)error
{
    
    NSString *msg = [NSString stringWithFormat:@"请确保用户名密码和服务器的正确性\n%@",[error localizedDescription] ];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)request:(DAVRequest *)aRequest didSucceedWithResult:(id)result
{
    [[NSUserDefaults standardUserDefaults] setValue:_name.text forKey:@"NAME"];
    [[NSUserDefaults standardUserDefaults] setValue:_passwd.text forKey:@"PASS"];
    [[NSUserDefaults standardUserDefaults] setValue:_server.text forKey:@"SERVER"];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示信息" message:@"服务器信息设置成功" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)closeAndCheck:(id)sender {
    
    [_server resignFirstResponder];
    [_name resignFirstResponder];
    [_passwd resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
@end
