//
//  ChunkEvent.h
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import <Foundation/Foundation.h>

//轨道事件类
@interface ChunkEvent : NSObject

//1-轨道事件的delta-time
@property (nonatomic,assign)NSUInteger eventDeltaTime;

//2-事件状态码
@property (nonatomic,assign)NSUInteger eventStatus;

//3-事件数组
@property (nonatomic,strong)NSMutableArray *eventArray;

//4-事件总长度
@property (nonatomic,assign)NSUInteger eventLength;

@end
