//
//  GCDTest.h
//  GCDDemo
//
//  Created by kuroky on 2017/11/22.
//  Copyright © 2017年 kuro. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDTest : NSObject

+ (instancetype)sharedTest;

/**
 异步下载，完成后通知主线程

 @param completion block
 */
- (void)gcdOnMainQueue:(void (^)(UIImage *image))completion;

/**
 串行
 */
- (void)testSerialQueue;

/**
 并行
 */
- (void)testConcurrentQueue;

- (void)testDispatchGroupWithBlock:(void (^)(id response))completion;

@end
