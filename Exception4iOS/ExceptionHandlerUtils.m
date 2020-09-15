//
//  ExceptionHandlerUtils.m
//  Exception4iOS
//
//  Created by Toureek on 9/16/20.
//  Copyright © 2020 com.toureek.exception4iOS. All rights reserved.
//

#import "ExceptionHandlerUtils.h"
#include <stdatomic.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <SCLAlertView.h>
#import <UIKit/UIKit.h>

// Address argument to atomic operation must be a pointer to non-const _Atomic type
atomic_int kUncaughtExceptionCount = 0;
const static int32_t   kUncaughtExceptionMaxCount = 8;
const static NSInteger kUncaughtExceptionSkipedAddressCount = 4;
const static NSInteger kUncaughtExceptionReportedAddressCount = 5;

static NSString *const kUncaughtExceptionHandlerSignalExceptionName = @"kUncaughtExceptionHandlerSignalExceptionName";
static NSString *const kUncaughtExceptionHandlerSignalExceptionReason = @"kUncaughtExceptionHandlerSignalExceptionReason";
static NSString *const kUncaughtExceptionHandlerSignalKey = @"kUncaughtExceptionHandlerSignalKey";
static NSString *const kUncaughtExceptionHandlerAddressesKey = @"kUncaughtExceptionHandlerAddressesKey";
static NSString *const kUncaughtExceptionHandlerCallStackSymbolsKey = @"kUncaughtExceptionHandlerCallStackSymbolsKey";
static NSString *const kUncaughtExceptionHandlerFileKey = @"kUncaughtExceptionHandlerFileKey";


@implementation ExceptionHandlerUtils

+ (void)installGlobalUncaughtSignalExceptionHandler {
    NSSetUncaughtExceptionHandler(&GlobalExceptionHandler);
}

void GlobalExceptionHandler(NSException *exception) {
    NSLog(@"locate current crashing-point is %s", __func__);
    
    int32_t exceptionCount = atomic_fetch_add_explicit(&kUncaughtExceptionCount, 1, memory_order_relaxed);
    if (exceptionCount > kUncaughtExceptionMaxCount) {
        return;
    }
    
    NSArray *systemCallStackTraces = [ExceptionHandlerUtils fetchedSystemCallStackTraces];

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:exception.name forKey:kUncaughtExceptionHandlerSignalExceptionName];
    [userInfo setObject:exception.reason forKey:kUncaughtExceptionHandlerSignalExceptionReason];
    [userInfo setObject:systemCallStackTraces forKey:kUncaughtExceptionHandlerAddressesKey];
    [userInfo setObject:exception.callStackSymbols forKey:kUncaughtExceptionHandlerCallStackSymbolsKey];
    [userInfo setObject:@"CaughtExceptions" forKey:kUncaughtExceptionHandlerFileKey];
    
    NSException *exceptionInfo = [NSException exceptionWithName:exception.name reason:exception.reason userInfo:userInfo];
    ExceptionHandlerUtils *utils = [[ExceptionHandlerUtils alloc] init];
    [utils performSelectorOnMainThread:@selector(handleWithExceptionBasedOnRunLoop:) withObject:exceptionInfo waitUntilDone:YES];
}

- (void)handleWithExceptionBasedOnRunLoop:(NSException *)exception {
    // 在当前RunLoop接到系统信号，通知它退出时，立即 人工启动一个平行RunLoop,把即将退出的RunLoop中素有的modes, input sources, timer全部拿到
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFArrayRef allRunLoopModes  = CFRunLoopCopyAllModes(runloop);
    
    NSDictionary *userinfo = [exception userInfo];
    NSLog(@">>>>> %@", userinfo);
    
    // 保存异常信息 当即上传服务端 或 在下次冷启动的时候 上传服务器. 注意 这里不仅只记录crash 还要配合 统计+日志埋点
    [self saveExceptionCrashingDetail:exception file:[userinfo objectForKey:kUncaughtExceptionHandlerFileKey]];
    
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindowWidth:300.f];
    [alert addButton:@"点击退出应用" actionBlock:^{
        self.dismissed = YES;
    }];
    [alert showWarning:exception.name subTitle:exception.reason closeButtonTitle:nil duration:0.0f];

    // 保证App不会因为系统发来的信号让RunLoop退出， 持续hold一会
    while (!self.dismissed) {
        for (NSString *mode in (__bridge NSArray *)allRunLoopModes) {
            /**
             <__NSArrayM 0x6000031e2e20>(
             UITrackingRunLoopMode,
             GSEventReceiveRunLoopMode,
             kCFRunLoopDefaultMode,
             kCFRunLoopCommonModes
             )
             */
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    CFRelease(allRunLoopModes);
}


/// 获取函数堆栈信息
+ (NSArray *)fetchedSystemCallStackTraces {
    void* systemCall_Stack[128];
    
    // 用于获取当前线程的函数调用堆栈(栈帧数量)，返回实际获取的指针个数
    int stackFrames = backtrace(systemCall_Stack, 128);
    // backtrace函数获取的信息 转化为一个字符串数组 所以 (char *)(*strs)
    char **strs = backtrace_symbols(systemCall_Stack, stackFrames);
    
    int i;
    NSMutableArray *stackTraces = [NSMutableArray arrayWithCapacity:stackFrames];
    for (i = kUncaughtExceptionSkipedAddressCount;
         i < kUncaughtExceptionSkipedAddressCount+kUncaughtExceptionReportedAddressCount;
         i++) {
        [stackTraces addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);  // C语言的内存释放
    return stackTraces;
}

- (void)saveExceptionCrashingDetail:(NSException *)exception file:(NSString *)fileName {
    NSArray *stackArray = [[exception userInfo] objectForKey:kUncaughtExceptionHandlerCallStackSymbolsKey];
    NSString *reason = exception.reason ? : @"placerHolder_Reason";
    NSString *name = exception.name ? : @"placerHolder_Name";

    NSString * systemPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString * libPath  = [systemPath stringByAppendingPathComponent:fileName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDate *data = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timeInterval = [data timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%f", timeInterval];
    NSString *savedPath = [libPath stringByAppendingFormat:@"/error%@.log", timeString];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@", name, reason, stackArray];
    BOOL sucess = [exceptionInfo writeToFile:savedPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"保存崩溃日志 sucess:%d,%@", sucess, savedPath);
}


@end
