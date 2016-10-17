//
//  ChunkHeader.m
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "ChunkHeader.h"

@implementation ChunkHeader


+(instancetype)sharedChunkHeaderFrom:(char *)fileLocation
{
    static ChunkHeader *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[ChunkHeader alloc] init];
        
        
        FILE *fp;
        
        unsigned char ch;
        
        int index = 0;
        
        if ((fp = fopen(fileLocation, "rb")) == NULL)
        {
            NSLog(@"cannot open file 0GAROTADE.mid");
            
            return;
        }
        
        ch = fgetc(fp);
        
        while (!feof(fp))
        {
            index ++;
            
            if (index == 15)
            {
                break;
            }
            else if (index == 10)
            {
                instance.chunkType = ch;
            }
            else if(index == 11)
            {
                instance.chunkNum = ch;
            }
            else if(index == 12)
            {
                instance.chunkNum <<= 8;
                
                instance.chunkNum |= ch;
            }
            else if(index == 13)
            {
                instance.tickNum = ch;
            }
            else if(index == 14)
            {
                instance.tickNum <<= 8;
                
                instance.tickNum |= ch;
            }
            
            //ch的值发生改变
            ch=fgetc(fp);
        }
        
        fclose(fp);
    
    });
    
    return instance;
}





@end
