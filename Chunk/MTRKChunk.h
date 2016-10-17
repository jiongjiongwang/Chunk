//
//  MTRKChunk.h
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//
//轨道块类
#import <Foundation/Foundation.h>
#import "ChunkEvent.h"


@interface MTRKChunk : NSObject

//1-轨道块长度(单位:字节)
@property (nonatomic,assign)NSUInteger chunkLength;


//2-当前轨道块的轨道事件数组
@property (nonatomic,strong)NSMutableArray<ChunkEvent *> *chunkEventArray;


//初始化构造方法，利用1-轨道块长度和2-当前轨道块在全局data中的位置(不包含头和长度)初始化
-(instancetype)initWithChunkLength:(NSUInteger)chunkLength and:(NSUInteger)location;



@end
