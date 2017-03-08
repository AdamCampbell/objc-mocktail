//
//  MocktailResponse.m
//  Mocktail
//
//  Created by Matthias Plappert on 3/11/13.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "MocktailResponse.h"


@interface MocktailResponse()

@property (nonatomic, strong) NSRegularExpression *methodRegex;
@property (nonatomic, strong) NSRegularExpression *absoluteURLRegex;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) NSInteger bodyOffset;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic) NSInteger statusCode;

@end


@implementation MocktailResponse

+ (MocktailResponse *)mocktailResponseForFileAtURL:(NSURL *)url {
    NSAssert(url, @"Expected valid URL.");

    NSError *error;
    NSStringEncoding originalEncoding;
    NSString *contentsOfFile = [NSString stringWithContentsOfURL:url usedEncoding:&originalEncoding error:&error];
    if (error) {
        NSLog(@"Error opening %@: %@", url, error);
        return nil;
    }

    NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
    NSString *headerMatter = nil;
    [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
    NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
    if ([lines count] < 4) {
        NSLog(@"Invalid amount of lines: %u", (unsigned)[lines count]);
        return nil;
    }

    MocktailResponse *response = [MocktailResponse new];
    response.methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
    response.absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
    response.statusCode = [lines[2] integerValue];
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    for (NSString *line in [lines subarrayWithRange:NSMakeRange(3, lines.count - 3)]) {
        NSArray* parts = [line componentsSeparatedByString:@":"];
        [headers setObject:[[parts lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                    forKey:[parts firstObject]];
    }
    response.headers = headers;
    response.fileURL = url;
    response.bodyOffset = [headerMatter dataUsingEncoding:originalEncoding].length + 2;
    return response;
}

@end
