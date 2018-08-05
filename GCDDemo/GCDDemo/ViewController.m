//
//  ViewController.m
//  GCDDemo
//
//  Created by kuro on 13-6-3.
//  Copyright (c) 2013年 kuro. All rights reserved.
//

#import "ViewController.h"
#import "GCDTest.h"

typedef void(^RequestBlock)(NSError *error, id response);
typedef void(^Completion)(NSError *error, id response);

static dispatch_semaphore_t _lock;
static NSString *const kViewControllerCellId    =   @"viewControllerCellId";

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSArray *dataList;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupData];
    [self setupUI];
    //[self testDispatch_barrier_async];
}

- (void)setupData {
    _lock = dispatch_semaphore_create(1); // 创建信号源
    self.dataList = @[@"主线程", @"串行", @"并行", @"group", @""];
}

- (void)setupUI {
    self.tableView.rowHeight = 50.0;
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kViewControllerCellId];
}

#pragma mark dispatch_barrier_async
- (void)testDispatch_barrier_async {
    /**
     dispatch_barrier_async是在前面的任务执行结束后它才执行,而且它后面的任务等它执行完成之后才会执行
     运行结果
     dispatch_async2
     dispatch_async1
     dispatch_barrier_async
     dispatch_async3
     */
    //dispatch_queue_t queue = dispatch_queue_create("gcdtest.rongfzh.yc", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:3];
        NSLog(@"dispatch_async1");
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:1.5];
        NSLog(@"dispatch_async2");
    });
    dispatch_barrier_async(queue, ^{
        [NSThread sleepForTimeInterval:0.5];
        NSLog(@"dispatch_barrier_async");
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:1];
        NSLog(@"dispatch_async3");
    });
    
    /** 
     如果使用dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
     运行结果
      dispatch_barrier_async
      dispatch_async3
      dispatch_async2
      dispatch_async1
     */
    
    /**
     dispatch_barrier_async的顺序执行还是依赖queue的类型，必需要queue的类型为dispatch_queue_create创建的，而且attr的参数值必需是DISPATCH_QUEUE_CONCURRENT类型，前面两个非dispatch_barrier_async的类型的执行是依赖其本身的执行时间的，如果attr是DISPATCH_QUEUE_SERIAL时，那就完全符合Serial queue的FIFO特征
     */
}

#pragma mark set_target_queue
- (void)testTargetQueue {
    dispatch_queue_t globalQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQ = dispatch_get_main_queue();
    dispatch_set_target_queue(mainQ, globalQ);
}

//MARK:- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kViewControllerCellId
                                                            forIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.text = self.dataList[indexPath.row];
    return cell;
}

//MARK:- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *str = self.dataList[indexPath.row];
    if ([str isEqualToString:@"主线程"]) {
        [[GCDTest sharedTest] gcdOnMainQueue:^(UIImage *image) {
            NSLog(@"image download: %@", image);
        }];
    }
    else if ([str isEqualToString:@"串行"]) {
        [[GCDTest sharedTest] testSerialQueue];
    }
    else if ([str isEqualToString:@"并行"]) {
        [[GCDTest sharedTest] testConcurrentQueue];
    }
    else if ([str isEqualToString:@"group"]) {
        [[GCDTest sharedTest] testDispatchGroupWithBlock:^(id response) {
            NSLog(@"group finish");
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
