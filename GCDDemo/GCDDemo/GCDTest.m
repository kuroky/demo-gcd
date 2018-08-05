//
//  GCDTest.m
//  GCDDemo
//
//  Created by kuroky on 2017/11/22.
//  Copyright © 2017年 kuro. All rights reserved.
//

#import "GCDTest.h"

@implementation GCDTest

+ (instancetype)sharedTest {
    static dispatch_once_t onceToken;
    static GCDTest *test;
    dispatch_once(&onceToken, ^{
        test = [GCDTest new];
    });
    return test;
}

//MARK:- 异步下载->主线程
- (void)gcdOnMainQueue:(void (^)(UIImage *image))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSURL *url = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage1.jpg"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [[UIImage alloc] initWithData:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(image);
        });
    });
}

//MARK:- 串行
- (void)testSerialQueue {
    /**
     运行结果
     [NSThread sleepForTimeInterval:6]
     [NSThread sleepForTimeInterval:3]
     [NSThread sleepForTimeInterval:1]
     */
    NSLog("testSerialQueue");
    NSDate *date = [NSDate date];
    NSString *daStr = [date description];
    const char *queuename = [daStr UTF8String];
    dispatch_queue_t myQueue = dispatch_queue_create(queuename, DISPATCH_QUEUE_SERIAL);
    dispatch_async(myQueue, ^{
        [NSThread sleepForTimeInterval:6];
        NSLog(@"[NSThread sleepForTimeInterval:6]");
    });
    
    dispatch_async(myQueue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"[NSThread sleepForTimeInterval:3]");
    });
    
    dispatch_async(myQueue, ^{
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[NSThread sleepForTimeInterval:1]");
    });
}

//MARK:- 并行
- (void)testConcurrentQueue {
    /**
     可以同时运行多个任务,每个任务的启动时间是按照加入queue的顺序，结束的顺序依赖各自的任务，使用dispatch_get_global_queue获得
     运行结果
     [NSThread sleepForTimeInterval:1]
     [NSThread sleepForTimeInterval:3]
     [NSThread sleepForTimeInterval:6]
     */
    dispatch_queue_t myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(myQueue, ^{
        [NSThread sleepForTimeInterval:6];
        NSLog(@"[NSThread sleepForTimeInterval:6]");
    });
    
    dispatch_async(myQueue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"[NSThread sleepForTimeInterval:3]");
    });
    
    dispatch_async(myQueue, ^{
        [NSThread sleepForTimeInterval:1];
        NSLog(@"[NSThread sleepForTimeInterval:1]");
    });
}

//MARK:- dispatch_group
- (void)testDispatchGroupWithBlock:(void (^)(id response))completion {
    dispatch_group_t serviceGroup = dispatch_group_create();
    __block BOOL configError = YES;
    dispatch_group_enter(serviceGroup);
    [self requestUsingBlock:^(NSError *error, id response) {
        configError = error ? YES : NO;
        dispatch_group_leave(serviceGroup);
    }];
    
    __block BOOL preferenceError = YES;
    // Start the second service
    dispatch_group_enter(serviceGroup);
    [self requestUsingBlock:^(NSError *error, id response) {
        preferenceError = error ? YES : NO;
        dispatch_group_leave(serviceGroup);
    }];
    
    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(),^{
        completion(@"finish");
    });
}

- (void)requestUsingBlock:(void (^)(NSError *error, id response))block {
    [NSThread sleepForTimeInterval:0.5];
    NSError *error = nil;
    id response = @[@1, @2];
    block(error, response);
}

#pragma mark Description
- (void)systemQueue {
    /**
     通过与线程池的配合，dispatch queue分为两种:系统默认串行队列main_queue和并行队列global_queue
     1.Serial Dispatch Queue  线程池只提供一个线程来执行任务，所以后一个任务必须等到前一个任务执行结束才能开始
     2.Concurrent Dispatch Queue 线程池提供多个线程来执行任务，所以可以按序启动多个任务并发执行
     
     而系统默认就有一个串行队列main_queue和并行队列global_queue
     */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQ = dispatch_get_main_queue();
#pragma clang diagnostic pop
    
    
    /**
     通常,我们可以在global_queue中做一些long-running的任务，完成后在main_queue中更新UI,避免UI阻塞,无法响应用户操作
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // long-running task
        dispatch_async(dispatch_get_main_queue(), ^{
            // update UI
        });
    });
}

- (void)createQueue {
    /**
     Serial queue(private dispatch queue)
     每次运行一个任务，可以添加多个，执行次序FIFO，通常是指程序员生成的，比如
     */
    NSDate *date = [NSDate date];
    NSString *daStr = [date description];
    const char *queueName = [daStr UTF8String];
    dispatch_queue_t myQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    dispatch_async(myQueue, ^{
        NSURL *url = [NSURL URLWithString:@"http://avatar.csdn.net/2/C/D/1_totogo2010.jpg"];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        UIImage *image = [[UIImage alloc] initWithData:data];
        if (data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"myQueue image: %@", image);
            });
        }
    });
}

#pragma mark 延时
- (void)testDelay
{
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // code to be executed on the main queue after delay
    });
}

@end
