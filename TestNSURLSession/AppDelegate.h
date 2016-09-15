//
//  AppDelegate.h
//  TestNSURLSession
//
//  Created by Bolu on 16/7/9.
//  Copyright © 2016年 Bolu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^block)();

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) block backgroundURLSessionCompletionHandler;


@end

