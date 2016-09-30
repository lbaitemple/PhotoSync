//
//  AddServerViewController.h
//  PhotoSync
//
//  Created by Hong on 9/30/16.
//  Copyright © 2016 Hong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddServerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *server;
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *passwd;

- (IBAction)closeAndCheck:(id)sender;

- (IBAction)checkAndSave:(id)sender;

@end
