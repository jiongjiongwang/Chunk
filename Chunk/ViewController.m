//
//  ViewController.m
//  Chunk
//
//  Created by dn210 on 16/10/14.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "ViewController.h"
#import "ChunkHeader.h"
#import "MTRKChunk.h"



#warning 放到PCH文件中，给整个项目使用
#define kFilePath "/Users/dn210/Desktop/0GAROTADE.mid"


@interface ViewController ()

@property (nonatomic,strong)ChunkHeader *chunkHead;

//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
@property (nonatomic,strong)NSArray<MTRKChunk *> *mtrkArray;


//一个MIDI文件在内存中只存在一个NSData对象
@property (nonatomic,strong)NSData *midiData;

//播放音乐的Sampler对象
@property (nonatomic,strong)MIDISampler *sampler;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _chunkHead = [ChunkHeader sharedChunkHeaderFrom:kFilePath];
    
    //1-初始化
    _sampler = [[MIDISampler alloc] init];
    
    [self CaculateMIDINum];
    
}

//求出当前MIDI文件的总delta-time总数
-(void)CaculateMIDINum
{
    
    //记录一下每个4分音符的时长(不断变化的)
    NSUInteger quartTime = 500000;
    
    //用一个数记录一下MIDI文件的最终时长
    float allMIDITime = 0;
    
    //遍历MIDI事件中的轨道
    for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
    {
        
#warning 即时计算
        //即时统计当前轨道中的delta-time
        NSUInteger allChunkDeltaTime = 0;
        
        //即时计算当前轨道的时间
        float theTime = 0.00000000;
        
        
        
        //遍历轨道中的事件(遍历每一个事件)
        //在当前这个轨道中
        for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
        {
            ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
            
            allChunkDeltaTime += chunkEvent.eventDeltaTime;

            
            //即时的时长
            theTime += (float)((float)chunkEvent.eventDeltaTime/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100;
            
            NSLog(@"事件%ld的delta-Time是%ld,即时的4分音符的时长是%ld,即时的总delta-time是%ld,即时的时间是%f",j,chunkEvent.eventDeltaTime,quartTime,allChunkDeltaTime,theTime);
            
            
            
            //出现5103事件时，4分音符时长发生变化
            if ([chunkEvent isKindOfClass:[FF5103ChunkEvent class]])
            {
                
                //4分音符的时长更新
                quartTime = [[chunkEvent valueForKey:@"theQuartTime"] integerValue];
            }
                
                //播放音乐?(一个事件一个事件地播放音乐)
            //[self PlaySoundWithChunkEvent:chunkEvent];
            
        }
        
        
        NSLog(@"当前轨道块%ld的事件总数是%ld,总时长是%f",i,self.mtrkArray[i].chunkEventArray.count,theTime);

        //NSLog(@"当前轨道块%ld的事件数组是%@",i,self.mtrkArray[i].chunkEventArray);
        
        
        
        if (_chunkHead.chunkType == 0)
        {
            allMIDITime = theTime;
        }
        else if(_chunkHead.chunkType == 1)
        {
            if (allMIDITime <= theTime)
            {
               allMIDITime = theTime;
            }
        }
        else
        {
            allMIDITime += theTime;
        }
    }
    
    NSLog(@"当前MIDI文件的总时长是%f",allMIDITime);
    
}


//封装播放音乐的方法(传入一个事件)
-(void)PlaySoundWithChunkEvent:(ChunkEvent *)chunkEvent
{
    //播放音乐?(一个事件一个事件地播放音乐)
    //不播放FF和F0开头事件的音乐
    if (chunkEvent.eventStatus.length <= 2)
    {
        
        //1-事件数组的起始位置
        NSUInteger location;
        
        //2-事件数组的长度
        NSUInteger length;
        
        //判断是不是缺失事件
        if (chunkEvent.isUnFormal)
        {
            location = chunkEvent.location + chunkEvent.deltaTimeLength;
            
            length = chunkEvent.eventLength - chunkEvent.deltaTimeLength + 1;
        }
        else
        {
            location = chunkEvent.location + chunkEvent.deltaTimeLength + 1;
            
            length = chunkEvent.eventLength - chunkEvent.deltaTimeLength;
        }
        
        
        [self sendMIDIMsgWithStatus:chunkEvent.eventStatus
                   andEventLocation:location
                             Length:length];
        
        
    }
}


//播放方法
//1-参数1:事件状态码(NSString)
//2-参数2:当前事件的事件码在NSData中的位置
- (void) sendMIDIMsgWithStatus:(NSString *)dataStr andEventLocation:(NSUInteger)location  Length:(NSUInteger)size
{
    
    Byte statusData = strtoul([dataStr UTF8String],0,16);
   
    [self.midiData enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
       
        
        if (size == 3)
        {
            [_sampler MIDIShortMsg:statusData withData1:((uint8_t*)bytes)[location] withData2:((uint8_t*)bytes)[location + 1]];
        }
        else if (size == 2)
        {
            [_sampler MIDIShortMsg:statusData withData1:((uint8_t*)bytes)[location] withData2:0];
        }
        
    }];
}



-(NSData *)midiData
{
    if (_midiData == nil)
    {
        _midiData = [NSData dataWithContentsOfFile:@kFilePath];
    }
    
    return _midiData;
}



//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
-(NSArray<MTRKChunk *> *)mtrkArray
{
    if (_mtrkArray == nil)
    {
        
        if (self.midiData.length <= 23)
        {
            NSLog(@"当前的MIDI文件不完全");
            
            return nil;
        }
        
        //当前轨道块的长度(NSString）
        NSMutableString *mtrkLength = [NSMutableString string];
        //当前轨道的长度(NSUInteger)
        __block NSUInteger length = 0;
        
        //每一个轨道块的长度值起始
        __block NSUInteger lengthStart = 18;
        
        //可变数组
        NSMutableArray<MTRKChunk *> *mMtrkArray = [NSMutableArray array];
        
        [self.midiData enumerateByteRangesUsingBlock:^(const void *bytes,
                                                       NSRange byteRange,
                                                       BOOL *stop) {
            
            //判断MIDI文件
            for (NSUInteger i = 0; i < byteRange.length; ++i)
            {
                
                //转换成NSString来判断值(也可以不转)
                NSString *tempString = [NSString stringWithFormat:@"%02x",((uint8_t*)bytes)[i]];
                
                //轨道块的长度提取
                if (i>=lengthStart + length && i<=lengthStart + 3 + length)
                {
                    [mtrkLength appendString:tempString];
                }
                
                if (i == lengthStart + 4 + length)
                {
                    length = strtoul([mtrkLength UTF8String],0,16);
                    
                    if (length != 0)
                    {
                        lengthStart = i + 4;
                    }
                    
                    //清空轨道快的长度
                    [mtrkLength deleteCharactersInRange:NSMakeRange(0, mtrkLength.length)];
                    
                    //初始化轨道块
                    MTRKChunk *mtrkChunk = [[MTRKChunk alloc] initWithMIDIData:self.midiData andChunkLength:length and:i];
                    
                    [mMtrkArray addObject:mtrkChunk];
                }
                
            }
        }];
        
        _mtrkArray = mMtrkArray.copy;
    }
    
    return _mtrkArray;
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
