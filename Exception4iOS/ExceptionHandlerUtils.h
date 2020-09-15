//
//  ExceptionHandlerUtils.h
//  Exception4iOS
//
//  Created by Toureek on 9/16/20.
//  Copyright © 2020 com.toureek.exception4iOS. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExceptionHandlerUtils : NSObject

@property (nonatomic, assign) BOOL dismissed;

+ (void)installGlobalUncaughtSignalExceptionHandler;

@end

NS_ASSUME_NONNULL_END
