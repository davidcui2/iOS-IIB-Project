//
//  IIBPostRequest.m
//  IIBProject
//
//  Created by Zhihao Cui on 25/01/2015.
//  Copyright (c) 2015 Zhihao Cui. All rights reserved.
//

#import "IIBPostRequest.h"

@implementation IIBPostRequest

@synthesize postContent = _postContent;
@synthesize postDictionary = _postDictionary;

- (id)initWithURLString:(NSString *)urlString
{
    _postDictionary = [[NSMutableDictionary alloc]init];
    _postContent = [[NSString alloc]init];
    return [super initWithURL:[NSURL URLWithString:urlString]];
}

- (void)setPostKey:(NSString *)postKey withValue:(NSString *)postValue
{
    [_postDictionary setObject:postValue forKey:postKey];
}

-(void)prepareForPost
{
    for (NSString* key in _postDictionary) {
        _postContent = [_postContent stringByAppendingString:[NSString stringWithFormat:@"%@=%@&",key,[_postDictionary objectForKey:key]]];
    }
    NSData *postData = [_postContent dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [self setHTTPMethod:@"POST"];
    [self setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self setHTTPBody:postData];
}

@end
