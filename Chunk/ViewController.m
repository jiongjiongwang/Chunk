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

#import "PlayMusic.h"


#define kFilePath "/Users/wangjiong/Desktop/tu er qi jin xing qu.mid"




@interface ViewController ()

@property (nonatomic,strong)ChunkHeader *chunkHead;



//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
@property (nonatomic,strong)NSArray<MTRKChunk *> *mtrkArray;


//一个MIDI文件在内存中只存在一个NSData对象
@property (nonatomic,strong)NSData *midiData;

//定义一个全局属性记录一下当前MIDI的总时间
@property (nonatomic,assign)float midiAllTime;

//定义一个数组记录一下MIDI文件中所有5103事件的数组
@property (nonatomic,strong)NSArray<FF5103ChunkEvent *> *ff5103Array;




//播放音乐的Sampler对象
@property (nonatomic,strong)MIDISampler *sampler;

//定时器label
@property (nonatomic,weak)UILabel *timeLabel;

//播放/暂停音乐按钮
@property (nonatomic,weak)UIButton *playButton;

//设置定时器
@property (nonatomic,strong)NSTimer *timer;



@property (nonatomic,strong)PlayMusic *playMusic;

//记录播放次数
@property (nonatomic,assign)NSUInteger playTime;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpUI];
    
    _chunkHead = [ChunkHeader sharedChunkHeaderFrom:kFilePath];
    
    //1-初始化
    //_sampler = [[MIDISampler alloc] init];
    
    //[self PlayMIDIMultiTemp];
    
    
    _playMusic = [PlayMusic PlayMusicWithChunkHead:_chunkHead
                                                    andff5103Array:self.ff5103Array andMTRKArray:self.mtrkArray andMidiAllTime:self.midiAllTime andMidiData:self.midiData];
    
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
    float num = [self.timeLabel.text floatValue];
    
    num+= 0.001;
    
    self.timeLabel.text = [NSString stringWithFormat:@"%f",num];
    
}

//播放按钮方法
-(void)PlayMIDI
{
    
    //按下播放时
    if ([_playButton.titleLabel.text isEqualToString:@"播放"])
    {
        [_playButton setTitle:@"暂停" forState:UIControlStateNormal];
        
        _playMusic.play = YES;
        
#warning 播放完毕之后_playTime置为0
        _playTime ++;
        
        /*
        //当是第一次播放时
        if (_playTime == 1)
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                [_playMusic PlayMIDIMultiTemp];
                
            });
        }
        */
        
        //设置定时器
        //_timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(labelUpdate) userInfo:nil repeats:YES];
        
        
        [_playMusic PlayMIDIMultiTempMusic];
        
        
    }
    else
    {
         [_playButton setTitle:@"播放" forState:UIControlStateNormal];
        
         _playMusic.play = NO;
        
        
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
