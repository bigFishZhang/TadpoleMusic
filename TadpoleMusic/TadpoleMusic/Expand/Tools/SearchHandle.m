//
//  SearchHandle.m
//  TadpoleMusic
//
//  Created by zhangzb on 2017/8/14.
//  Copyright © 2017年 zhangzb. All rights reserved.
//

#import "SearchHandle.h"
#import "SearchModel.h"
@interface SearchHandle()
/** 搜索数据*/


@end
@implementation SearchHandle
#pragma mark - **************** 懒加载

#pragma mark - **************** 搜索部分
/**
 在百度里面搜索歌曲
 
 @param songName 歌曲名字
 */
+(NSMutableDictionary *)searchMusicInBD:(NSString *)songName{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    //判断Url中是否有特殊符号（ - 排除干扰
    NSMutableArray *stringArray =[[NSMutableArray alloc]init];
    if ([songName containsString:@"("]) {
        [stringArray addObjectsFromArray:[songName componentsSeparatedByString:@"("]];
    }
    if ([songName containsString:@"-"]) {
        [stringArray addObjectsFromArray:[songName componentsSeparatedByString:@"-"]];
    }
    //确认正确的url
    NSString *url= [NSString stringWithFormat:@"http://www.baidu.com/s?wd=%@",songName];
    if (stringArray.count!=0) {
        url= [NSString stringWithFormat:@"http://www.baidu.com/s?wd=%@",stringArray[0]];
    }
    
    //获取网页HTML
    NSURL *xcfURL = [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSError *error = nil;
    NSString *htmlString = [NSString stringWithContentsOfURL:xcfURL encoding:NSUTF8StringEncoding error:&error];
    if (htmlString==nil||htmlString.length==0) {
        NSLog(@"没有搜索出歌曲");
        return result;
    }
    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];

    #pragma mark - **************** 抓取平台名称
    OCQueryObject *musicPlatformElement = document.Query(@"body").find(@".c-tabs-nav-view").find(@".c-tabs-nav-li");
    #pragma mark - **************** 抓取专辑封面
    
    OCGumboNode *songImageGumboNode = document.Query(@"body").find(@".op-musicsong-img").first();
    
    #pragma mark - **************** 抓取歌曲URL
    OCQueryObject *getElement = document.Query(@"body").find(@".c-icon-play-circle");
    OCQueryObject *songUrlElement = document.Query(@"body").find(@"#content_left").find(@".result-op").find(@".c-tabs-content");
    //准备返回的封面图
    NSString * imageUrl = @"-";
    if (songImageGumboNode != nil && songImageGumboNode.attr(@"src") !=nil &&songImageGumboNode.attr(@"src").length !=0) {
        imageUrl = songImageGumboNode.attr(@"src");
    }else{
        //尝试另外一种获取方式
         OCQueryObject *songImageGumboNode = document.Query(@"body").find(@".op-bk-polysemy-album");
        if (songImageGumboNode.count != 0 ) {
            OCGumboNode * imgNode = songImageGumboNode.find(@".c-img").first();
            if (imgNode!=nil) {
                imageUrl = imgNode.attr(@"src");
            }
        }else{//关键词搜索
            OCGumboNode *songImageGumboNode = document.Query(@"body").find(@".op-music-lrc-r-img").first();
            if (songImageGumboNode != nil && songImageGumboNode.attr(@"src") !=nil &&songImageGumboNode.attr(@"src").length !=0) {
                imageUrl = songImageGumboNode.attr(@"src");
            }
        }
    }
    
    [result setValue:imageUrl forKey:@"songImageUrl"];
    #pragma mark - **************** 准备返回数据
    if ((unsigned long)musicPlatformElement.count>0&&(unsigned long)songUrlElement.count>0&&(unsigned long)musicPlatformElement.count==(unsigned long)songUrlElement.count) {//搜取的歌曲必须平台数大于1
        //
        //歌曲封面
        NSMutableArray *tmpArr = [NSMutableArray array];
        for ( int i=0; i<musicPlatformElement.count; i++) {
            NSDictionary * tmpMusic = [NSMutableDictionary dictionary];
            OCGumboElement *elePlatform = musicPlatformElement[i];
            OCGumboElement *eleSong = songUrlElement[i];
            NSString * platform = @"-";
            NSString * songUrl = @"-";
            NSString * artist = @"-";
            //平台名称
            platform = elePlatform.text();
            //歌曲URL
            if ((unsigned long)getElement.count>0 && songUrlElement.count>0) {//情况1
                    OCGumboNode *firstSong =eleSong.Query(@".c-icon-play-circle").first();
                    OCQueryObject *songArtist =eleSong.Query(@".c-gray");
                    if (firstSong != nil) {
                       songUrl =  firstSong.attr(@"href");
                    }
                    if (songArtist != nil&&songArtist.count>1) {
                        OCGumboNode *artistNode =songArtist[1];
                        if (artistNode!=nil) {
                             artist =  artistNode.text();
                             artist= [artist stringByReplacingOccurrencesOfString:@" " withString:@""];
                             artist= [artist stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                            artist= [artist stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                        }
                        
                    }

            }else{//尝试第二种搜索
                    OCGumboNode *firstSong =eleSong.Query(@".op-musicsong-songname").first();
                    if (firstSong != nil) {
                        songUrl =  firstSong.attr(@"href");
                      
                    }
                   OCGumboNode *songArtist = document.Query(@".c-musicsong-singer").first();
                  if (songArtist != nil) {
                      artist =  songArtist.text();
                      artist= [artist stringByReplacingOccurrencesOfString:@" " withString:@""];
                      artist= [artist stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                      artist= [artist stringByReplacingOccurrencesOfString:@"\t" withString:@""];
                  }
            }
 
            

            [tmpMusic setValue:platform forKey:@"musicPlatform"];
            [tmpMusic setValue:artist forKey:@"artist"];
            [tmpMusic setValue:songUrl  forKey:@"songUrl"];
            SearchModel *oneModel = [[SearchModel alloc]initWithDict:tmpMusic];
            [tmpArr addObject:oneModel];
            
        }
        [result setObject:tmpArr forKey:@"musicPlatform"];
    }else{
        OCGumboNode *songImageGumboNode = document.Query(@"body").find(@".op-music-lrc-r-songname").first();
        
        NSString * songUrl = @"-";
        NSString * platform = @"-";
        NSString * artist = @"-";
        NSMutableArray *tmpArr = [NSMutableArray array];
        NSDictionary * tmpMusic = [NSMutableDictionary dictionary];
        if (songImageGumboNode != nil && songImageGumboNode.attr(@"href") !=nil &&songImageGumboNode.attr(@"href").length !=0) {
            songUrl = songImageGumboNode.attr(@"href");
            NSString *songName =songImageGumboNode.text();
           
            [tmpMusic setValue:platform forKey:@"musicPlatform"];
            [tmpMusic setValue:songUrl  forKey:@"songUrl"];
            
            if (songName!=nil) {
                 [result setValue:songName forKey:@"songName"];
            }
            OCGumboNode *songArtist = document.Query(@".c-music-lrc-r-singer").first();
            if (songArtist != nil) {
                artist =  songArtist.text();
                artist= [artist stringByReplacingOccurrencesOfString:@" " withString:@""];
                artist= [artist stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                artist= [artist stringByReplacingOccurrencesOfString:@"\t" withString:@""];
            }
            [tmpMusic setValue:artist forKey:@"artist"];
            SearchModel *oneModel = [[SearchModel alloc]initWithDict:tmpMusic];
            [tmpArr addObject:oneModel];
            [result setObject:tmpArr forKey:@"musicPlatform"];
        }
        
        
    }
    
    return result;
}

#pragma mark - url 中文格式化
+ (NSString *)strUTF8Encoding:(NSString *)str
{
    return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];

}

@end
