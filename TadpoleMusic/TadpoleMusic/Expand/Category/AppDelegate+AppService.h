//
//  AppDelegate+AppService.h
//  TadpoleMusic
//
//  Created by zhangzb on 2017/8/9.
//  Copyright © 2017年 zhangzb. All rights reserved.
//  启动第三方SDK的服务，系统配置，网络监测

#import "AppDelegate.h"

@interface AppDelegate (AppService)
/**
 *  网络监测
 */
- (void)startNetworkMonitoring;
/**
 *  Bug收集
 */
- (void)startBugly;


/**
 第一次启动
 */
-(void)firstStart;

@end
