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
{
    if (self = [super init])
    {
        _eventLength = eventLength;
        
        _eventStatus = eventStatus;
        
        _location = location;
    }
    return self;
}


-(NSString *)description
{
    
    return [NSString stringWithFormat:@"当前事件状态码是%@,事件长度是%ld,事件位置在%ld",self.eventStatus,self.eventLength,self.location];
}



@end
