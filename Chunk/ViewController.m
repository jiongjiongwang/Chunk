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
#import "Masonry.h"
#import "FF5103ChunkEvent.h"


#warning 放到PCH文件中，给整个项目使用
#define kFilePath "/Users/dn210/Desktop/马勒1-4.mid"


@interface ViewController ()

@property (nonatomic,strong)ChunkHeader *chunkHead;

//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
@property (nonatomic,strong)NSArray<MTRKChunk *> *mtrkArray;


//一个MIDI文件在内存中只存在一个NSData对象
@property (nonatomic,strong)NSData *midiData;

//播放音乐的Sampler对象
@property (nonatomic,strong)MIDISampler *sampler;

//定时器label
@property (nonatomic,weak)UILabel *timeLabel;

//设置定时器
@property (nonatomic,strong)NSTimer *timer;

//定义一个全局属性记录一下当前MIDI的总时间
@property (nonatomic,assign)float midiAllTime;

//定义一个数组记录一下MIDI文件中所有5103事件的数组
@property (nonatomic,strong)NSArray<FF5103ChunkEvent *> *ff5103Array;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpUI];
    
    _chunkHead = [ChunkHeader sharedChunkHeaderFrom:kFilePath];
    
    //1-初始化
    _sampler = [[MIDISampler alloc] init];
    
    //设置定时器
    //_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(labelUpdate) userInfo:nil repeats:YES];
    
    //求出总时间并更新一下每一个事件的播放时间
    [self CaculateMIDINum];
    
    //播放音乐
    //[self PlayTheMIDI];
}

//设置界面布局
-(void)setUpUI
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    //1-定时器label
    UILabel *timeLabel = [[UILabel alloc] init];
    
    self.timeLabel = timeLabel;
    
    [self.view addSubview:timeLabel];
    
    timeLabel.text = @"0";
    
    //label居中
    [timeLabel setTextAlignment:NSTextAlignmentCenter];
    //label字体
    [timeLabel setFont:[UIFont systemFontOfSize:15]];
    //字体自适应
    [timeLabel sizeToFit];
    
    //设置约束
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.centerX.equalTo(self.view.mas_centerX);
        
        make.centerY.equalTo(self.view.mas_centerY);
    }];
    
}

//定时器方法
-(void)labelUpdate
{
    //1-取label上的数字
    NSInteger num = [self.timeLabel.text integerValue];
    
    num ++;
    
    self.timeLabel.text = [NSString stringWithFormat:@"%ld",(long)num];
    
}

//定时器销毁
-(void)dealloc
{
    [self.timer invalidate];
}


//求出当前MIDI文件的总delta-time总数
-(void)CaculateMIDINum
{
    
    //记录一下每个4分音符的时长(不断变化的)
    NSUInteger quartTime;
    
    //用一个数记录一下MIDI文件的最终时长
    float allMIDITime = 0;
    
    
    
    //遍历MIDI事件中的轨道
    for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
    {
        
        //即时统计当前轨道中的delta-time
        NSUInteger allChunkDeltaTime = 0;
        
        //即时计算当前轨道的时间
        float theTime = 0.00000000;
        
        
        //遍历轨道中的事件(遍历每一个事件)
        //在当前这个轨道中
        for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
        {
            ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
            
            //即时的总delta-time
            allChunkDeltaTime += chunkEvent.eventDeltaTime;
            
            //更新属性值:即时的总delta-time
            //chunkEvent.eventAllDeltaTime = allChunkDeltaTime;
            
            //传入即时的总delta-time来计算获取即时的4分音符时长
            quartTime = [self GetQuartTimeWithDeltaTime:allChunkDeltaTime];

            
            
            
            //当前事件的时长
            float theChunkEventTime = 0.00000000;
            
            theChunkEventTime = (float)((float)chunkEvent.eventDeltaTime/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100;
            
            //即时的总时长
            theTime += theChunkEventTime;
            
            //即时的总时长赋值给事件
            chunkEvent.eventPlayTime = theTime;
            
            
            
            
            /*
            if (i == 1)
            {
                 //NSLog(@"轨道%ld事件%ld的状态码是%@,事件的当前的delta-time是%ld,事件的即时总delta-time是%ld,事件的当前时间是%f,即时的总时间是%f",i,j,chunkEvent.eventStatus,chunkEvent.eventDeltaTime,allChunkDeltaTime,theChunkEventTime,theTime);
                
                NSLog(@"轨道%ld事件%ld的状态码是%@,事件的当前的delta-time是%ld,事件的即时总delta-time是%ld",i,j,chunkEvent.eventStatus,chunkEvent.eventDeltaTime,allChunkDeltaTime);
            }
            */
            
            
            
            //出现5103事件时，4分音符时长发生变化
            /*
            if ([chunkEvent isKindOfClass:[FF5103ChunkEvent class]])
            {
                
                //4分音符的时长更新
                quartTime = [[chunkEvent valueForKey:@"theQuartTime"] integerValue];
                
                //NSLog(@"轨道变速:轨道%ld事件%ld的状态码是%@,事件的当前的delta-time是%ld,事件的即时总delta-time是%ld,事件的当前时间是%f,%f秒之后的4分音符的时长是%ld",i,j,chunkEvent.eventStatus,chunkEvent.eventDeltaTime,allChunkDeltaTime,theChunkEventTime,theTime,quartTime);
                
                //NSLog(@"轨道变速:轨道%ld事件%ld的状态码是%@,事件的当前的delta-time是%ld,delta-time:%ld之后的4分音符的时长是%ld",i,j,chunkEvent.eventStatus,chunkEvent.eventDeltaTime,allChunkDeltaTime,quartTime);
                
            }
            */
        }
        
        
        
        NSLog(@"当前轨道块%ld其事件总数是%ld,总时长是%f",i,self.mtrkArray[i].chunkEventArray.count,theTime);

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
    
    _midiAllTime = allMIDITime;
    
}

-(NSArray<FF5103ChunkEvent *> *)ff5103Array
{
    if (_ff5103Array == nil)
    {
        
        NSMutableArray<FF5103ChunkEvent *> *ff51mArray = [NSMutableArray array];
        
        //遍历MIDI事件中的轨道
        for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
        {
            
            //即时统计当前轨道中的delta-time
            NSUInteger allChunkDeltaTime = 0;
            
            
            //遍历轨道中的事件(遍历每一个事件)
            //在当前这个轨道中
            for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
            {
                ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                
                //即时的总delta-time
                allChunkDeltaTime += chunkEvent.eventDeltaTime;
                
                //出现5103事件时，4分音符时长发生变化
                if ([chunkEvent isKindOfClass:[FF5103ChunkEvent class]])
                {
                    //更新属性值:即时的总delta-time
                    chunkEvent.eventAllDeltaTime = allChunkDeltaTime;
                    
                    //NSLog(@"delta-time:%ld之后的4分音符的时长是%ld",allChunkDeltaTime,[[chunkEvent valueForKey:@"theQuartTime"] integerValue]);
                    
                    
                    [ff51mArray addObject:(FF5103ChunkEvent *)chunkEvent];
                }
            }
        }
        
        _ff5103Array = ff51mArray.copy;
        
    }
    
    return _ff5103Array;
}



//传入即时的总delta-time来计算获取即时的4分音符时长
-(NSUInteger)GetQuartTimeWithDeltaTime:(NSUInteger)allChunkDeltaTime
{
    //记录一下每个4分音符的时长(不断变化的)
    NSUInteger quartTime = 0;
    
    
    //判断是否大于1
    if (self.ff5103Array.count > 1)
    {
        if (allChunkDeltaTime <= self.ff5103Array[self.ff5103Array.count - 1].eventAllDeltaTime)
        {
            for (NSUInteger i = 0; i < self.ff5103Array.count -1; i++)
            {
                if (allChunkDeltaTime > self.ff5103Array[i].eventAllDeltaTime && allChunkDeltaTime <= self.ff5103Array[i+1].eventAllDeltaTime)
                {
                    quartTime = [self.ff5103Array[i].theQuartTime integerValue];
                    
                    break;
                }
            }
        }
        else
        {
            quartTime = [self.ff5103Array[self.ff5103Array.count -1].theQuartTime integerValue];
        }
    }
    else
    {
        if (allChunkDeltaTime > self.ff5103Array[0].eventAllDeltaTime)
        {
            quartTime = [self.ff5103Array[0].theQuartTime integerValue];
        }
    }
    
    
    return quartTime;
}



//播放MIDI文件
-(void)PlayTheMIDI
{
    NSLog(@"当前MIDI文件的轨道数:%ld",_chunkHead.chunkNum);
    
    
    //用一个数来得到最小的值
    float lowEventTime = 0.0000000000;
    
    //记录一下前一个得到的最小值
    float preLowEventTime;
    
    //总共的时间数
    int allTimeNum = 0;
    
    //定义一个数组来记录一下每一轨道的索引信息
    NSUInteger chunkIndex[_chunkHead.chunkNum];
    
    
    memset(chunkIndex, 0, sizeof(chunkIndex));
    
    
    
    NSMutableArray *mEventArray;
    
    allTimeNum ++;
    
    mEventArray = [self GetEventArrayWithTime:lowEventTime andIndexArray:chunkIndex];
    
    //NSLog(@"0时间的事件数组是%@",mEventArray);
    
    
    //播放0时间数组的事件
    [self PlaySoundWithArray:mEventArray andDelayTime:0.000000];
    preLowEventTime = lowEventTime;
    
    //当小于总时间时，一直循环
    while (lowEventTime < _midiAllTime)
    {
        //1-轨道要全部遍历结束
        for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
        {
            //2-每一个轨道的事件不需要全部遍历
            for (NSUInteger j = chunkIndex[i]; j < self.mtrkArray[i].chunkEventArray.count; j++)
            {
                ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                
                //NSLog(@"轨道%ld事件%ld的状态码是%@,是否是缺失事件%d,当前的事件在MIDI中的位置是%ld,即时的总时间是%f",i,j,chunkEvent.eventStatus,chunkEvent.isUnFormal,chunkEvent.location,chunkEvent.eventPlayTime);
                
                
                if (chunkEvent.eventPlayTime > preLowEventTime)
                {
                    //说明已经更新过一次了(已经在第二个轨道了)
                    if (lowEventTime > preLowEventTime)
                    {
                        if (lowEventTime >= chunkEvent.eventPlayTime)
                        {
                            lowEventTime = chunkEvent.eventPlayTime;
                        }
                    }
                    //第一次更新(默认取第一个轨道中大于preLowEventTime的数)
                    else
                    {
                        lowEventTime = chunkEvent.eventPlayTime;
                    }
                    
                    chunkIndex[i] = j;
                    
                    break;
                }
                
            }
        }
        
        allTimeNum ++;
        
        NSLog(@"第%d个最小的总时间已经找到是%f",allTimeNum,lowEventTime);
        
        //NSLog(@"%d时间的事件数组是%@",allTimeNum,mEventArray);
        
        //播放音乐
        mEventArray = [self GetEventArrayWithTime:lowEventTime andIndexArray:chunkIndex];
        
        //播放0时间数组的事件
        [self PlaySoundWithArray:mEventArray andDelayTime:lowEventTime - preLowEventTime];
        
        //更新数据
        preLowEventTime = lowEventTime;
    }
    
    NSLog(@"播放结束");
    
}

//封装一个方法:传入一个基准数,返回一个事件数组
-(NSMutableArray<ChunkEvent *> *)GetEventArrayWithTime:(float)lowTime andIndexArray:(NSUInteger[])chunkIndex
{
    //用一个临时的可变数组来保存当前的事件
    NSMutableArray<ChunkEvent *> *mEventArray = [NSMutableArray array];

    
    //1-轨道要全部遍历结束
    for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
    {
        //2-每一个轨道的事件不需要全部遍历
        for (NSUInteger j = chunkIndex[i]; j < self.mtrkArray[i].chunkEventArray.count; j++)
        {
            ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
             //NSLog(@"轨道%ld事件%ld的状态码是%@,是否是缺失事件%d,当前的事件在MIDI中的位置是%ld,即时的总时间是%f",i,j,chunkEvent.eventStatus,chunkEvent.isUnFormal,chunkEvent.location,chunkEvent.eventPlayTime);
            
            //根据最小值基准数来遍历
            if (chunkEvent.eventPlayTime < lowTime)
            {
                continue;
            }
            else if(chunkEvent.eventPlayTime == lowTime)
            {
                [mEventArray addObject:chunkEvent];
            }
            else
            {
                break;
            }
        }
    }
    
    return mEventArray;
}

//封装一个方法:播放数组事件
-(void)PlaySoundWithArray:(NSMutableArray<ChunkEvent *> *)eventArray andDelayTime:(float)deltaTime
{
    
    [NSThread sleepForTimeInterval:deltaTime];
    
    //NSLog(@"过%f秒播放",deltaTime);
    NSLog(@"播放的数组%@",eventArray);
    
    [eventArray enumerateObjectsUsingBlock:^(ChunkEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //播放音乐的核心代码
        //播放音乐(一个事件一个事件地播放音乐)
        //不播放FF和F0开头事件的音乐
    
         if (obj.eventStatus.length <= 2)
         {
             [self PlaySoundWithChunkEvent:obj];
         }
    }];
}


//封装播放音乐的方法(传入一个事件)
-(void)PlaySoundWithChunkEvent:(ChunkEvent *)chunkEvent
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
