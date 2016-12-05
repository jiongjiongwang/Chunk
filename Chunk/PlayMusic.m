//
//  PlayMusic.m
//  Chunk
//
//  Created by dn210 on 16/11/9.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "PlayMusic.h"


@interface PlayMusic()


@property (nonatomic,strong)ChunkHeader *chunkHead;

//定义一个数组记录一下MIDI文件中所有5103事件的数组
@property (nonatomic,strong)NSArray<FF5103ChunkEvent *> *ff5103Array;


//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
@property (nonatomic,strong)NSArray<MTRKChunk *> *mtrkArray;


//定义一个全局属性记录一下当前MIDI的总时间
@property (nonatomic,assign)float midiAllTime;


//一个MIDI文件在内存中只存在一个NSData对象
@property (nonatomic,strong)NSData *midiData;


//播放音乐的Sampler对象
@property (nonatomic,strong)MIDISampler *sampler;




//时间链表
@property (nonatomic,assign)struct node *theTimeHead;

//记录起点的链表指针
@property (nonatomic,assign)struct node *startIndexHead;

@property (nonatomic,strong)NSTimer *timer;

@property (nonatomic,assign)float clock;



@end




@implementation PlayMusic


+(instancetype)PlayMusicWithChunkHead:(ChunkHeader *)chunkHead andff5103Array:(NSArray<FF5103ChunkEvent *> *)ff5103Array andMTRKArray:(NSArray<MTRKChunk *> *)mtrkArray
                       andMidiAllTime:(float)midiAllTime
                          andMidiData:(NSData *)midiData
{
    PlayMusic *playOrPause = [[PlayMusic alloc] init];
    
    //轨道头
    playOrPause.chunkHead = chunkHead;
    
    //MIDI中的5103数组
    playOrPause.ff5103Array = ff5103Array;
    
    //一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
    playOrPause.mtrkArray = mtrkArray;
    
    //定义一个全局属性记录一下当前MIDI的总时间
    playOrPause.midiAllTime = midiAllTime;
    
    //一个MIDI文件在内存中只存在一个NSData对象
    playOrPause.midiData = midiData;
    
    
    playOrPause.sampler = [[MIDISampler alloc] init];
    
    return playOrPause;
}


-(void)PlayMIDIMultiTempMusic
{
    
    //得出时间链表
    
    [self PlayMIDIMultiTemp];
    
    /*
    while (_theTimeHead != NULL)
    {
        NSLog(@"%f",_theTimeHead->lowTime);
        
        _theTimeHead = _theTimeHead -> next;
    }
    */
    
    //开始播放
    NSLog(@"开始播放");
    
    
    _startIndexHead = _theTimeHead;
    
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(TimeGo) userInfo:nil repeats:YES];
    
}

-(void)TimeGo
{
    if (_clock == 0)
    {
        NSLog(@"%f",_clock);
    }
    
    
    if (_clock >= self.midiAllTime)
    {
        NSLog(@"%f",self.midiAllTime);
        
        [_timer invalidate];
        
        NSLog(@"%f",_clock);
        
        return;
    }
    
    
    
    
    struct node *head;
    
    head = _startIndexHead;
    
    
    while (head != NULL)
    {
        
        if (head->lowTime - _clock < 0.001 && head->lowTime - _clock > 0)
        {
            
            //播放音乐
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                //NSLog(@"在%@线程中播放时间为%f的音乐",[NSThread currentThread],head->lowTime);
                
                
                NSMutableArray *mEventArray;
                
                NSUInteger quartChunkIndex[_chunkHead.chunkNum];
                
                memset(quartChunkIndex, 0, sizeof(quartChunkIndex));
                
                
                
                NSUInteger chunkIndex[_chunkHead.chunkNum];
                
                
                memset(chunkIndex, 0, sizeof(chunkIndex));
                
                //生成事件数组
#warning 3-生成事件数组的时间(暂时不可减去)
                //传入一个基准数,返回一个事件数组
                mEventArray = [self GetEventArrayWithTime:head->lowTime andIndexArray:chunkIndex andEndIndexArray:quartChunkIndex];
                
                //NSLog(@"当前的播放时间是%f,前一个播放时间是%f,之间的差值为%f",lowEventTime,preLowEventTime,lowEventTime-preLowEventTime);
                
                
                //播放音乐
#warning 4-播放音乐的时间(不可减去)
                [self PlaySoundWithArray:mEventArray andDelayTime:0];
                
            });
            
            _startIndexHead = head;
            
            
            break;
        }
        else if (head->lowTime - (_clock + 0.001) >= 0)
        {
            break;
        }
        
        
        head = head -> next;
    }
    
    _clock += 0.001;
}




-(void)PlayMIDIMultiTemp
{
    
    struct node *head = NULL,*p,*q = NULL;
    
    
    //用一个数来得到最小的值
    float lowEventTime = 0.0000000;
    
    //记录一下前一个得到的最小值
    float preLowEventTime;
    
    
    
    //总共的时间数
    int allTimeNum = 0;
    
    
    //定义一个数组来记录一下每一轨道的索引信息(4分音符范围的数组)
    //所在4分音符的终点
    //终点
    NSUInteger quartChunkIndex[_chunkHead.chunkNum];
    
    memset(quartChunkIndex, 0, sizeof(quartChunkIndex));
    
    
    
    
    //定义另一个数组
    //定义一个数组来记录一下每一轨道的索引信息
    //起点
    NSUInteger chunkIndex[_chunkHead.chunkNum];
    
    
    memset(chunkIndex, 0, sizeof(chunkIndex));
    
    
    
    
    NSMutableArray *mEventArray;
    
    allTimeNum ++;
    
    mEventArray = [self GetEventArrayWithTime:lowEventTime andIndexArray:chunkIndex andEndIndexArray:quartChunkIndex];
    
    //播放0时间数组的事件
    //[self PlaySoundWithArray:mEventArray andDelayTime:0.000000];
    
    //preLowEventTime初始为0
    preLowEventTime = lowEventTime;
    
    //暂停次数
    NSUInteger pauseNum = 0;
    
    //NSLog(@"播放开始");
    
    for (NSUInteger k = 0; k < self.ff5103Array.count; k++)
    {
        
#warning 1-得到事件时间的时间(很短,但是在多个5103的情况下可能会比较长)
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
        
        
        
        //设置起点(默认为0)
        float startIndex = 0;
        //设置终点(默认为0.000001）
        float endIndex = 0.001;
        
        //NSLog(@"播放开始");
        
        
        while (endIndex <= endTime)
        {
            mEventArray = [self GetEventArrayWithTime:startIndex andendTime:endIndex andIndexArray:chunkIndex andEndIndexArray:quartChunkIndex];
            
            //播放音乐
#warning 4-播放音乐的时间(不可减去)
            
            if (mEventArray.count >= 1)
            {
                
               //取时间
                ChunkEvent *event = (ChunkEvent *)mEventArray[0];
                
                float eventPlayTime = event.eventPlayTime;
                //NSLog(@"开始播放%f时的MIDI,所在范围是%f到%f之间",eventPlayTime,startIndex,endIndex);
                
                //NSLog(@"开始播放%f时的MIDI",eventPlayTime);
                
                p = (struct node *)malloc(sizeof(struct node));
                
                p->lowTime = eventPlayTime;
                
                p->next = NULL;
                
                
                
                if (head == NULL)
                {
                    //如果这是第一个创建的结点，则将头指针指向这个结点
                    head = p;
                }
                else
                {
                    //如果不是第一个创建的结点，则将上一个结点的后继指针指向当前结点
                    q->next = p;
                }
                
                //指向q也指向当前结点
                q=p;
                
                
                
                
                //NSLog(@"当前的时刻是%f",startIndex);
                //[self PlaySoundWithArray:mEventArray andDelayTime:eventPlayTime - startIndex];
                
                //NSLog(@"结束播放%f时的MIDI",eventPlayTime);
                
            }
            else
            {
                //NSLog(@"当前的时刻是%f",startIndex);
                //[NSThread sleepForTimeInterval:0.001];
                //NSLog(@"什么都不做,浑浑郁郁地度过这0.001秒");
            }
        
            startIndex += 0.001;
            
            endIndex = startIndex + 0.001;
        }
        
        
        
        
        //NSLog(@"播放结束");
        
        
        
        
        
        
        //NSLog(@"播放开始");
        /*
        while (lowEventTime < endTime)
        {
            
            if (_play == YES)
            {
                
                
                //1-轨道要全部遍历结束
                for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
                {
                    //2-每一个轨道的事件不需要全部遍历
                    for (NSUInteger j = chunkIndex[i]; j < quartChunkIndex[i]; j++)
                    {
                        ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                        
#warning 2-排序时间(很长)
                        if (chunkEvent.eventPlayTime > preLowEventTime)
                        {
                            //说明已经更新过一次了
                            if (lowEventTime > preLowEventTime)
                            {
                                
                                //若发现比当前的"最小值"更小的，则更新为更小的那一个
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
                
                
                
                //生成事件数组
#warning 3-生成事件数组的时间(暂时不可减去)
               //传入一个基准数,返回一个事件数组
              mEventArray = [self GetEventArrayWithTime:lowEventTime andIndexArray:chunkIndex andEndIndexArray:quartChunkIndex];
                
                //NSLog(@"当前的播放时间是%f,前一个播放时间是%f,之间的差值为%f",lowEventTime,preLowEventTime,lowEventTime-preLowEventTime);
                
                
                //播放音乐
#warning 4-播放音乐的时间(不可减去)
                [self PlaySoundWithArray:mEventArray andDelayTime:lowEventTime - preLowEventTime];
                
                
                
                
                
                //更新数据
                preLowEventTime = lowEventTime;
                
                pauseNum = 0;
            }
            else
            {
                pauseNum ++;
                
                if (pauseNum == 1)
                {
                    NSLog(@"播放暂停,播放数:%ld",pauseNum);
                    
                     [_sampler MIDIAllNotesOff];
                }
            }
        }
        */
        //NSLog(@"第%ld个区域播放完毕",k);
        
    }
    
    _theTimeHead = head;
    
    //NSLog(@"播放结束");
}






//事件时间排序
-(struct node *)TimePaixuWithEndChunkArray:(NSUInteger[])endChunkIndex andEndTime:(float)endTime
{
    
    //用一个数来得到最小的值
    float lowEventTime = 0.0000000;
    
    //记录一下前一个得到的最小值
    float preLowEventTime;
    
    
    //总共的时间数
    int allTimeNum = 0;
    
    
    //定义另一个数组
    //定义一个数组来记录一下每一轨道的索引信息
    //起点
    NSUInteger chunkIndex[_chunkHead.chunkNum];
    
    
    memset(chunkIndex, 0, sizeof(chunkIndex));
    
    
    //preLowEventTime初始为0
    preLowEventTime = lowEventTime;
    
    
    struct node *head = NULL,*p,*q = NULL;
    
    
    while (lowEventTime < endTime)
    {
        
        p = (struct node *)malloc(sizeof(struct node));
        
        
        
        //1-轨道要全部遍历结束
        for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
        {
            //2-每一个轨道的事件不需要全部遍历
            for (NSUInteger j = chunkIndex[i]; j < endChunkIndex[i]; j++)
            {
                ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
                
                if (chunkEvent.eventPlayTime > preLowEventTime)
                {
                    //说明已经更新过一次了
                    if (lowEventTime > preLowEventTime)
                    {
                        
                        //若发现比当前的"最小值"更小的，则更新为更小的那一个
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
        
        
        //NSLog(@"第%d个最小的总时间已经找到是%f",allTimeNum,lowEventTime);
        
       // p = (struct node *)malloc(sizeof(struct node));
        
        p->lowTime = lowEventTime;
        
        p->preLowTime = preLowEventTime;
        
        p->next = NULL;
        
        if (head == NULL)
        {
            //如果这是第一个创建的结点，则将头指针指向这个结点
            head = p;
        }
        else
        {
            //如果不是第一个创建的结点，则将上一个结点的后继指针指向当前结点
            q->next = p;
        }
        
        //指向q也指向当前结点
        q=p;
        
        //更新数据
        preLowEventTime = lowEventTime;
    }
    
    return head;
    
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

//封装一个方法:传入一个范围，返回一个数组
-(NSMutableArray<ChunkEvent *> *)GetEventArrayWithTime:(float)startTime andendTime:(float)endTime andIndexArray:(NSUInteger[])chunkIndex andEndIndexArray:(NSUInteger[])endChunkIndex
{
    
    //用一个临时的可变数组来保存当前的事件
    NSMutableArray<ChunkEvent *> *mEventArray = [NSMutableArray array];
    
    float tempTime = 0;
    
    int num = 0;
    
    static int allNum = 0;
    
    //1-轨道要全部遍历结束
    for (NSUInteger i = 0; i < _chunkHead.chunkNum; i++)
    {
        //2-每一个轨道的事件不需要全部遍历
        for (NSUInteger j = chunkIndex[i]; j < endChunkIndex[i]; j++)
        {
            ChunkEvent *chunkEvent = self.mtrkArray[i].chunkEventArray[j];
            
            if (chunkEvent.eventPlayTime > startTime && chunkEvent.eventPlayTime <= endTime)
            {
                 [mEventArray addObject:chunkEvent];
                
                if (tempTime == 0)
                {
                    //第一次赋值
                    tempTime = chunkEvent.eventPlayTime;
                    
                    num ++;
                    
                    allNum ++;
                }
                else
                {
                    //已经把第一个值赋值了
                    if (tempTime != chunkEvent.eventPlayTime)
                    {
                        num ++;
                    }
                }
                
                
                //NSLog(@"在%f到%f的范围内的时间是%f,此时间总数为%d,最小时间编号为%d",startTime,endTime,chunkEvent.eventPlayTime,num,allNum);
                
                chunkIndex[i] = j;
                
                break;
            }
            else if(chunkEvent.eventPlayTime > endTime)
            {
                chunkIndex[i] = j;
                
                break;
            }
            
        }
    }
    
    return mEventArray;
}

//仅仅是放
//封装一个方法:播放数组事件
-(void)PlaySoundWithArray:(NSMutableArray<ChunkEvent *> *)eventArray andDelayTime:(float)deltaTime
{
    
    //NSLog(@"相隔时间=%f",deltaTime);
    //[NSThread sleepForTimeInterval:deltaTime];
    
    
    //NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"HH:mm:ss:SSS"];
    
    
    //NSString *startDateStr = [dateFormatter stringFromDate:[NSDate date]];
    //NSLog(@"开始播放当前数组,当前的时间是%@",startDateStr);
    
    //float startValue = [startDateStr floatValue];
    
    
    
    [eventArray enumerateObjectsUsingBlock:^(ChunkEvent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //播放音乐的核心代码
        //播放音乐(一个事件一个事件地播放音乐)
        //不播放FF和F0开头事件的音乐
        if (obj.eventStatus.length <= 2)
        {
            //NSLog(@"%@",obj);
            
            [self PlaySoundWithChunkEvent:obj];
        }
    }];
    
    //NSString *endDateStr = [dateFormatter stringFromDate:[NSDate date]];
    //NSLog(@"当前数组播放完毕,当前的时间是%@",endDateStr);
    
    /*
    if ([startDateStr isEqualToString:endDateStr])
    {
        NSLog(@"播放音乐在0.001秒内完成");
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





@end
