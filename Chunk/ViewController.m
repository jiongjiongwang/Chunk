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
#import "MIDIDecoder.h"

#warning 放到PCH文件中，给整个项目使用
#define kFilePath "/Users/dn210/Documents/DESC/DESC/Trateil.mid"


@interface ViewController ()

@property (nonatomic,strong)ChunkHeader *chunkHead;

//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
@property (nonatomic,strong)NSArray<MTRKChunk *> *mtrkArray;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _chunkHead = [ChunkHeader sharedChunkHeaderFrom:kFilePath];
    
    //轨道块总数(一次获取完成之后无需再次加载，其值固定不变)
    NSLog(@"轨道块总数为%ld",(long)_chunkHead.chunkNum);
    
    //四分音符节奏数(一次获取完成之后无需再次加载，其值固定不变)
    NSLog(@"四分音符节奏数为%ld",(long)_chunkHead.tickNum);
    
    NSLog(@"%@",self.mtrkArray);
}


//一个大的MIDI文件分成多个轨道块，用数组保存这些轨道块
-(NSArray<MTRKChunk *> *)mtrkArray
{
    if (_mtrkArray == nil)
    {
        
        if ([MIDIDecoder sharedMIDIDecoder].midiData.length <= 23)
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
        
        [[MIDIDecoder sharedMIDIDecoder].midiData enumerateByteRangesUsingBlock:^(const void *bytes,
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
                    
                    [mtrkLength deleteCharactersInRange:NSMakeRange(0, mtrkLength.length)];
                    
                    NSLog(@"轨道长度为%ld",length);
                    
                    //初始化轨道块
                    MTRKChunk *mtrkChunk = [[MTRKChunk alloc] initWithChunkLength:length and:i];
                    
                    [mMtrkArray addObject:mtrkChunk];
                }
                
            }
        }];
        
        _mtrkArray = mMtrkArray;
    }
    
    return _mtrkArray;
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
