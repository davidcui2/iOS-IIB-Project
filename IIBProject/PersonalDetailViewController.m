//
//  PersonalDetailViewController.m
//  IIBProject
//
//  Created by Zhihao Cui on 01/02/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "PersonalDetailViewController.h"

@interface PersonalDetailViewController ()

- (void)confirmInformation;

@end

@implementation PersonalDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    // Get the stored data before the view loads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"firstName"]) {
        _firstNameTextField.text = [defaults objectForKey:@"firstName"];
    }
    if ([defaults objectForKey:@"lastName"]) {
        _lastNameTextField.text = [defaults objectForKey:@"lastName"];
    }
    if ([defaults objectForKey:@"ownerEmail"]) {
        _emailTextField.text = [defaults objectForKey:@"ownerEmail"];
    }
    if ([defaults objectForKey:@"deviceName"]) {
        _deviceNameTextField.text = [defaults objectForKey:@"deviceName"];
    }
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(confirmInformation)];
    self.navigationItem.rightBarButtonItem = anotherButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)confirmInformation
{
    self.navigationItem.backBarButtonItem.enabled = true;
    // Get the stored data before the view loads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:_firstNameTextField.text forKey:@"firstName"];
    [defaults setObject:_lastNameTextField.text forKey:@"lastName"];
    [defaults setObject:_emailTextField.text forKey:@"ownerEmail"];
    [defaults setObject:_deviceNameTextField.text forKey:@"deviceName"];

    
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyNext) {
        UIView *next = [[textField superview] viewWithTag:textField.tag + 1];
        [next becomeFirstResponder];
    }
    else if (textField.returnKeyType == UIReturnKeyDone) {
        [textField resignFirstResponder];
        [self confirmInformation];
    }
    return YES;
}

#pragma Clear Data

- (void) askForClearCoreData
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"You are about to delete all recorded data on this device. This cannot be recovered!"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Delete!",nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:@"Delete!"]) {
        [self clearCoreData];
    }
    
}

- (void) clearCoreData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
    [allData setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:context]];
    [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * data = [context executeFetchRequest:allData error:&error];
    //error handling goes here
    for (NSManagedObject * dt in data) {
        [context deleteObject:dt];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    //more error handling here
    NSLog(@"Cleared all data at %@", [NSDate date]);
}


- (IBAction)deleteAllLocalDataPressed:(id)sender {
    [self askForClearCoreData];
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
