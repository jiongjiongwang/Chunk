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

//外界传入的属性
//1-轨道事件的delta-time位数
@property (nonatomic,assign)NSUInteger deltaTimeLength;


//2-事件状态码
@property (nonatomic,copy)NSString *eventStatus;

//3-事件总长度
@property (nonatomic,assign)NSUInteger eventLength;

//4-当前事件在总的MIDI文件中的位置
@property (nonatomic,assign)NSUInteger location;


//5-判断当前的事件是不是缺失事件
@property (nonatomic,assign)BOOL isUnFormal;


//计算得到的属性
//6-轨道事件的delta-time
@property (nonatomic,assign)NSUInteger eventDeltaTime;


//外界计算得到的属性
//7-当前的事件在整个播放过程中的播放时间(开始时间)
@property (nonatomic,assign)float eventPlayTime;

//8-当前的事件的即时delta-time
@property (nonatomic,assign)NSUInteger eventAllDeltaTime;


//9-事件音符号(只统计8，9，A开头的事件)
@property (nonatomic,copy)NSString *midiCode;

//10-事件速度(只统计8，9，A开头的事件)
@property (nonatomic,copy)NSString *midiSpeed;

//11-钢琴从按下去到释放的持续时间(只统计9开头的事件)
@property (nonatomic,assign)float eventDuration;


//初始化方法:传入事件的1-delta-time位数，2-事件的状态码，3-事件总长度和4-总的data,5当前轨道块在总data中的位置
-(instancetype)initWithMIDIData:(NSData *)midiData
                    andDeltaNum:(NSUInteger)deltaNum
                 andEventStatus:(NSString *)eventStatus
                 andEventLength:(NSUInteger)eventLength
               andEventLocation:(NSUInteger)location
                  andIsUnformal:(BOOL)isUnFormal;



@end
