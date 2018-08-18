//
//  TestRACSequenceTests.m
//  TestRACSequenceTests
//
//  Created by ys on 2018/8/18.
//  Copyright © 2018年 ys. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <ReactiveCocoa.h>

@interface TestRACSequenceTests : XCTestCase

@end

@implementation TestRACSequenceTests

- (void)test_sequenceWithHeadBlock
{
    RACSequence *sequence1 = [RACSequence sequenceWithHeadBlock:^id{
        return @(1);
    } tailBlock:nil];
    RACSequence *sequence2 = [RACSequence sequenceWithHeadBlock:^id{
        return @"x";
    } tailBlock:^RACSequence *{
        return sequence1;
    }];
    
    NSLog(@"sequenceWithHeadBlock -- %@ -- %@", sequence1, sequence2);
    
    // 打印日志：
    /*
     2018-08-13 17:29:11.779905+0800 TestRACSequence[91431:11665825] sequenceWithHeadBlock -- <RACDynamicSequence: 0x6000000937e0>{ name = , head = (unresolved), tail = (null) } -- <RACDynamicSequence: 0x600000092570>{ name = , head = (unresolved), tail = (unresolved) }
     */
}

- (void)test_head_tail
{
    RACSequence *sequence1 = [RACSequence sequenceWithHeadBlock:^id{
        return @(1);
    } tailBlock:nil];
    RACSequence *sequence2 = [RACSequence sequenceWithHeadBlock:^id{
        return @"x";
    } tailBlock:^RACSequence *{
        return sequence1;
    }];
    NSLog(@"head_tail -- %@ -- %@ -- %@", sequence2, sequence2.head, sequence2.tail);
    
    // 打印日志：
    /*
     2018-08-13 17:35:23.971686+0800 TestRACSequence[91710:11683638] head_tail -- <RACDynamicSequence: 0x6000002827b0>{ name = , head = x, tail = <RACDynamicSequence: 0x600000285730>{ name = , head = (unresolved), tail = (null) } } -- x -- <RACDynamicSequence: 0x600000285730>{ name = , head = (unresolved), tail = (null) }
     */
}

- (void)test_empty
{
    RACSequence *sequence = [RACSequence empty];
    NSLog(@"empty -- %@", sequence);
    
    // 打印日志：
    /*
     2018-08-13 17:36:49.308519+0800 TestRACSequence[91788:11688256] empty -- <RACEmptySequence: 0x60400001cf90>{ name =  }
     */
}

- (void)test_return
{
    RACSequence *sequence = [RACSequence return:@(1)];
    NSLog(@"return -- %@", sequence);
    
    // 打印日志：
    /*
     2018-08-13 17:38:49.967036+0800 TestRACSequence[91890:11694680] return -- <RACUnarySequence: 0x60400023f580>{ name = , head = 1 }
     */
}

- (void)test_bind
{
    RACSequence *sequence = [RACSequence return:@(1)];
    RACSequence *sequence1 = [sequence bind:^RACStreamBindBlock{
        return ^(id value, BOOL *stop){
            return [RACSequence return:@"x"];
        };
    }];
    NSLog(@"bind -- %@", sequence1);
    
    // 打印日志：
    /*
     2018-08-13 17:44:28.092128+0800 TestRACSequence[92150:11712416] bind -- <RACUnarySequence: 0x604000430de0>{ name = , head = x }
     */
}

- (void)test_concat
{
    RACSequence *sequence1 = [RACSequence return:@(1)];
    RACSequence *sequence2 = [RACSequence return:@"x"];
    RACSequence *quence = [sequence1 concat:sequence2];
    NSLog(@"concat -- %@", quence);
    NSLog(@"concat -- %@ -- %@ -- %@", quence.head, quence.tail, quence.tail.head);
    
    // 打印日志
    /*
     2018-08-13 17:54:42.848858+0800 TestRACSequence[92582:11743087] concat -- <RACDynamicSequence: 0x60400009e000>{ name = , head = (unresolved), tail = (unresolved) }
     2018-08-13 17:54:42.849428+0800 TestRACSequence[92582:11743087] concat -- 1 -- <RACDynamicSequence: 0x60400009e730>{ name = , head = x, tail = (unresolved) } -- x
     */
}

- (void)test_zip
{
    RACSequence *sequence1 = [RACSequence return:@(1)];
    RACSequence *sequence2 = [RACSequence return:@"x"];
    RACSequence *quence = [sequence1 zipWith:sequence2];
    NSLog(@"concat -- %@", quence);
    NSLog(@"concat -- %@ -- %@", quence.head, quence.tail);
    
    // 打印日志
    /*
     2018-08-13 17:57:01.474478+0800 TestRACSequence[92683:11750366] concat -- <RACDynamicSequence: 0x60000008d660>{ name = , head = (unresolved), tail = (unresolved) }
     2018-08-13 17:57:01.478114+0800 TestRACSequence[92683:11750366] concat -- <RACTuple: 0x60000001d640> (
     1,
     x
     ) -- (null)
     */
}

- (void)test_array
{
    RACSequence *sequence1 = [RACSequence return:@(1)];
    RACSequence *sequence2 = [RACSequence return:@"x"];
    RACSequence *sequence = [sequence1 concat:sequence2];
    NSLog(@"array -- %@", sequence);
    NSLog(@"array -- %@", sequence.array);
    
    // 打印日志：
    /*
     2018-08-13 18:00:09.420123+0800 TestRACSequence[92822:11759844] array -- <RACDynamicSequence: 0x60000028a8c0>{ name = , head = (unresolved), tail = (unresolved) }
     2018-08-13 18:00:09.421563+0800 TestRACSequence[92822:11759844] array -- (
     1,
     x
     )
     */
}

- (void)test_objectEnumerator
{
    RACSequence *sequence1 = [RACSequence return:@(1)];
    RACSequence *sequence2 = [RACSequence return:@"x"];
    RACSequence *sequence = [sequence1 concat:sequence2];
    NSEnumerator *enumerator = [sequence objectEnumerator];
    id x;
    while (x = [enumerator nextObject]) {
        NSLog(@"objectEnumerator -- %@", x);
    }
    
    // 打印日志：
    /*
     2018-08-13 18:04:54.179471+0800 TestRACSequence[93045:11774396] objectEnumerator -- 1
     2018-08-13 18:04:54.180524+0800 TestRACSequence[93045:11774396] objectEnumerator -- x
     */
}

- (void)test_signal
{
    RACSequence *sequence = [RACSequence return:@(1)];
    RACSignal *signal1 = [sequence signal];
    RACScheduler *scheduler = [RACScheduler scheduler];
    RACSignal *signal2 = [sequence signalWithScheduler:scheduler];
    NSLog(@"signal -- %@ -- %@ -- %@", signal1, scheduler, signal2);
    
    [signal1 subscribeNext:^(id x) {
        NSLog(@"signal -- %@ -- %@", x, [RACScheduler currentScheduler]);
    }];
    
    [signal2 subscribeNext:^(id x) {
        NSLog(@"signal -- %@ -- %@", x, [RACScheduler currentScheduler]);
    }];
    
    // 打印日志：
    /*
     2018-08-13 18:12:01.468921+0800 TestRACSequence[93338:11795985] signal -- <RACDynamicSignal: 0x6040004231a0> name:  -- <RACTargetQueueScheduler: 0x6040004231c0> com.ReactiveCocoa.RACScheduler.backgroundScheduler -- <RACDynamicSignal: 0x6040004231e0> name:
     2018-08-13 18:12:01.469827+0800 TestRACSequence[93338:11796059] signal -- 1 -- <RACTargetQueueScheduler: 0x604000423040> com.ReactiveCocoa.RACScheduler.backgroundScheduler
     Test Case '-[TestRACSequenceTests test_signal]' passed (0.003 seconds).
     2018-08-13 18:12:01.469858+0800 TestRACSequence[93338:11796058] signal -- 1 -- <RACTargetQueueScheduler: 0x6040004231c0> com.ReactiveCocoa.RACScheduler.backgroundScheduler
     */
}

- (void)test_foldLeftWithStart
{
    RACSequence *sequence = [RACSequence return:@(1)];
    id x = [sequence foldLeftWithStart:@(100) reduce:^id(id accumulator, id value) {
        return @([accumulator intValue] + [value intValue]);
    }];
    NSLog(@"foldLeftWithStart -- %@", x);
    
    // 打印日志：
    /*
     2018-08-13 18:15:10.572439+0800 TestRACSequence[93473:11805347] foldLeftWithStart -- 101
     */
}

- (void)test_foldRightWithStart
{
    RACSequence *sequence = [RACSequence return:@(1)];
    id x = [sequence foldRightWithStart:@(100) reduce:^id(id first, RACSequence *rest) {
        return @([first intValue] + [rest.head intValue]);
    }];
    
    NSLog(@"foldRightWithStart -- %@", x);
    
    // 打印日志：
    /*
     2018-08-13 18:18:07.610381+0800 TestRACSequence[93615:11815125] foldRightWithStart -- 1
     */
}

- (void)test_any_all_objectPassingTest
{
    RACSequence *sequence = [RACSequence sequenceWithHeadBlock:^id{
        return @(3);
    } tailBlock:^RACSequence *{
        return [RACSequence return:@(2)];
    }];
    
    BOOL any = [sequence any:^BOOL(id value) {
        return [value integerValue] > 0;
    }];
    
    BOOL all = [sequence all:^BOOL(id value) {
        return [value integerValue] > 0;
    }];
    
    id pass = [sequence objectPassingTest:^BOOL(id value) {
        return [value integerValue] > 0;
    }];
    
    NSLog(@"any_all_objectPassingTest -- %d -- %d -- %@", any, all, pass);
    
    // 打印日志：
    /*
     2018-08-13 18:23:14.915419+0800 TestRACSequence[93823:11830326] any_all_objectPassingTest -- 1 -- 1 -- 3
     */
}

- (void)test_eagerSequence
{
    RACSequence *sequence = [RACSequence sequenceWithHeadBlock:^id{
        return @(1);
    } tailBlock:^RACSequence *{
        return nil;
    }];
    NSLog(@"eagerSequence -- %@", sequence);
    RACSequence *eager = [sequence eagerSequence];
    NSLog(@"eagerSequence -- %@ -- %@", sequence, eager);
    
    // 打印日志：
    /*
     2018-08-13 18:28:13.685364+0800 TestRACSequence[94050:11846212] eagerSequence -- <RACDynamicSequence: 0x6040000972a0>{ name = , head = (unresolved), tail = (unresolved) }
     2018-08-13 18:28:13.686662+0800 TestRACSequence[94050:11846212] eagerSequence -- <RACDynamicSequence: 0x6040000972a0>{ name = , head = 1, tail = (null) } -- <RACEagerSequence: 0x604000428240>{ name = , array = (
     1
     ) }
     */
}

- (void)test_lazySequence
{
    RACSequence *sequence = [RACSequence sequenceWithHeadBlock:^id{
        return @(1);
    } tailBlock:^RACSequence *{
        return nil;
    }];
    RACSequence *lazy = [sequence lazySequence];
    NSLog(@"lazySequence -- %@ -- %@", sequence, lazy);
    
    // 打印日志：
    /*
     2018-08-13 18:51:55.549171+0800 TestRACSequence[94412:11865893] lazySequence -- <RACDynamicSequence: 0x604000481fe0>{ name = , head = (unresolved), tail = (unresolved) } -- <RACDynamicSequence: 0x604000481fe0>{ name = , head = (unresolved), tail = (unresolved) }
     */
}



@end
