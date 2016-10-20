//
//  ChunkEvent.m
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "ChunkEvent.h"

@implementation ChunkEvent


-(instancetype)initWithMIDIData:(NSData *)midiData
                    andDeltaNum:(NSUInteger)deltaNum
                 andEventStatus:(NSString *)eventStatus
                 andEventLength:(NSUInteger)eventLength
               andEventLocation:(NSUInteger)location
                  andIsUnformal:(BOOL)isUnFormal
{
    if (self = [super init])
    {
        _eventLength = eventLength;
        
        _eventStatus = eventStatus;
        
        _location = location;
        
        _deltaTimeLength = deltaNum;
        
        //判断当前的事件是不是缺失事件
        _isUnFormal = isUnFormal;
        
        //根据以上的外界属性来得出事件的delta-time
        _eventDeltaTime = [self GetDeltaTimeWithMidiData:midiData andDeltaNum:deltaNum andEventLocation:location];
        
    }
    return self;
}


//根据以上的外界属性来得出事件的delta-time
-(NSUInteger)GetDeltaTimeWithMidiData:(NSData *)midiData
                          andDeltaNum:(NSUInteger)deltaNum
                     andEventLocation:(NSUInteger)location
{

    //初始化为0
    __block NSUInteger deltaTime = 0;
    
    //根据delta-time的位数和delta-time所在的data位置
    [midiData enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
       
        if (deltaNum == 1)
        {
            deltaTime = ((uint8_t*)bytes)[location];
        }
        else if (deltaNum == 2)
        {
            deltaTime = changeReadVarLen(((uint8_t*)bytes)[location], ((uint8_t*)bytes)[location + 1], 0, 0);
        }
        else if (deltaNum == 3)
        {
            deltaTime = changeReadVarLen(((uint8_t*)bytes)[location], ((uint8_t*)bytes)[location + 1], ((uint8_t*)bytes)[location + 2], 0);
        }
        else if (deltaNum == 4)
        {
            deltaTime = changeReadVarLen(((uint8_t*)bytes)[location], ((uint8_t*)bytes)[location + 1], ((uint8_t*)bytes)[location + 2], ((uint8_t*)bytes)[location + 3]);
        }
        
    }];
    
    return deltaTime;
}

//delta-time的转换
unsigned long changeReadVarLen(unsigned long firstValue,unsigned long secondValue,unsigned long thirdValue,unsigned long fourthValue)
{
    unsigned long value;
    
    if (firstValue & 0x80)
    {
        //delata-time的第一个字节(与0x7F相与)
        firstValue &= 0x7F;
        
        value = (firstValue << 7) + (secondValue & 0x7F);
        
        
        if(secondValue & 0x80)
        {
            value = (value << 7) + (thirdValue & 0x7F);
        }
        
        if (thirdValue & 0x80)
        {
            value = (value << 7) + (fourthValue & 0x7F);
        }
        
    }
    
    return value;
}




-(NSString *)description
{
    
    return [NSString stringWithFormat:@"当前事件状态码是%@,事件长度是%ld,事件位置在%ld,当前事件的delta-time位数是%ld,当前事件的delta-time是%ld,当前事件是缺失事件%d",self.eventStatus,self.eventLength,self.location,self.deltaTimeLength,self.eventDeltaTime,self.isUnFormal];
}



@end
