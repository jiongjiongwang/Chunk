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
@property (nonatomic,copy)NSString *eventStatus;

//3-事件数组
@property (nonatomic,strong)NSMutableArray *eventArray;

//4-事件总长度
@property (nonatomic,assign)NSUInteger eventLength;

//5-当前轨道快在总的MIDI文件中的位置
@property (nonatomic,assign)NSUInteger location;


//初始化方法:传入事件的1-delta-time位数，2-事件的状态码，3-事件总长度和4-总的data,5当前轨道块在总data中的位置
-(instancetype)initWithMIDIData:(NSData *)midiData
                    andDeltaNum:(NSUInteger)deltaNum
                 andEventStatus:(NSString *)eventStatus
                 andEventLength:(NSUInteger)eventLength
               andEventLocation:(NSUInteger)location;



@end
