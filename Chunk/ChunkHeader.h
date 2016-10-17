//
//  ChunkHeader.h
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

//轨道头类
#import <Foundation/Foundation.h>

//轨道类型枚举
typedef enum : NSUInteger {
    chunkTypeSigle = 0,
    chunkTypeMultiSync,
    chunkTypeMultiAsync,
} kChunkType;

@interface ChunkHeader : NSObject

//1-轨道类型
@property (nonatomic,assign)kChunkType chunkType;

//2-轨道块总数
@property (nonatomic,assign)NSUInteger chunkNum;

//3-4分音符节奏数
@property (nonatomic,assign)NSUInteger tickNum;

//一个MIDI文件，轨道头只有一个，使用单例模式
+(instancetype)sharedChunkHeaderFrom:(char *)fileLocation;



@end
