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
#define kFilePath "/Users/dn210/Desktop/马勒1-4.mid"


@interface ViewController ()

@property (nonatomic,strong)ChunkHeader *chunkHead;

//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
@property (nonatomic,strong)NSArray<MTRKChunk *> *mtrkArray;


//一个MIDI文件在内存中只存在一个NSData对象
@property (nonatomic,strong)NSData *midiData;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _chunkHead = [ChunkHeader sharedChunkHeaderFrom:kFilePath];
    
    //轨道块总数(一次获取完成之后无需再次加载，其值固定不变)
    NSLog(@"轨道块总数为%ld",(long)_chunkHead.chunkNum);
    
    //四分音符节奏数(一次获取完成之后无需再次加载，其值固定不变)
    NSLog(@"四分音符节奏数为%ld",(long)_chunkHead.tickNum);
    
    //轨道类型
    NSLog(@"四分音符轨道类型类型为%ld",_chunkHead.chunkType);
    
    
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
        //当前轨道中每一个分界点的delta-time数(以5103为分界点,直到轨道结束)
        NSUInteger chunkDeltaTime = 0;
        
        //当前轨道的时长
        float chunkTime = 0.00000000;
        
        
        NSLog(@"轨道块%ld,事件总数是%ld",i,self.mtrkArray[i].chunkEventArray.count);
        
        
        
        //遍历轨道中的事件(遍历每一个事件)
        //在当前这个轨道中
        for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
        {
            ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
            //添加每一个事件的delta-time
            chunkDeltaTime += chunkEvent.eventDeltaTime;
            
            
            
            
            //出现5103事件时，4分音符时长发生变化
            if ([chunkEvent isKindOfClass:[FF5103ChunkEvent class]])
            {
                
                //4分音符时长(BPM)
                //NSUInteger theBPM = 60000000 / quartTime;
                
                //NSLog(@"5103出现,在MIDI的%ld位置,当前的总时长是%f,即时BPM为%ld,原值为%ld,当前5103事件的delta-time是%ld",chunkEvent.location,chunkTime,theBPM,quartTime,chunkEvent.eventDeltaTime);
                
                
                //计算4分节奏数
                //4分节奏数(delta-time总数/四分音符节奏数)
                float quartNum = (float)chunkDeltaTime/(float)_chunkHead.tickNum;
                
                //即时计算时长
                chunkTime += quartNum * quartTime *0.001 * 0.001;
                
                
                //chunkDeltaTime此时清零,进行下一波计算
                chunkDeltaTime = 0;
                
                //4分音符的时长更新
                quartTime = [[chunkEvent valueForKey:@"theQuartTime"] integerValue];
                
            }
            
           
        }
        
        
        //到当前循环结束时，在同一计算当前轨道的总时长
        //计算4分节奏数
        //4分节奏数(delta-time总数/四分音符节奏数)
        float quartNum = (float)chunkDeltaTime/(float)_chunkHead.tickNum;
        
        //即时计算时长
        chunkTime += quartNum * quartTime *0.001 * 0.001;
        
        
        
        NSLog(@"轨道块%ld的总时长是%f",i,chunkTime);
        
        if (_chunkHead.chunkType == 0)
        {
            allMIDITime = chunkTime;
        }
        else if(_chunkHead.chunkType == 1)
        {
            if (allMIDITime <= chunkTime)
            {
               allMIDITime = chunkTime;
            }
        }
        else
        {
            allMIDITime += chunkTime;
        }
    }
    
    NSLog(@"当前MIDI文件的总时长是%f",allMIDITime);
    
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
