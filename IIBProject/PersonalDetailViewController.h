//
//  PersonalDetailViewController.h
//  IIBProject
//
//  Created by Zhihao Cui on 01/02/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface PersonalDetailViewController : UIViewController <UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *deviceNameTextField;
- (IBAction)deleteAllLocalDataPressed:(id)sender;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
