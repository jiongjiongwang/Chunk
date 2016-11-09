//
//  PlayAndPauseMusic.h
//  Chunk
//
//  Created by 王炯 on 16/11/8.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayAndPauseMusic : NSOperation

@property (nonatomic,copy)NSString *playStr;

//BOOL:播放/暂停音乐
@property (nonatomic,assign)BOOL play;



@end
