//
//  IIBPostRequest.h
//  IIBProject
//
//  Created by Zhihao Cui on 25/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IIBPostRequest : NSMutableURLRequest

@property NSString *postContent;
@property NSMutableDictionary *postDictionary;

- (id)initWithURLString:(NSString *)urlString;

- (void)setPostKey:(NSString *)postKey withValue:(NSString *)postValue;

- (void)prepareForPost;

@end
