//
//  ViewController.m
//  TestNSURLSession
//
//  Created by Bolu on 16/7/9.
//  Copyright © 2016年 Bolu. All rights reserved.
//

#import "ViewController.h"
#import "TestViewController.h"

@interface ViewController ()
{
    UIWebView *_webView;
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //初始化一个webView
//    _webView = [[UIWebView alloc] initWithFrame:self.view.frame];
//    [self.view addSubview:_webView];
    
    //测试请求网页数据
//    [self testSessionDataTask];
    
    //测试下载图片
    [self testSessionDownLoadTask];
    
//    TestViewController *testVC = [[TestViewController alloc] init];
//    testVC.view.frame = self.view.frame;
//    [self.view addSubview:testVC.view];
    
//    NSLog(@"当前路径--%@",[self getDocumentsPath]);
}

- (void)testSessionDataTask {
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://blog.csdn.net/bolu1234"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [_webView loadData:data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
    }];
    [dataTask resume];
}

- (void)testSessionDownLoadTask {
    NSURL *URL = [NSURL URLWithString:@"http://b.hiphotos.baidu.com/image/w%3D2048/sign=6be5fc5f718da9774e2f812b8469f919/8b13632762d0f703b0faaab00afa513d2697c515.jpg"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                            completionHandler:
                                              ^(NSURL *location, NSURLResponse *response, NSError *error) {
                                                  
                                                  // 输出下载文件原来的存放目录
                                                  NSLog(@"location---%@", location);
                                                  
                                                  // 设置文件的存放目标路径
                                                  NSString *documentsPath = [self getDocumentsPath];
                                                  NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:documentsPath];
                                                  //[[response URL] lastPathComponent]为下载图片的文件名
                                                  NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[[response URL] lastPathComponent]];
                                                  
                                                  // 如果该路径下文件已经存在，就要先将其移除，在移动文件
                                                  NSFileManager *fileManager = [NSFileManager defaultManager];
                                                  if ([fileManager fileExistsAtPath:[fileURL path] isDirectory:NULL]) {
                                                      [fileManager removeItemAtURL:fileURL error:NULL];
                                                  }
                                                  [fileManager moveItemAtURL:location toURL:fileURL error:NULL];
                                                  
                                                  // 在webView中加载图片文件
                                                  NSURLRequest *showImage_request = [NSURLRequest requestWithURL:fileURL];
                                                  [_webView loadRequest:showImage_request];
                                                  
                                              }];
    
    [downloadTask resume];
}

/* 获取Documents文件夹的路径 */
- (NSString *)getDocumentsPath {
    NSArray *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = documents[0];
    return documentsPath;
}

@end
