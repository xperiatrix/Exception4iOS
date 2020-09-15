//
//  ViewController.m
//  Exception4iOS
//
//  Created by Toureek on 9/16/20.
//  Copyright © 2020 com.toureek.exception4iOS. All rights reserved.
//

#import "ViewController.h"

/**
 严格的说：这是基于信号捕获异常的解决方案，crash的捕获类型并不全面(只能捕获KVO Notification 数组越界 野指针访问等异常)
         还要有基于OOM，启动超时，后台任务超时，主线程卡顿超阈值等异常引起的crash 有待完善
 */

@interface ViewController ()

@end

@implementation ViewController {
    NSArray *_tempArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    
   _tempArray = @[@"1", @"2", @"3", @"4"];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSLog(@"%@", _tempArray[5]);
    
    NSObject *a = [[NSObject alloc] init];
    [a performSelector:@selector(run)];
}


@end
