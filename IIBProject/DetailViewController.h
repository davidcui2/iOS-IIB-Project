//
//  DetailViewController.h
//  IIBProject
//
//  Created by Zhihao Cui on 14/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

