//
//  PlayAndPauseMusic.m
//  Chunk
//
//  Created by 王炯 on 16/11/8.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "PlayAndPauseMusic.h"

@implementation PlayAndPauseMusic



-(void)main
{
    
    int index = 0;
    
    //直到这首歌歌曲播放结束
    while (index < 10000)
    {
        
        if (_play)
        {
            NSLog(@"%d:当前线程为%@----->%@",index,[NSThread currentThread],self.playStr);
            
            [NSThread sleepForTimeInterval:0.2];
            
            index ++;
        }
    }
}




@end
