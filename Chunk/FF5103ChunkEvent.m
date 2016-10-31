//
//  FF5103ChunkEvent.m
//  Chunk
//
//  Created by dn210 on 16/10/19.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "FF5103ChunkEvent.h"

@implementation FF5103ChunkEvent

//重写父类的init方法，在原有的init方法基础上添加计算4分音符时长的方法
-(instancetype)initWithMIDIData:(NSData *)midiData andDeltaNum:(NSUInteger)deltaNum andEventStatus:(NSString *)eventStatus andEventLength:(NSUInteger)eventLength andEventLocation:(NSUInteger)location andIsUnformal:(BOOL)isUnFormal
{
    if (self = [super initWithMIDIData:midiData andDeltaNum:deltaNum andEventStatus:eventStatus andEventLength:eventLength andEventLocation:location andIsUnformal:isUnFormal])
    {
        
        //添加计算4分音符时长的方法
        _theQuartTime = [self CaculateTheQuartTimeWithMidiData:midiData andEventLocation:location andDeltaNum:deltaNum];
    }
    return self;
}

//计算4分音符时长
-(NSUInteger)CaculateTheQuartTimeWithMidiData:(NSData *)midiData andEventLocation:(NSUInteger)location andDeltaNum:(NSUInteger)deltaNum
{
    __block NSUInteger theQuartTime = 0;
    
    [midiData enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
       
        for (NSUInteger i = location + deltaNum + 3; i <= location + deltaNum + 5; ++i)
        {
            NSString *tempString = [NSString stringWithFormat:@"%02x",((uint8_t*)bytes)[i]];
            
            NSUInteger theTempNum = strtoul([tempString UTF8String],0,16);
            
            theQuartTime += theTempNum << 8*(location + deltaNum + 5 - i);
            
        }
        
    }];
    
    
    return theQuartTime;
}


@end
