//
//  PlayMusic.h
//  Chunk
//
//  Created by dn210 on 16/11/9.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChunkHeader.h"
#import "MTRKChunk.h"
#import "FF5103ChunkEvent.h"
#import "MIDISampler.h"


@interface PlayMusic : NSObject


+(instancetype)PlayMusicWithChunkHead:(ChunkHeader *)chunkHead andff5103Array:(NSArray<FF5103ChunkEvent *> *)ff5103Array andMTRKArray:(NSArray<MTRKChunk *> *)mtrkArray
                               andMidiAllTime:(float)midiAllTime
                                  andMidiData:(NSData *)midiData;

-(void)PlayMIDIMultiTemp;

//BOOL:播放/暂停音乐
@property (nonatomic,assign)BOOL play;


@end
