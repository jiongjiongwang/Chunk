//
//  MTRKChunk.m
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "MTRKChunk.h"

@implementation MTRKChunk

-(instancetype)initWithMIDIData:(NSData *)midiData andChunkLength:(NSUInteger)chunkLength and:(NSUInteger)location
{
    if (self == [super init])
    {
        
        _chunkLength = chunkLength;
        
        _location = location;
        
        //根据传入的MIDI文件总data和当前轨道快在data中的长度和位置来提取相关信息
        
        
    }
    return self;
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"当前轨道快的长度是%ld,在MIDI文件中的位置是%ld",self.chunkLength,self.location];
}



@end
