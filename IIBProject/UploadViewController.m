//
//  UploadViewController.m
//  IIBProject
//
//  Created by Zhihao Cui on 15/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "UploadViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "PersonalDetailViewController.h"

#import "Reachability.h"

@interface UploadViewController ()

- (void)addToLog:(NSString *)input;

@property (strong, nonatomic) NSString *ipAddress;
@property (strong, nonatomic) NSString *defaultAddress;



@property (nonatomic, strong) CMMotionActivityManager *motionActivitiyManager;

@end

@implementation UploadViewController

@synthesize motionActivitiyManager = _motionActivitiyManager;

NSUUID * deviceUUID;

-(void)viewDidAppear:(BOOL)animated{
    // Get the stored data before the view loads
    if (![self deviceInfoIsEntered]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                        message:@"Please provide your personal information first."
                                                       delegate:self
                                              cancelButtonTitle:@"Sure"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.logText.layer.borderWidth = 2.0f;
    self.logText.layer.borderColor = [[UIColor grayColor] CGColor];
    
    self.progressBar.hidden = 1;
    
    // Get the stored data before the view loads
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults objectForKey:@"deleteLocalValue"] == nil) {
        [defaults setBool:NO forKey:@"deleteLocalValue"];
    }
    _deleteLocalSwitch.on = [defaults boolForKey:@"deleteLocalValue"];
    
    //default
    self.defaultAddress = @"www.zhihaodatatrack.com";
    self.ipAddress = self.defaultAddress;
    self.textField.text = self.ipAddress;
    
    deviceUUID = [[UIDevice currentDevice] identifierForVendor];
    
    
    if (_motionActivitiyManager == nil) {
        _motionActivitiyManager = [[CMMotionActivityManager alloc]init];
    }
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
    [self addToLog:[NSString stringWithFormat:@"DataStorage Total Count = %lu",(unsigned long)count]];
//    NSLog(@"Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    // TEST!!!
    //    [self updateLastUpdateDate:[NSDate dateWithTimeIntervalSinceNow:-1*3600*24]];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadButtonPressed:(id)sender {
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
        [self addToLog:[NSString stringWithFormat:@"Sorry, internet connection"]];
        return;
    }
    else if (status == ReachableViaWiFi)
    {
        //WiFi
    }
    else if (status == ReachableViaWWAN)
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Upload stopped"
                                                          message:@"Please connect to WiFi first!"
                                                         delegate:nil
                                                cancelButtonTitle:@"Back"
                                                otherButtonTitles:nil];
        [message show];
        
        return;
    }
    
//    NSString* fullAddress = [NSString stringWithFormat:@"http://%@/Direct/uploadDataUsage.php", self.ipAddress];
//    [self httpPostWithOneEntryEach:fullAddress];
    
    NSString* fullAddress = [NSString stringWithFormat:@"http://%@/Direct/uploadDataUsageJson.php", self.ipAddress];
    [self httpPostWithJson:fullAddress];
    
}

- (void)addToLog:(NSString *)input
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"Y-M-D H:mm:s"];
    [[self.logText textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n",[formatter stringFromDate:[NSDate date]],input]]];
}

- (IBAction)clearLogs:(id)sender {
    [self.logText setText:@""];
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

- (NSDate *)getLastUpdateTime
{
    // Get last uploaded time
    NSDate *lastUpdateTime;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *allData = [[NSFetchRequest alloc] init];
    [allData setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:context]];
    [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * data = [context executeFetchRequest:allData error:&error];
    
    
    NSDate *sevenDatesB4 = [NSDate dateWithTimeIntervalSinceNow:-7*24*3600+1];
    
    for (MotionActivityRecord * dt in data) {
        lastUpdateTime = dt.lastUpdateTime;
        break;
    }
    
    if (!(lastUpdateTime)) {
        lastUpdateTime = sevenDatesB4;
    }
    else lastUpdateTime = [lastUpdateTime laterDate:sevenDatesB4];
    
    return lastUpdateTime;
}

- (void) updateLastUpdateDate:(NSDate *)lastUpdateDate
{
    // Get last uploaded time
    NSManagedObjectContext *context = [self managedObjectContext];
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
//    NSLog(@"MotionActivityRecord Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    if (count > 0) {
        NSFetchRequest *allData = [[NSFetchRequest alloc] init];
        [allData setEntity:[NSEntityDescription entityForName:@"MotionActivityRecord" inManagedObjectContext:context]];
        [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        
        NSError * error = nil;
        NSArray * data = [context executeFetchRequest:allData error:&error];
        
        for (MotionActivityRecord * dt in data) {
            dt.lastUpdateTime = lastUpdateDate;
            break;
        }
    }
    else {
        NSManagedObjectContext *context = [self managedObjectContext];
        MotionActivityRecord *motionActivityRecord = [NSEntityDescription
                                                      insertNewObjectForEntityForName:@"MotionActivityRecord" inManagedObjectContext:context];
        motionActivityRecord.lastUpdateTime = lastUpdateDate;
    }
    NSError *saveError = nil;
    [context save:&saveError];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:@"Yes"]) {
        [self uploadMotionActivityJson];
    }
    else if ([title isEqualToString:@"Sure"]) { // Go to personal detail page
        [self performSegueWithIdentifier:@"showPersonalDetail" sender:self];
    }
}

- (IBAction)deleteLocalSwitchValueChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:_deleteLocalSwitch.on forKey:@"deleteLocalValue"];
}

- (BOOL) deviceInfoIsEntered
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ((![defaults objectForKey:@"firstName"])||(![defaults objectForKey:@"lastName"])||
        (![defaults objectForKey:@"ownerEmail"])||(![defaults objectForKey:@"deviceName"]))
        return false;
    else if (([[defaults objectForKey:@"firstName"] length]==0)||([[defaults objectForKey:@"lastName"] length]==0)||
             ([[defaults objectForKey:@"ownerEmail"] length]==0)||([[defaults objectForKey:@"deviceName"] length]==0))
        return false;

    return true;
    
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

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [self setIP:nil];
    return YES;
}


//#pragma mark - NSURLConnection Delegate Methods
//
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    _responseData = [NSMutableData data];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [_responseData appendData:data];
//}
//
//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
//                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
//    // Return nil to indicate not necessary to store a cached response for this connection
//    return nil;
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    NSLog(@"response data - %@", [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding]);
//}
//
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
//    // The request has failed for some reason!
//    // Check the error var
//    NSLog(error);
//}

#pragma mark - HTTP Post

- (void)httpPostWithJson:(NSString *)postAddress {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *startDate;
    if(![defaults objectForKey:@"lastDataUsageUploadTimestamp"])
    {
        startDate = [[NSDate alloc]initWithTimeIntervalSince1970:0];
    }
    else
    {
        startDate = [defaults objectForKey:@"lastDataUsageUploadTimestamp"];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp > %@", startDate];
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    [fetchRequest setPredicate:predicate];
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    if (count > 0) {
        self.progressBar.hidden = 0;
    }
    else {
        
        [self addToLog:[NSString stringWithFormat:@"Sorry, no new data found in Core Data DB"]];
        if ([CMMotionActivityManager isActivityAvailable]) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Further Upload"
                                                              message:@"Do you want to upload device activity?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                                    otherButtonTitles:@"Yes", nil];
            [message show];
            
        }
        return;
    }

    NSMutableURLRequest *newRequest = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:postAddress]cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    
    // Upload in background
    NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
    [progressQueue addOperationWithBlock:^{
        // Json: {dict:@"deviceInfoKey"{UUID,firstName,lastName,email},@"deviceInfoData"{xx-xx-xx,name,name,name@email.com}
        //              @"dataTypeKey"{time,wifi....},@"actualData"{dataArray1,dataArray2..}}
        
        
        
        NSArray *deviceInfoKey = [NSArray arrayWithObjects:@"UUID",@"firstName",@"lastName",@"email", @"deviceName", nil];
        NSArray *deviceInfoData = [NSArray arrayWithObjects:
                                   deviceUUID.UUIDString,
                                   [defaults objectForKey:@"firstName"],
                                   [defaults objectForKey:@"lastName"],
                                   [defaults objectForKey:@"ownerEmail"],
                                   [defaults objectForKey:@"deviceName"]//[[defaults objectForKey:@"deviceName"] stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"]
                                   , nil];
        
        NSArray *dataTypeKey = [NSArray arrayWithObjects:@"timeStamp",@"wifiSent",@"wifiReceived",@"wwanSent",
                                @"wwanReceived",@"gpsLatitude",@"gpsLongitude",@"estimateSpeed", nil];
        NSMutableArray *actualData = [[NSMutableArray alloc]initWithCapacity:count];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Y-M-d H:mm:s"];
        //        NSLog(@"%@",[formatter stringFromDate:[NSDate date]]);
        
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSFetchRequest *allData = [[NSFetchRequest alloc] init];
        [allData setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:context]];
        [allData setIncludesPropertyValues:NO]; //only fetch the managedObjectID
        [allData setPredicate:predicate];
        
        NSError * error = nil;
        NSArray * data = [context executeFetchRequest:allData error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addToLog:[NSString stringWithFormat:@"Error: %@", error]];
            });
            NSLog(@"Error: %@", error);
        }
        //error handling goes here
        int currentCounter = 0;
        
        NSDate *latestTimeStamp = [[NSDate alloc]initWithTimeIntervalSince1970:0];
        
        for (DataStorage * dt in data) {
            [actualData addObject:[NSArray arrayWithObjects:
                                   [formatter stringFromDate:dt.timeStamp],
                                   [dt.wifiSent stringValue],
                                   [dt.wifiReceived stringValue],
                                   [dt.wwanSent stringValue],
                                   [dt.wwanReceived stringValue],
                                   [dt.gpsLatitude stringValue],
                                   [dt.gpsLongitude stringValue],
                                   [dt.estimateSpeed stringValue], nil]];
            
            latestTimeStamp = [latestTimeStamp laterDate:dt.timeStamp];
            currentCounter++;
            if (currentCounter%100 == 0) NSLog(@"JSON added No.%d", currentCounter);
            
            float progressValue = (float)currentCounter/count;
            
            if (progressValue == 1) {
                NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:deviceInfoKey,deviceInfoData,dataTypeKey,actualData, nil]
                                                                           forKeys:[NSArray arrayWithObjects:@"deviceInfoKey",@"deviceInfoData",@"dataTypeKey",@"dataTypeValue", nil]];
                if ([NSJSONSerialization isValidJSONObject:jsonDictionary]){
                    NSLog(@"Can be converted to JSON");
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
                    
                    //                    [newRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                    [newRequest setHTTPMethod:@"POST"];
                    [newRequest setHTTPBody:jsonData];
                    [newRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
                    
                    NSData *returnData = [NSURLConnection sendSynchronousRequest:newRequest returningResponse:nil     error:&error];
                    if (returnData)
                    {
                        NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                        NSLog(@"Resp string: %@",json);
                        
                        if ([json hasSuffix:@"All success."]) {
                            [defaults setObject:latestTimeStamp forKey:@"lastDataUsageUploadTimestamp"];

                            if (_deleteLocalSwitch.on) {
                                [self clearCoreData];
                            }
                        }
                        
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.progressBar.hidden = 1;
                            [self addToLog:[NSString stringWithFormat:@"Uploaded %d entries", currentCounter]];
                            
                            
                            if ([CMMotionActivityManager isActivityAvailable]) {
                                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Further Upload"
                                                                                  message:@"Do you want to upload device activity?"
                                                                                 delegate:self
                                                                        cancelButtonTitle:@"Cancel"
                                                                        otherButtonTitles:@"Yes", nil];
                                [message show];
                                
                            }
                        });
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self addToLog:[NSString stringWithFormat:@"Error: %@", error]];
                        });
                        NSLog(@"Error: %@", error);
            
            
            
                    }
                }
                else{
                    NSLog(@"Cannot be converted to JSON");
                }
                
                
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressBar setProgress:progressValue];
                });
            }
        }
        
        error = nil;

    }];
}

- (void)httpPostWithOneEntryEach:(NSString *)postAddress {
    IIBPostRequest *newRequest = [[IIBPostRequest alloc]initWithURLString:postAddress];
    [newRequest setPostKey:@"UUID" withValue:deviceUUID.UUIDString];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [newRequest setPostKey:@"firstName" withValue:[defaults objectForKey:@"firstName"]];
    [newRequest setPostKey:@"lastName" withValue:[defaults objectForKey:@"lastName"]];
    [newRequest setPostKey:@"ownerEmail" withValue:[defaults objectForKey:@"ownerEmail"]];
    [newRequest setPostKey:@"deviceName" withValue:[defaults objectForKey:@"deviceName"]];
    
    
    // Count all entities
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"DataStorage" inManagedObjectContext:self.managedObjectContext]];
    [fetchRequest setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Count = %lu",(unsigned long)count);
    if(count == NSNotFound) {
        //Handle error
    }
    
    if (count > 0) {
        self.progressBar.hidden = 0;
    }
    else {
        
        [self addToLog:[NSString stringWithFormat:@"Sorry, no data found in Core Data DB"]];
        return;
    }
    
    // Upload in background
    NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
    [progressQueue addOperationWithBlock:^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"Y-M-d H:mm:s"];
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
            
            [newRequest setPostKey:@"timeStamp" withValue:[formatter stringFromDate:dt.timeStamp]];
            [newRequest setPostKey:@"wifiSent" withValue:[dt.wifiSent stringValue]];
            [newRequest setPostKey:@"wifiReceived" withValue:[dt.wifiReceived stringValue]];
            [newRequest setPostKey:@"wwanSent" withValue:[dt.wwanSent stringValue]];
            [newRequest setPostKey:@"wwanReceived" withValue:[dt.wwanReceived stringValue]];
            [newRequest setPostKey:@"gpsLatitude" withValue:[dt.gpsLatitude stringValue]];
            [newRequest setPostKey:@"gpsLongitude" withValue:[dt.gpsLongitude stringValue]];
            [newRequest setPostKey:@"estimateSpeed" withValue:[dt.estimateSpeed stringValue]];
            
            [newRequest prepareForPost];
            
            NSError *error;
            NSData *returnData = [NSURLConnection sendSynchronousRequest:newRequest returningResponse:nil     error:&error];
            if (returnData)
            {
                NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                NSLog(@"Resp string: %@",json);
                
                if (_deleteLocalSwitch.on) {
                    [context deleteObject:dt];
                }
                
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addToLog:[NSString stringWithFormat:@"Error: %@", error]];
                });
                NSLog(@"Error: %@", error);
                break;
            }
            
            currentCounter++;
            NSLog(@"Uploaded No.%d", currentCounter);
            
            // TEST!!!!!!!
            //            if(currentCounter > 100) break;
            
            
            float progressValue = (float)currentCounter/count;
            
            if (progressValue == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.progressBar.hidden = 1;
                    [self addToLog:[NSString stringWithFormat:@"Uploaded %d entries", currentCounter]];
                    
                    
                    if ([CMMotionActivityManager isActivityAvailable]) {
                        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Further Upload"
                                                                          message:@"Do you want to upload device activity?"
                                                                         delegate:self
                                                                cancelButtonTitle:@"Cancel"
                                                                otherButtonTitles:@"Yes", nil];
                        [message show];
                        
                    }
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

- (void)uploadMotionActivity
{
    NSDate *lastUpdateTime = [self getLastUpdateTime];
    
    
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.center=self.view.center;
    [activityView startAnimating];
    [self.view addSubview:activityView];
    
    [_motionActivitiyManager queryActivityStartingFromDate:lastUpdateTime toDate:[NSDate date] toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray *activities, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:[error description]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return ;
        }
        if (error != nil && error.code == CMErrorMotionActivityNotAuthorized) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addToLog:@"The app isn't authorized to use motion activity support."];
                [activityView stopAnimating];
            });
        }
        else{
            //            for (CMMotionActivity *activity in activities) {
            //                // Only need High confidence activity
            //                if (activity.confidence == CMMotionActivityConfidenceHigh) {
            //                    // Extract a function return all possible activity
            //                    if (activity.automotive) NSLog(@"Automotive: %d, Start date: %@", activity.automotive, activity.startDate);
            //                    if (activity.cycling) NSLog(@"Cycling: %d, Start date: %@", activity.cycling, activity.startDate);
            //                    if (activity.running) NSLog(@"Running: %d, Start date: %@", activity.running, activity.startDate);
            //                    if (activity.walking) NSLog(@"Walking: %d, Start date: %@", activity.walking, activity.startDate);
            //                    if (activity.stationary) NSLog(@"Stationary: %d, Start Date: %@", activity.stationary, activity.startDate);
            //                }
            //
            //            }
            
            NSString* fullAddress = [NSString stringWithFormat:@"http://%@/Direct/uploadActivity.php", self.ipAddress];
            
            IIBPostRequest *newRequest = [[IIBPostRequest alloc]initWithURLString:fullAddress];
            [newRequest setPostKey:@"UUID" withValue:deviceUUID.UUIDString];
            
            // Upload in background
            NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
            [progressQueue addOperationWithBlock:^{
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"Y-M-D H:mm:s"];
                
                int currentCounter = 0;
                
                BOOL uploadOK = 1;
                
                for (CMMotionActivity *activity in activities) {
                    if ((activity.confidence == CMMotionActivityConfidenceHigh)||(activity.confidence == CMMotionActivityConfidenceMedium)) {
                        // Extract a function return all possible activity
                        NSString *activityName;
                        if (activity.automotive) activityName = @"automotive";
                        else if (activity.cycling) activityName = @"cycling";
                        else if (activity.running) activityName = @"running";
                        else if (activity.walking) activityName = @"walking";
                        else if (activity.stationary) activityName = @"stationary";
                        else activityName = @"unknown";
                        
                        NSString *confidence;
                        
                        if (activity.confidence == CMMotionActivityConfidenceHigh) confidence = @"High";
                        else confidence = @"Medium";
                        
                        [newRequest setPostKey:@"startTime" withValue:[formatter stringFromDate:activity.startDate]];
                        [newRequest setPostKey:@"activityName" withValue:activityName];
                        [newRequest setPostKey:@"confidenceLevel" withValue:confidence];
                        
                        [newRequest prepareForPost];
                        
                        NSError *error;
                        NSData *returnData = [NSURLConnection sendSynchronousRequest:newRequest returningResponse:nil     error:&error];
                        if (returnData)
                        {
                            //                            NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
                            //                            NSLog(@"Resp string: %@",json);
                        }
                        else
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self addToLog:[NSString stringWithFormat:@"Error: %@", error]];
                            });
                            NSLog(@"Error: %@", error);
                            uploadOK = 0;
                            break;
                        }
                        
                        currentCounter++;
                    }
                    
                    
                    
                }
                
                if (uploadOK) {
                    [self updateLastUpdateDate:[NSDate date]];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self addToLog:[NSString stringWithFormat:@"Uploaded %d high confidence motion activities.", currentCounter]];
                    [activityView stopAnimating];
                });
                
            }];
        }
    }];
}

- (BOOL)sendDeviceActivityWithData:(NSMutableArray *)actualData dataTypeKey:(NSArray *)dataTypeKey deviceInfoData:(NSArray *)deviceInfoData deviceInfoKey:(NSArray *)deviceInfoKey newRequest:(NSMutableURLRequest *)newRequest
{
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:deviceInfoKey,deviceInfoData,dataTypeKey,actualData, nil]
                                                               forKeys:[NSArray arrayWithObjects:@"deviceInfoKey",@"deviceInfoData",@"dataTypeKey",@"dataTypeValue", nil]];
    
    NSError *error = nil;
    if ([NSJSONSerialization isValidJSONObject:jsonDictionary]){
        NSLog(@"Can be converted to JSON");
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
        
        [newRequest setHTTPMethod:@"POST"];
        [newRequest setHTTPBody:jsonData];
        [newRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Length"];
        
        NSData *returnData = [NSURLConnection sendSynchronousRequest:newRequest returningResponse:nil     error:&error];
        if (returnData)
        {
            NSString *json=[[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
            NSLog(@"Resp string: %@",json);
            
            if ([json hasSuffix:@"All success."]) {
                [self updateLastUpdateDate:[NSDate date]];
                return YES;
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addToLog:[NSString stringWithFormat:@"Error: %@", error]];
            });
            NSLog(@"Error: %@", error);
        }
    }
    else{
        NSLog(@"Cannot be converted to JSON");
    }
    return NO;
}

- (void)uploadMotionActivityJson
{
    NSDate *lastUpdateTime = [self getLastUpdateTime];
    
    
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc]     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.center=self.view.center;
    [activityView startAnimating];
    [self.view addSubview:activityView];
    
    [_motionActivitiyManager queryActivityStartingFromDate:lastUpdateTime toDate:[NSDate date] toQueue:[NSOperationQueue mainQueue] withHandler:^(NSArray *activities, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                            message:[error description]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return ;
        }
        if (error != nil && error.code == CMErrorMotionActivityNotAuthorized) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addToLog:@"The app isn't authorized to use motion activity support."];
                [activityView stopAnimating];
            });
        }
        else{
            NSString* fullAddress = [NSString stringWithFormat:@"http://%@/Direct/uploadActivityJson.php", self.ipAddress];
            
             NSMutableURLRequest *newRequest = [[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:fullAddress]cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
            
            // Upload in background
            NSOperationQueue *progressQueue = [[NSOperationQueue alloc] init];
            [progressQueue addOperationWithBlock:^{
                
                // Json: {dict:@"deviceInfoKey"{UUID},@"deviceInfoData"{xx-xx-xx}
                //              @"dataTypeKey"{startTime,activityName,confidenceLevel},@"actualData"{dataArray1,dataArray2..}}
                
                NSArray *deviceInfoKey = [NSArray arrayWithObjects:@"UUID", nil];
                NSArray *deviceInfoData = [NSArray arrayWithObjects: deviceUUID.UUIDString, nil];
                
                NSArray *dataTypeKey = [NSArray arrayWithObjects:@"startTime",@"activityName",@"confidenceLevel", nil];
                NSMutableArray *actualData = [[NSMutableArray alloc]init];
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"Y-M-d H:mm:s"];
                //        NSLog(@"%@",[formatter stringFromDate:[NSDate date]]);
                
                BOOL success = NO;
                
                int currentCounter = 0;
                int totalCounter = 0;
                NSDate *latestTimeStamp = [[NSDate alloc]initWithTimeIntervalSince1970:0];
                
                for (CMMotionActivity *activity in activities) {
                    if ((activity.confidence == CMMotionActivityConfidenceHigh)||(activity.confidence == CMMotionActivityConfidenceMedium)) {
                        // Extract a function return all possible activity
                        NSString *activityName;
                        if (activity.automotive) activityName = @"automotive";
                        else if (activity.cycling) activityName = @"cycling";
                        else if (activity.running) activityName = @"running";
                        else if (activity.walking) activityName = @"walking";
                        else if (activity.stationary) activityName = @"stationary";
                        else activityName = @"unknown";
                        
                        NSString *confidence;
                        
                        if (activity.confidence == CMMotionActivityConfidenceHigh) confidence = @"High";
                        else confidence = @"Medium";
                        
                        [actualData addObject:[NSArray arrayWithObjects:
                                               [formatter stringFromDate:activity.startDate],
                                               activityName,
                                               confidence,
                                               nil]];
                       latestTimeStamp = [latestTimeStamp laterDate:activity.startDate];
                        currentCounter++;
                        totalCounter++;
                        // Memory concern, 400 max a time
                        if (currentCounter > 400) {
                            success = [self sendDeviceActivityWithData:actualData dataTypeKey:dataTypeKey deviceInfoData:deviceInfoData deviceInfoKey:deviceInfoKey newRequest:newRequest];
                            
                            currentCounter = 0;
                            if (success) {
                                [actualData removeAllObjects];
                            }
                            else
                            {
                                break;
                            }
                        }
                    }
                }
                // upload remaining data < 200
                if (success) {
                    success = [self sendDeviceActivityWithData:actualData dataTypeKey:dataTypeKey deviceInfoData:deviceInfoData deviceInfoKey:deviceInfoKey newRequest:newRequest];
                }
                
                if (success) {
                    [self updateLastUpdateDate:[NSDate date]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addToLog:[NSString stringWithFormat:@"Uploaded %d high/medium confidence motion activities.", totalCounter]];
                        [activityView stopAnimating];
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addToLog:[NSString stringWithFormat:@"Failed to upload motion activities."]];
                        [activityView stopAnimating];
                    });
                }
                
                
            }];
        }
    }];
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     if ([[segue identifier] isEqualToString:@"showPersonalDetail"]) {
         PersonalDetailViewController *vc = [segue destinationViewController];
         vc.navigationItem.backBarButtonItem.enabled = false;
         vc.title = @"My Details";
     }
 }

@end
