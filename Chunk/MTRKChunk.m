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
    if (self = [super init])
    {
        
        _chunkLength = chunkLength;
        
        _location = location;
        
        //根据传入的MIDI文件总data和当前轨道快在data中的长度和位置来设置轨道事件数组
      _chunkEventArray = [self setUpChunkEventArrayWithData:midiData andChunkLength:chunkLength and:location].copy;
        
        
    }
    return self;
}

//根据传入的MIDI文件总data和当前轨道快在data中的长度和位置来设置轨道事件数组
-(NSMutableArray<ChunkEvent *> *)setUpChunkEventArrayWithData:(NSData *)midiData andChunkLength:(NSUInteger)chunkLength and:(NSUInteger)location
{
    
    //1-判断传入的data总长度是否合理
    if (midiData.length < chunkLength + 22)
    {
        NSLog(@"当前轨道长度不合法");
        
        return nil;
    }
    
    //2-声明一个可变的数组
    //可变数组
    NSMutableArray<ChunkEvent *> *mChunkArray = [NSMutableArray array];
    
    //3-根据长度和起始值来遍历data
    [midiData enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
       
#warning 具体某一种事件的索引
#warning 1-FF事件
        //记录一下FF事件所在的索引
        NSUInteger indexFF = 0;
        
        //FF之后的数字索引(01-09)
        NSUInteger numIndex = 0;
        
        //FF之后的5事件索引
        NSUInteger ff5Index = 0;
        
        //FF之后的2F事件索引
        NSUInteger ff2fIndex = 0;
        
        //FF之后是00事件时
        NSUInteger ff00Index = 0;
        
        //FF之后的21事件
        NSUInteger ff21Index = 0;
        
        //FF事件保存一下FF事件的后续状态码
        NSString *ffStatus;
        
#warning 2-F0事件
        //记录一下F0事件所在的索引
        NSUInteger indexF0 = 0;
        
#warning 3-正常事件
        //记录一下正常事件的状态码(NSString)
        NSString *formalStatus;
        
#warning 每一个事件在总的data中的位置和长度(创建一个事件变量所需要的必要元素)
        //记录一下事件总长度
        NSUInteger eventLength = 0;
        
        //记录一下每一个事件的开始位置(初始为location)
        NSUInteger eventLocation = location;
        
        
        //记录一下每一个事件delta-time的位数(初始化为1位)
        NSUInteger eventDeltaNum = 1;
        
        //从内部提取出长度信息
        NSUInteger length = 0;
        
        //判断MIDI文件
        for (NSUInteger i = location; i < location + chunkLength; ++i)
        {
            //转换成NSString来判断值(也可以不转)
            NSString *tempString = [NSString stringWithFormat:@"%02x",((uint8_t*)bytes)[i]];
            
            
            
#warning 0-判断事件delta-time的位数,待封装代码
            //判断delta-time是否超过了80
            //1-delta-time第一位是否超过80时
            if (eventDeltaNum == 1&& i - eventLocation == 0)
            {
                //如果第一位超过了80
                if ((((uint8_t*)bytes)[i] & 0x80) == 0x80)
                {
                    //delta-time位数加一(至少两位delta-time)
                    eventDeltaNum = 2;
                    //继续验证下一个delta-time而不会继续向下再走了
                    continue;
                }
                else
                {
                    //只有一位delta-time时候
                    continue;
                }
            }
            //2-delta-time第二位是否超过80时
            if (eventDeltaNum == 2 && i - eventLocation == 1)
            {
                //如果第二位超过了80
                if ((((uint8_t*)bytes)[i] & 0x80) == 0x80)
                {
                    //delta-time位数再加一(至少3位delta-time)
                    eventDeltaNum = 3;
                    //继续验证下一个delta-time而不会继续向下再走了
                    continue;
                }
                else
                {
                    //只有两位delta-time的时候
                    continue;
                }
            }
            //3-delta-time第三位是否超过80时
            if (eventDeltaNum == 3 && i - eventLocation == 2)
            {
                //如果第三位超过了80
                if ((((uint8_t*)bytes)[i] & 0x80) == 0x80)
                {
                    //delta-time位数再加一(4位delta-time)
                    eventDeltaNum = 4;
                    //继续验证下一个delta-time而不会继续向下再走了
                    continue;
                }
                else
                {
                    //只有三位delta-time的时候
                    continue;
                }
            }
            
            
#warning 1-判断，当碰到FF事件时
            if ([tempString isEqualToString:@"ff"])
            {
                indexFF = i;
            }
            
            //判断ff的下一个状态码是什么
            if (i == indexFF + 1 && indexFF != 0)
            {
                //1-判断FF的下一个字符是不是在01到09之间的数
                if ((((uint8_t*)bytes)[i] >= 0x01 && ((uint8_t*)bytes)[i] <= 0x09) || ((uint8_t*)bytes)[i] == 0x7F)
                {
                    //记录一下当前的索引，用于提取出事件之后的长度
                    numIndex = i;
                }
                
                //2-判断FF的下一个字符是不是51，54，58，59
                if (((((uint8_t*)bytes)[i] >>4) ^0x05) == 0x00)
                {
                    ff5Index = i;
                }
                
                //3-判断FF的下一个字符是不是2F
                if (((uint8_t*)bytes)[i] == 0x2F)
                {
                    ff2fIndex = i;
                }
                
                //4-判断FF的下一个字符是不是00
                if (((uint8_t*)bytes)[i] == 0x00)
                {
                    ff00Index = i;
                }
                
                //5-判断FF的下一个字符是不是21
                if (((uint8_t*)bytes)[i] == 0x21)
                {
                    ff21Index = i;
                }
                
                ffStatus = [NSString stringWithFormat:@"FF %@",tempString];
                
                continue;
            }
            
            //当是数字状态码时，获取长度值
            if (i == numIndex + 1 && numIndex != 0)
            {
                
                //1-判断此时的长度字符是否超过7F
                if ((((uint8_t*)bytes)[i] & 0x80) == 0x80)
                {
                    #warning 判断字符长度是否超过了7F(127)
                    NSLog(@"FF之后的数字长度超出了7F(127)");
                }
                
                //提取出长度信息
                length = strtoul([tempString UTF8String],0,16);
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 3;
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:ffStatus andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
#warning 代码重复，待封装
                //数据恢复
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //4-delta-time位数
                eventDeltaNum = 1;
                
                continue;
            }
            
            //2-当是F5事件时
            if (i == ff5Index + 1 && ff5Index != 0)
            {
                
                if ((((uint8_t*)bytes)[i] ^ 0x03) == 0x00)
                {
                    length = 3;
                    
                    //碰到了5103事件了
                    _FF5103Num ++;
                }
                else if((((uint8_t*)bytes)[i] ^ 0x05) == 0x00)
                {
                    length = 5;
                }
                else if ((((uint8_t*)bytes)[i] ^ 0x04) == 0x00)
                {
                    length = 4;
                }
                else if((((uint8_t*)bytes)[i] ^ 0x02) == 0x00)
                {
                    length = 2;
                }
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 3;
                
                
                    [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:ffStatus andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
                
                
                
                //数据更新
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //3-delta-time位数
                eventDeltaNum = 1;
                
                continue;
            }
            //3-当是2F事件时
            if (i == ff2fIndex + 1 && ff2fIndex != 0)
            {
                length = 1;
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 2;
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:ffStatus andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
                //不需要数据更新
                continue;
            }
            
            //4-当是FF 00事件时
            if (i == ff00Index + 1 && ff00Index != 0)
            {
                //(1)当此时的字符是02时
                if (((uint8_t*)bytes)[i] == 0x02)
                {
                    length = 2;
                }
                //2-当此时的字符是00时
                else if(((uint8_t*)bytes)[i] == 0x00)
                {
                    length = 0;
                }
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 3;
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:ffStatus andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
                //数据恢复
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //4-delta-time位数
                eventDeltaNum = 1;
                
                continue;
            }
            
            //5-当是FF21事件时
            if (i == ff21Index + 1 && ff21Index != 0)
            {
                length = 2;
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 2;
                
                
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:ffStatus andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
                
                
                
                
                //数据恢复
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //4-delta-time位数
                eventDeltaNum = 1;
                
                continue;
                
            }
#warning 2-判断，当遇到F0事件时，
            if ([tempString isEqualToString:@"f0"])
            {
                indexF0 = i;
            }
 
            //判断f0的下一个状态码是什么(f0事件的长度)
            if (i == indexF0 + 1 && indexF0 != 0)
            {
                
                //1-判断此时的长度字符是否超过7F
                if ((((uint8_t*)bytes)[i] & 0x80) == 0x80)
                {
#warning 判断字符长度是否超过了7F(127)
                    NSLog(@"F0之后的数字长度超出了7F(127)");
                }
                
                //提取出长度信息
                length = strtoul([tempString UTF8String],0,16);
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 2;
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:@"F0F7" andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
                //数据恢复
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //4-delta-time位数
                eventDeltaNum = 1;
                
                continue;
            }
            
            
#warning 3-判断，当遇到一个正常事件时
            if ((((uint8_t*)bytes)[i] & 0x80) == 0x80 &&
                (((uint8_t*)bytes)[i] & 0xF0) != 0xF0)
            {
                
                //求出长度信息(0x0C和0x0D特例)
                length = 2;
                
                if ((((uint8_t*)bytes)[i] >>4) == 0x0C ||
                    (((uint8_t*)bytes)[i] >>4) == 0x0D)
                {
                    length = 1;
                }
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 1;
                
                //保存一下当前的事件状态码
                formalStatus = [NSString stringWithFormat:@"%@",tempString];
                
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:tempString andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:NO];
                
                //数据恢复
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //4-delta-time位数
                eventDeltaNum = 1;
                
                continue;
            }
            
#warning 4-判断缺失事件
            if ((((uint8_t*)bytes)[i] & 0x80) == 0x00 &&
                i != indexFF + 1)
            {
               // NSLog(@"缺失事件");
                //根据上一个事件的状态码来判断长度length
                length = 1;
                
                NSUInteger statusNum = strtoul([formalStatus UTF8String],0,16);
                //Cx和Dx之间
                if (statusNum >= 192 && statusNum <= 223)
                {
                    length = 0;
                }
                
                //更新事件总长度
                eventLength = length + eventDeltaNum + 1;
                
                
                //根据所得到的信息来创建一个事件变量
                [self SetUpChunkEventArrayWithMIDIData:midiData andDeltaNum:eventDeltaNum andEventStatus:formalStatus andEventLength:eventLength andEventLocation:eventLocation withmArray:mChunkArray andIsUnformal:YES];
                
                //数据恢复
                //1-location
                eventLocation = eventLocation + eventLength;
                
                //2-i跨length个字节，无视其中的数据
                i += length;
                
                //3-事件总长度
                eventLength = 0;
                
                //4-delta-time位数
                eventDeltaNum = 1;
                
                continue;
            }
            
        }
    }];
    
    
    return mChunkArray;
}

//根据所得到的信息来创建一个事件变量
-(void)SetUpChunkEventArrayWithMIDIData:(NSData *)midiData
                        andDeltaNum:(NSUInteger)deltaNum
                     andEventStatus:(NSString *)eventStatus
                     andEventLength:(NSUInteger)eventLength
                   andEventLocation:(NSUInteger)location
                             withmArray:(NSMutableArray *)mChunkArray
                             andIsUnformal:(BOOL)isUnformal
{
    
    ChunkEvent *chunkEvent;
    
    //判断是不是5103事件
    if ([eventStatus isEqualToString:@"FF 51"])
    {
    
        chunkEvent = [[FF5103ChunkEvent alloc] initWithMIDIData:midiData andDeltaNum:deltaNum andEventStatus:eventStatus andEventLength:eventLength andEventLocation:location andIsUnformal:isUnformal];
    }
    else
    {
        chunkEvent = [[ChunkEvent alloc] initWithMIDIData:midiData andDeltaNum:deltaNum andEventStatus:eventStatus andEventLength:eventLength andEventLocation:location andIsUnformal:isUnformal];
    }
    
    
    [mChunkArray addObject:chunkEvent];
}



-(NSString *)description
{
    return [NSString stringWithFormat:@"当前轨道快的长度是%ld,在MIDI文件中的位置是%ld,轨道中5103事件的数量是%ld",self.chunkLength,self.location,self.FF5103Num];
}



@end
