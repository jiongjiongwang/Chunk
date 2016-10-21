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



#warning 放到PCH文件中，给整个项目使用
#define kFilePath "/Users/dn210/Desktop/Trateil.mid"


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
    [self PlayTheMIDI];
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
    NSUInteger quartTime = 500000;
    
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
            
            
            allChunkDeltaTime += chunkEvent.eventDeltaTime;

            //当前事件的时长
            float theChunkEventTime = 0.00000000;
            
            theChunkEventTime = (float)((float)chunkEvent.eventDeltaTime/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100;
            
            //即时的总时长
            theTime += theChunkEventTime;
            
            //即时的总时长赋值给事件
            chunkEvent.eventPlayTime = theTime;
            
            
            
            //NSLog(@"轨道%ld事件%ld的状态码是%@,是否是缺失事件%d,其delta-Time是%ld,事件的当前时间是%f,即时的4分音符的时长是%ld,即时的总delta-time是%ld,即时的总时间是%f",i,j,chunkEvent.eventStatus,chunkEvent.isUnFormal,chunkEvent.eventDeltaTime,theChunkEventTime,quartTime,allChunkDeltaTime,theTime);
            
            
            //出现5103事件时，4分音符时长发生变化
            if ([chunkEvent isKindOfClass:[FF5103ChunkEvent class]])
            {
                
                //4分音符的时长更新
                quartTime = [[chunkEvent valueForKey:@"theQuartTime"] integerValue];
            }
        }
        
        //NSLog(@"当前轨道块%ld播放结束,其事件总数是%ld,总时长是%f",i,self.mtrkArray[i].chunkEventArray.count,theTime);

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

//播放MIDI文件
-(void)PlayTheMIDI
{
    NSLog(@"当前MIDI文件的轨道数:%ld",_chunkHead.chunkNum);
    
    
    //用一个临时的可变数组来保存当前的事件
    NSMutableArray<ChunkEvent *> *mEventArray = [NSMutableArray array];
    
    //1-取轨道0的事件0的所在时间(作为基准点时间)
    float eventTime = 0.00000000;
    
    //遍历MIDI事件中的轨道
    for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
    {
        //遍历轨道中的事件
        for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
        {
             ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
            NSLog(@"轨道%ld中的事件%ld的所在时间是%f",i,j,chunkEvent.eventPlayTime);
            
            //初始化eventTime:取轨道0的事件0的所在时间(作为基准点时间)
            
            
            
            //1-取轨道0的事件0的所在时间
            if (chunkEvent.eventPlayTime == eventTime)
            {
                [mEventArray addObject:chunkEvent];
            }
            
        }
        
        NSLog(@"当前轨道结束");
    }
    
    //2-字典中的键按照从小到大排序
    //NSLog(@"重新分配得到的字典是%@",eventDict);
    
    
    //播放音乐的核心代码
    //播放音乐(一个事件一个事件地播放音乐)
    //不播放FF和F0开头事件的音乐
    /*
     if (chunkEvent.eventStatus.length <= 2 && i == 5)
     {
     [NSThread sleepForTimeInterval:theChunkEventTime];
     
     [self PlaySoundWithChunkEvent:chunkEvent];
     }
     */
    
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
