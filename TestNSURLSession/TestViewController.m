//
//  TestViewController.m
//  TestNSURLSession
//
//  Created by Bolu on 16/7/10.
//  Copyright © 2016年 Bolu. All rights reserved.
//

#import "TestViewController.h"
#import "AppDelegate.h"

@interface TestViewController () <NSURLSessionDownloadDelegate>

/* NSURLSessions */
@property (strong, nonatomic) NSURLSession *currentSession;    // 当前会话
@property (strong, nonatomic) NSURLSession *backgroundSession; // 后台会话

/* 下载任务 */
@property (strong, nonatomic) NSURLSessionDownloadTask *cancellableTask; // 可取消的下载任务
@property (strong, nonatomic) NSURLSessionDownloadTask *resumableTask;   // 可恢复的下载任务
@property (strong, nonatomic) NSURLSessionDownloadTask *backgroundTask;  // 后台的下载任务

/* 用于可恢复的下载任务的数据 */
@property (strong, nonatomic) NSData *partialData;

/* 显示已经下载的图片 */
@property (strong, nonatomic) UIImageView *downloadedImageView;

@end

@implementation TestViewController

#define kImageUrl @"http://img2.pconline.com.cn/pconline/0706/19/1038447_34.jpg"
#define kBackgroundSessionID @"BackgroundSessionID"

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.downloadedImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.downloadedImageView];
    
    //断点下载
    [self createResumableDownloadTask];     //开始下载
    [NSThread sleepForTimeInterval:0.1];
    [self pauseDownloadTask];               //暂停下载
    [NSThread sleepForTimeInterval:1];
    [self createResumableDownloadTask];     //继续下载

    //后台下载，点击home键后再回来没有调用application handleEventsForBackgroundURLSession，此次未实现
//    [NSThread sleepForTimeInterval:2];
//    [self createBackgroundDownloadTask];
}

#pragma mark - 后台下载

/* 创建一个后台session单例 */
- (NSURLSession *)createBackgroundSession {
    static NSURLSession *backgroundSess = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionID];
        backgroundSess = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    
    return backgroundSess;
}

- (void)createBackgroundDownloadTask {
    
    self.backgroundSession = [self createBackgroundSession];
    
    NSString *imageURLStr = kImageUrl;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLStr]];
    self.backgroundTask = [self.backgroundSession downloadTaskWithRequest:request];
    
    [self.backgroundTask resume];
}

#pragma mark - 断点下载

// 创建可恢复的下载任务
- (void)createResumableDownloadTask {
    if (!self.resumableTask) {
        if (!self.currentSession) {
            [self createCurrentSession];
        }
        
        if (self.partialData) { // 如果是之前被暂停的任务，就从已经保存的数据恢复下载
            self.resumableTask = [self.currentSession downloadTaskWithResumeData:self.partialData];
        }
        else { // 否则创建下载任务
            NSString *imageURLStr = kImageUrl;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLStr]];
            self.resumableTask = [self.currentSession downloadTaskWithRequest:request];
        }
        
        [self.resumableTask resume];
    }
}

- (void)createCurrentSession {
    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.currentSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:nil];
}

//暂停下载任务
- (void)pauseDownloadTask
{
    if (self.resumableTask) {
        [self.resumableTask cancelByProducingResumeData:^(NSData *resumeData) {
            // 如果是可恢复的下载任务，应该先将数据保存到partialData中，注意在这里不要调用cancel方法
            self.partialData = resumeData;
            self.resumableTask = nil;
        }];  
    }
}

#pragma mark - NSURLSessionDownloadDelegate

/* 从fileOffset位移处恢复下载任务 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"NSURLSessionDownloadDelegate: Resume download at %lld", fileOffset);
}

//该方法只有下载成功才被调用
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL*)location
{
    NSLog(@"didFinishDownloadingToURL--%@",location);
    
    if ([session.configuration.identifier isEqualToString:kBackgroundSessionID]) {
        self.backgroundTask = nil;
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        if (appDelegate.backgroundURLSessionCompletionHandler) {
            // 执行回调代码块
            void (^handler)() = appDelegate.backgroundURLSessionCompletionHandler;
            appDelegate.backgroundURLSessionCompletionHandler = nil;
            handler();
        }  
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadedImageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];

    });
}

/* 完成下载任务，无论下载成功还是失败都调用该方法 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"NSURLSessionDownloadDelegate: Complete task");
    
    if (error) {
        NSLog(@"下载失败：%@", error);
    }
}

/* 执行下载任务时有数据写入 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten // 每次写入的data字节数
 totalBytesWritten:(int64_t)totalBytesWritten // 当前一共写入的data字节数
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite // 期望收到的所有data字节数
{
    NSLog(@"bytesWritten--%lld",bytesWritten);
//    NSLog(@"totalBytesWritten--%lld",totalBytesWritten);
//    self.downloadedImageView.image = [UIImage imageWithData:downloadTask.response.URL];
    //没有实现图片逐步显示的效果，即断点续传，可参照AFNetwork
}

@end
