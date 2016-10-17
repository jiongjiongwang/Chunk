//
//  MTRKChunk.m
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "MTRKChunk.h"

@implementation MTRKChunk

-(instancetype)initWithChunkLength:(NSUInteger)chunkLength and:(NSUInteger)location
{
    if (self == [super init])
    {
        
        _chunkLength = chunkLength;
        
    }
    return self;
}

@end
