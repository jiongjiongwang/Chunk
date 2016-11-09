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
#import "PlayAndPauseMusic.h"


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

//播放/暂停音乐按钮
@property (nonatomic,weak)UIButton *playButton;


//设置定时器
@property (nonatomic,strong)NSTimer *timer;

//定义一个全局属性记录一下当前MIDI的总时间
@property (nonatomic,assign)float midiAllTime;

//定义一个数组记录一下MIDI文件中所有5103事件的数组
@property (nonatomic,strong)NSArray<FF5103ChunkEvent *> *ff5103Array;

//定义一个子线程队列
@property (nonatomic,strong)NSOperationQueue *queue;

//定义一个子线程
@property (nonatomic,strong)PlayAndPauseMusic *playOrPause;



@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpUI];
    
    _chunkHead = [ChunkHeader sharedChunkHeaderFrom:kFilePath];
    
    //1-初始化
    _sampler = [[MIDISampler alloc] init];
    
}

-(NSOperationQueue *)queue
{
    if (!_queue)
    {
        _queue = [[NSOperationQueue alloc] init];
    }
    
    return _queue;
}

-(PlayAndPauseMusic *)playOrPause
{
    if (!_playOrPause)
    {
        _playOrPause = [[PlayAndPauseMusic alloc] init];
    }
    
    return _playOrPause;
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
    
    
    
    
    //2-播放/暂停音乐按钮
    UIButton *playButton = [[UIButton alloc] init];
    
    self.playButton = playButton;
    
    [self.view addSubview:playButton];
    
    [playButton setTitle:@"播放" forState:UIControlStateNormal];
    
    [playButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    playButton.titleLabel.font = [UIFont systemFontOfSize:17];;
    
    //添加事件
    [playButton addTarget:self action:@selector(PlayMIDI) forControlEvents:UIControlEventTouchUpInside];
    
    
    //设置约束
    [playButton mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.centerX.equalTo(self.view.mas_centerX);
        
        make.bottom.equalTo(self.timeLabel.mas_top).offset(-10);
        
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

//播放按钮方法
-(void)PlayMIDI
{
    
    //按下播放时
    if ([_playButton.titleLabel.text isEqualToString:@"播放"])
    {
        [_playButton setTitle:@"暂停" forState:UIControlStateNormal];
        
        self.playOrPause.playStr = @"播放音乐";
        
        self.playOrPause.play = YES;
        
        NSLog(@"%d",self.playOrPause.executing);
        
        if (!self.playOrPause.executing)
        {
           [self.queue addOperation:self.playOrPause];
        }
         //设置定时器
         _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(labelUpdate) userInfo:nil repeats:YES];
        
    }
    else
    {
         [_playButton setTitle:@"播放" forState:UIControlStateNormal];
        
         self.playOrPause.playStr = @"暂停音乐";
        
         self.playOrPause.play = NO;
        
        
         [self.timer invalidate];
    }
    
    
    
}


//定时器销毁
-(void)dealloc
{
    [self.timer invalidate];
}


-(float)midiAllTime
{
    if (_midiAllTime == 0)
    {
        //记录一下每个4分音符的时长(不断变化的)
        NSUInteger quartTime = 0;
        
        //遍历MIDI事件中的轨道
        for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
        {
            
            //即时计算当前轨道的时间
            float theTime = 0.00000000;
            
            //遍历轨道中的事件(遍历每一个事件)
            //在当前这个轨道中
            for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
            {
                ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                
                
                
                //判断即时的总delta-time是否大于ff5103数组中的最大值
                if (self.ff5103Array.count > 0)
                {
                    //超过了总的5103
                    if (chunkEvent.eventAllDeltaTime > self.ff5103Array[self.ff5103Array.count - 1].eventAllDeltaTime)
                    {
                        quartTime = self.ff5103Array[self.ff5103Array.count - 1].theQuartTime;
                    }
                    else
                    {
                        theTime =  self.ff5103Array[self.ff5103Array.count - 1].eventPlayTime;
                        
                        continue;
                    }
                }
                else
                {
                    quartTime = 500000;
                }
                
                
                //超过的时长
                float theSurDelataTime = 0.00000000;
                
                theSurDelataTime = (float)((float)(chunkEvent.eventAllDeltaTime - self.ff5103Array[self.ff5103Array.count - 1].eventAllDeltaTime)/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100;
                
                theTime = theSurDelataTime + self.ff5103Array[self.ff5103Array.count - 1].eventPlayTime;
                
            }
            
            if (_chunkHead.chunkType == 0)
            {
                _midiAllTime = theTime;
            }
            else if(_chunkHead.chunkType == 1)
            {
                if (_midiAllTime <= theTime)
                {
                    _midiAllTime = theTime;
                }
            }
            else
            {
                _midiAllTime += theTime;
            }
            
        }
        
        NSLog(@"当前MIDI文件的总时间是:%f",_midiAllTime);
        
    }
    
    return _midiAllTime;
}



#warning 默认5103的分布不会出现凹形状的
-(NSArray<FF5103ChunkEvent *> *)ff5103Array
{
    if (_ff5103Array == nil)
    {
        
        NSMutableArray<FF5103ChunkEvent *> *ff51mArray = [NSMutableArray array];
        
        //记录一下每个4分音符的时长(不断变化的)
        NSUInteger quartTime = 0;
        
        
        //遍历MIDI事件中的轨道
        for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
        {
            
            //即时统计当前轨道中的delta-time(总的delta-time)
            NSUInteger allChunkDeltaTime = 0;
            
            //即时统计总时间
            float theTime = 0.000000;
            
            
            
            //遍历轨道中的事件(遍历每一个事件)
            //在当前这个轨道中
            for (NSUInteger j = 0; j < self.mtrkArray[i].chunkEventArray.count; j++)
            {
                ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                
                //即时的总delta-time
                allChunkDeltaTime += chunkEvent.eventDeltaTime;
                
                
                //更新属性值:即时的总delta-time
                chunkEvent.eventAllDeltaTime = allChunkDeltaTime;
                
                
                //即时计算总时间
                //当前事件的时长
                float theChunkEventTime = 0.00000000;
                
                theChunkEventTime = (float)((float)chunkEvent.eventDeltaTime/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100;
                
                //即时的总时长
                theTime += theChunkEventTime;
                
                
                
                //出现5103事件时，4分音符时长发生变化
                if ([chunkEvent isKindOfClass:[FF5103ChunkEvent class]])
                {
                    //更新属性值:即时的总delta-time
                    //chunkEvent.eventAllDeltaTime = allChunkDeltaTime;
                    
                    //更新即时时间属性值
                    chunkEvent.eventPlayTime = theTime;
                    
                    
                    quartTime = ((FF5103ChunkEvent *)chunkEvent).theQuartTime;
                    
                    
                    //NSLog(@"delta-time:%ld之后的4分音符的时长是%ld,%ld之前的总运行时间是%f",allChunkDeltaTime,quartTime,allChunkDeltaTime,theTime);
                    
                    [ff51mArray addObject:(FF5103ChunkEvent *)chunkEvent];
                }
            }
        }
        
        _ff5103Array = ff51mArray.copy;
        
    }
    
    return _ff5103Array;
}



//播放MIDI文件
-(void)PlayMIDIMultiTemp
{
    //用一个数来得到最小的值
    float lowEventTime = 0.0000000;
    
    //记录一下前一个得到的最小值
    float preLowEventTime;
    
    
    
    //总共的时间数
    int allTimeNum = 0;


    //定义一个数组来记录一下每一轨道的索引信息(4分音符范围的数组)
    //所在4分音符的终点
    NSUInteger quartChunkIndex[_chunkHead.chunkNum];
    
    memset(quartChunkIndex, 0, sizeof(quartChunkIndex));
    
    
    
    //定义另一个数组
    //定义一个数组来记录一下每一轨道的索引信息
    NSUInteger chunkIndex[_chunkHead.chunkNum];
    
    
    memset(chunkIndex, 0, sizeof(chunkIndex));
    
    
    
    
    NSMutableArray *mEventArray;
    
    allTimeNum ++;
    
     //mEventArray = [self GetEventArrayWithTime:lowEventTime andIndexArray:chunkIndex andEndIndexArray:quartChunkIndex];
    
    //播放0时间数组的事件
    //[self PlaySoundWithArray:mEventArray andDelayTime:0.000000];
    
    //preLowEventTime初始为0
    preLowEventTime = lowEventTime;
    
    
    for (NSUInteger k = 0; k < self.ff5103Array.count; k++)
    {
        
          //1-轨道要全部遍历结束
            for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
            {
                
                //2-每一个轨道的事件不需要全部遍历
                for (NSUInteger j = quartChunkIndex[i]; j < self.mtrkArray[i].chunkEventArray.count; j++)
                {
                    ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                    
                     //5103数组最后一个或当前MIDI文件只有一个5103
                     if (k == self.ff5103Array.count -1)
                     {
                        
                         //计算每个事件的时刻
                         //即时计算总时间
                         float theTime = 0.00000000;
                         
                         NSUInteger quartTime = self.ff5103Array[k].theQuartTime;
                         
                         
                         theTime = (float)((float)(chunkEvent.eventAllDeltaTime - self.ff5103Array[k].eventAllDeltaTime)/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100 + self.ff5103Array[k].eventPlayTime;
                         
                         //即时的总时长
                         chunkEvent.eventPlayTime = theTime;
                         
                         
                         quartChunkIndex[i] = self.mtrkArray[i].chunkEventArray.count - 1;
                     }
                     else
                     {
                         if (chunkEvent.eventAllDeltaTime > self.ff5103Array[k].eventAllDeltaTime && chunkEvent.eventAllDeltaTime <= self.ff5103Array[k + 1].eventAllDeltaTime)
                         {
                             
                             //计算每个事件的时刻
                             //即时计算总时间
                             float theTime = 0.00000000;
                             
                             NSUInteger quartTime = self.ff5103Array[k].theQuartTime;
                             
                             
                             theTime = (float)((float)(chunkEvent.eventAllDeltaTime - self.ff5103Array[k].eventAllDeltaTime)/(float)_chunkHead.tickNum) * quartTime *0.00100 * 0.00100 + self.ff5103Array[k].eventPlayTime;
                             
                             //即时的总时长
                             chunkEvent.eventPlayTime = theTime;
                             
                         }
                         else if (chunkEvent.eventAllDeltaTime > self.ff5103Array[k + 1].eventAllDeltaTime)
                         {
                             //超过了当前的4分范围了，4分时间要更新
                             quartChunkIndex[i] = j;
                             
                             break;
                         }
                     }
                }
            }
        
        float endTime = 0.000000;
        
        

        //5103数组最后一个或当前MIDI文件只有一个5103
        if (k == self.ff5103Array.count -1)
        {
            //endTime = _midiAllTime;
            endTime = self.midiAllTime;
        }
        else
        {
            endTime = self.ff5103Array[k+1].eventPlayTime;
        }
        
#warning 待封装
        while (lowEventTime < endTime)
        {
            //1-轨道要全部遍历结束
            for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
            {
                //2-每一个轨道的事件不需要全部遍历
                for (NSUInteger j = chunkIndex[i]; j < quartChunkIndex[i]; j++)
                {
                    ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                    
                    
                    if (chunkEvent.eventPlayTime > preLowEventTime)
                    {
                        //说明已经更新过一次了
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
            
            //NSLog(@"第%d个最小的总时间已经找到是%f,此时的5103序列号是%ld",allTimeNum,lowEventTime,k);
            
            
            //播放音乐
            //生成事件数组
            mEventArray = [self GetEventArrayWithTime:lowEventTime andIndexArray:chunkIndex andEndIndexArray:quartChunkIndex];
            
            //播放0时间数组的事件
            [self PlaySoundWithArray:mEventArray andDelayTime:lowEventTime - preLowEventTime];
            
            //更新数据
            preLowEventTime = lowEventTime;
      }
        
    }
    
        NSLog(@"播放结束");
    
    //通知主界面播放结束
    
    
}



//封装一个方法:传入一个基准数,返回一个事件数组
-(NSMutableArray<ChunkEvent *> *)GetEventArrayWithTime:(float)lowTime andIndexArray:(NSUInteger[])chunkIndex andEndIndexArray:(NSUInteger[])endChunkIndex
{
    //用一个临时的可变数组来保存当前的事件
    NSMutableArray<ChunkEvent *> *mEventArray = [NSMutableArray array];
    
    
    //1-轨道要全部遍历结束
    for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
    {
        
        //根据传入的lowTime设置不同的终点
        NSUInteger endIndex;
        
        if (lowTime == 0.0000000000)
        {
            endIndex = self.mtrkArray[i].chunkEventArray.count;
        }
        else
        {
            endIndex = endChunkIndex[i];
        }
        
        
        //遍历轨道的每一个事件或每一个轨道的事件不需要全部遍历
        for (NSUInteger j = chunkIndex[i]; j < endIndex; j++)
        {
            ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
            
            if (lowTime == 0.0000000000)
            {
                //根据最小值基准数来遍历
                if(chunkEvent.eventAllDeltaTime == 0)
                {
                    [mEventArray addObject:chunkEvent];
                }
                else
                {
                    break;
                }
            }
            else
            {
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
        
    }
    
    return mEventArray;
}

//封装一个方法:播放数组事件
-(void)PlaySoundWithArray:(NSMutableArray<ChunkEvent *> *)eventArray andDelayTime:(float)deltaTime
{
    
    [NSThread sleepForTimeInterval:deltaTime];
    
    
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
