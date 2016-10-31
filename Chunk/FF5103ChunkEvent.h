//
//  FF5103ChunkEvent.h
//  Chunk
//
//  Created by dn210 on 16/10/19.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "ChunkEvent.h"

@interface FF5103ChunkEvent : ChunkEvent

//5103事件之后的值(4分音符的时长)
@property (nonatomic,assign)NSUInteger theQuartTime;


@end
