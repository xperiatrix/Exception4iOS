//
//  AppDelegate.m
//  Exception4iOS
//
//  Created by Toureek on 9/16/20.
//  Copyright © 2020 com.toureek.exception4iOS. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "ExceptionHandlerUtils.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [ExceptionHandlerUtils installGlobalUncaughtSignalExceptionHandler];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    ViewController *singlePage = [[ViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:singlePage];
    self.window.rootViewController = navi;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
