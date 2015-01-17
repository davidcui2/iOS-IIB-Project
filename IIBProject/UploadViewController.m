//
//  UploadViewController.m
//  IIBProject
//
//  Created by Zhihao Cui on 15/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "UploadViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface UploadViewController ()

- (void)addToLog:(NSString *)input;

@property (strong, nonatomic) NSString *ipAddress;
@property (strong, nonatomic) NSString *defaultAddress;


@end

@implementation UploadViewController

int deviceID;

@synthesize progressBar;
@synthesize logText;
@synthesize managedObjectContext;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    logText.layer.borderWidth = 2.0f;
    logText.layer.borderColor = [[UIColor grayColor] CGColor];
    
    progressBar.hidden = 1;
    
    //default
    self.defaultAddress = @"192.168.165.100";
    self.ipAddress = self.defaultAddress;
    self.textField.text = self.ipAddress;
    
    NSUUID *oNSUUID = [[UIDevice currentDevice] identifierForVendor];
    if ([oNSUUID.UUIDString isEqualToString:@"388BDB9E-ECC1-4644-BD80-71F48118104C"])
    {
        deviceID = 2;
    }
    else
    {
        deviceID = 1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadButtonPressed:(id)sender {
    
    NSString* fullAddress = [NSString stringWithFormat:@"http://%@/~DavidCui/Direct/uploadDataUsage.php", self.ipAddress];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullAddress]];
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    if (count > 0) {
        progressBar.hidden = 0;
    }
    else {
        
        [self addToLog:[NSString stringWithFormat:@"Sorry, no data found in Core Data DB"]];
        return;
    }
    
    // Upload in background
    NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
    [progressQueue addOperationWithBlock:^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Y-m-d H:mm:s"];
        //        NSLog(@"%@",[formatter stringFromDate:[NSDate date]]);
        
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSFetchRequest *allData = [[NSFetchRequest alloc] init];
        [allData setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:context]];
        [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError * error = nil;
        NSArray * data = [context executeFetchRequest:allData error:&error];
        //error handling goes here
        int currentCounter = 0;
        
        for (DataStorage * dt in data) {
            NSString *post = [NSString stringWithFormat:@"deviceID=%d&timeStamp=%@&wifiSent=%@&wifiReceived=%@&wwanSent=%@&wwanReceived=%@&gpsLatitude=%@&gpsLongitude=%@&", deviceID,
                              [formatter stringFromDate:[NSDate date]],dt.wifiSent,dt.wifiReceived,dt.wwanSent,dt.wwanReceived,dt.gpsLatitude,dt.gpsLongitude];
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];
            
            NSError *error;
            NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil     error:&error];
            if (returnData)
            {
//                                NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
//                                NSLog(@"Resp string: %@",json);
                
                [context deleteObject:dt];

            }
            else
            {
                NSLog(@"Error: %@", error);
                break;
            }
            
            currentCounter++;
            NSLog(@"Uploaded No.%d", currentCounter);
            
            
            float progressValue = (float)currentCounter/count;
            
            if (progressValue == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressBar.hidden = 1;
                    [self addToLog:[NSString stringWithFormat:@"Uploaded %d entries", currentCounter]];
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressBar setProgress:progressValue];
                });
            }
        }
        NSError *saveError = nil;
        [context save:&saveError];
        
    }];
    
    
    
}

- (void)addToLog:(NSString *)input
{
    [[logText textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n",[NSDate date],input]]];
}

- (IBAction)clearLogs:(id)sender {
    [logText setText:@""];
}

- (IBAction)startEditIP:(id)sender {
    [self.textField becomeFirstResponder];

}

- (IBAction)setIP:(id)sender {
    [self.textField resignFirstResponder];
    if ([self.textField.text length]>0) {
        self.ipAddress = self.textField.text;
    }
    // set to default value
    else{
        self.ipAddress = self.defaultAddress;
    }
    self.textField.text = self.ipAddress;
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
