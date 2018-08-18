##### `RACSequence` 顾名思义就是序列，也就是存放一系列数据的集合。当然`oc`中也有这种数据类型，比如`NSArray` `NSSet`等等。那这些有什么区别呢，遇到数据处理又该选择使用哪一个呢？带着这些问题，去看下`RACSequence`的实现。

完整测试用例[在这里](https://github.com/jianghui1/TestRACSequence)。

`RACSequence`继承于`RACStream`，也是一种 流 的概念，所以对于`RACStream`的操作方法，`RACSequence`也是适用的，这样就可以很方便的通过一些block实现对数据的处理。接下来，看下`RACSequence`中的属性和方法的作用。

* `head` 序列的第一个元素，如果序列为空，返回一个`nil`。
* `tail` 原序列除去第一个元素，剩下的序列。同样的，如果源序列为空，返回一个`nil`。
* `array` 将序列元素组合成一个数组`array`。
* `objectEnumerator` 返回一个`NSEnumerator`对象，用于对序列进行快速遍历。与`NSArray`遍历相似。
* `eagerSequence` 之前信号的分析中说过信号分为 冷信号 和 热信号。而序列也是一样，通过这个属性就可以获得一个原序列对应的热序列。冷序列与热序列的区别在后面的代码分析中具体区分。
* `lazySequence` 获取一个原序列对应的冷序列。
* `- (RACSignal *)signal;` 获取一个把序列值作为信号值的信号。
* `- (RACSignal *)signalWithScheduler:(RACScheduler *)scheduler;` 获取一个把序列值作为信号值的信号，并且信号值的发送发生在`scheduler`调度器上。
* `- (id)foldLeftWithStart:(id)start reduce:(id (^)(id accumulator, id value))reduce;` 将序列值从头到尾通过`reduce`计算出一个结果。
* `- (id)foldRightWithStart:(id)start reduce:(id (^)(id first, RACSequence *rest))reduce;` 将序列值从尾到头通过`reduce`计算出一个结果。
* `- (BOOL)any:(BOOL (^)(id value))block;` 类似`RACSignal`中的`any:`方法，检测序列中是否存在一个值符合`block`的规则。
* `- (BOOL)all:(BOOL (^)(id value))block;` 类似`RACSignal`中的`all:`方法，检测序列中是否所有值符合`block`的规则。
* `- (id)objectPassingTest:(BOOL (^)(id value))block;` 获取序列中第一个满足`block`条件的序列值。
* `+ (RACSequence *)sequenceWithHeadBlock:(id (^)(void))headBlock tailBlock:(RACSequence *(^)(void))tailBlock;` 序列的初始化方法，此方法要求`headBlock` `tailBlock`应当线程安全，同时`headBlock`不能为`nil`。

##### 下面分析`RACSequence`中的方法。
    + (RACSequence *)sequenceWithHeadBlock:(id (^)(void))headBlock tailBlock:(RACSequence *(^)(void))tailBlock {
    	return [[RACDynamicSequence sequenceWithHeadBlock:headBlock tailBlock:tailBlock] setNameWithFormat:@"+sequenceWithHeadBlock:tailBlock:"];
    }
> 该方法是序列的初始化方法， 方法中通过其子类`RACDynamicSequence`完成初始化工作。其实`RACSequence`的实现与`NSArray`类似，也是通过类簇分工实现不同的功能。

测试用例：

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
***

    - (id)head {
    	NSCAssert(NO, @"%s must be overridden by subclasses", __func__);
    	return nil;
    }
    
    - (RACSequence *)tail {
    	NSCAssert(NO, @"%s must be overridden by subclasses", __func__);
    	return nil;
    }
`RACSequence`作为抽象类，提供一个默认实现。

测试用例：

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
***

    + (instancetype)empty {
    	return RACEmptySequence.empty;
    }
对`RACStream`中方法的实现，返回一个`RACEmptySequence`对象。

测试用例：

    - (void)test_empty
    {
        RACSequence *sequence = [RACSequence empty];
        NSLog(@"empty -- %@", sequence);
        
        // 打印日志：
        /*
         2018-08-13 17:36:49.308519+0800 TestRACSequence[91788:11688256] empty -- <RACEmptySequence: 0x60400001cf90>{ name =  }
         */
    }
***

    + (instancetype)return:(id)value {
    	return [RACUnarySequence return:value];
    }
对`RACStream`中方法的实现，由`RACUnarySequence`处理`value`。

测试用例：

    - (void)test_return
    {
        RACSequence *sequence = [RACSequence return:@(1)];
        NSLog(@"return -- %@", sequence);
        
        // 打印日志：
        /*
         2018-08-13 17:38:49.967036+0800 TestRACSequence[91890:11694680] return -- <RACUnarySequence: 0x60400023f580>{ name = , head = 1 }
         */
    }
***

    - (instancetype)bind:(RACStreamBindBlock (^)(void))block {
    	RACStreamBindBlock bindBlock = block();
    	return [[self bind:bindBlock passingThroughValuesFromSequence:nil] setNameWithFormat:@"[%@] -bind:", self.name];
    }
    
    - (instancetype)bind:(RACStreamBindBlock)bindBlock passingThroughValuesFromSequence:(RACSequence *)passthroughSequence {
    	// Store values calculated in the dependency here instead, avoiding any kind
    	// of temporary collection and boxing.
    	//
    	// This relies on the implementation of RACDynamicSequence synchronizing
    	// access to its head, tail, and dependency, and we're only doing it because
    	// we really need the performance.
    	__block RACSequence *valuesSeq = self;
    	__block RACSequence *current = passthroughSequence;
    	__block BOOL stop = NO;
    
    	RACSequence *sequence = [RACDynamicSequence sequenceWithLazyDependency:^ id {
    		while (current.head == nil) {
    			if (stop) return nil;
    
    			// We've exhausted the current sequence, create a sequence from the
    			// next value.
    			id value = valuesSeq.head;
    
    			if (value == nil) {
    				// We've exhausted all the sequences.
    				stop = YES;
    				return nil;
    			}
    
    			current = (id)bindBlock(value, &stop);
    			if (current == nil) {
    				stop = YES;
    				return nil;
    			}
    
    			valuesSeq = valuesSeq.tail;
    		}
    
    		NSCAssert([current isKindOfClass:RACSequence.class], @"-bind: block returned an object that is not a sequence: %@", current);
    		return nil;
    	} headBlock:^(id _) {
    		return current.head;
    	} tailBlock:^ id (id _) {
    		if (stop) return nil;
    
    		return [valuesSeq bind:bindBlock passingThroughValuesFromSequence:current.tail];
    	}];
    
    	sequence.name = self.name;
    	return sequence;
    }
对`RACStream`中方法的实现。主要功能是通过`RACDynamicSequence`的`sequenceWithLazyDependency:headBlock:tailBlock:`方法实现的。现在先看下每个block的含义。
* `dependencyBlock` 先根据`current`的`head`是否存在分条件处理。

    假设`current.head == nil`，就会开始循环，循环中先拿到序列自身的`head`然后做判空处理，为空直接返回`nil`；不为空调用`bindBlock`将序列自身的`value`做转换，如果转换的值不存在，返回`nil`;如果存在，那么序列自身去掉头部，并开始对转换的序列`current`继续循环操作。

* `headBlock` 返回参数序列的头部。
* `tailBlock` 序列自身调用方法本身并以参数序列的尾部为参数。

这里只是单纯对方法表面的分析，具体实现逻辑还是要参考`RACDynamicSequence`代码，所以，后面对`RACDynamicSequence`的分析会重新来看这个方法的作用。

测试用例：

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
***

    - (instancetype)concat:(RACStream *)stream {
    	NSCParameterAssert(stream != nil);
    
    	return [[[RACArraySequence sequenceWithArray:@[ self, stream ] offset:0]
    		flatten]
    		setNameWithFormat:@"[%@] -concat: %@", self.name, stream];
    }
对`RACStream`中方法的实现。通过`RACArraySequence`的`sequenceWithArray:offset`将`self` `stream`组合成一个序列，再通过方法`flatten`最终由`RACSequence`的`bind:`方法返回一个`RACDynamicSequence`序列。

测试用例：

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
***

    - (instancetype)zipWith:(RACSequence *)sequence {
    	NSCParameterAssert(sequence != nil);
    
    	return [[RACSequence
    		sequenceWithHeadBlock:^ id {
    			if (self.head == nil || sequence.head == nil) return nil;
    			return RACTuplePack(self.head, sequence.head);
    		} tailBlock:^ id {
    			if (self.tail == nil || [[RACSequence empty] isEqual:self.tail]) return nil;
    			if (sequence.tail == nil || [[RACSequence empty] isEqual:sequence.tail]) return nil;
    
    			return [self.tail zipWith:sequence.tail];
    		}]
    		setNameWithFormat:@"[%@] -zipWith: %@", self.name, sequence];
    }
对`RACStream`中方法的实现。作用是将两个序列的序列值两两结合成元祖。

测试用例：

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
***

    - (NSArray *)array {
    	NSMutableArray *array = [NSMutableArray array];
    	for (id obj in self) {
    		[array addObject:obj];
    	}
    
    	return [array copy];
    }
通过使用`for in` 循环返回一个`NSMutableArray`对象。

测试用例：

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
***
    - (NSEnumerator *)objectEnumerator {
    	RACSequenceEnumerator *enumerator = [[RACSequenceEnumerator alloc] init];
    	enumerator.sequence = self;
    	return enumerator;
    }
    
    @implementation RACSequenceEnumerator
    
    - (id)nextObject {
    	id object = nil;
    	
    	@synchronized (self) {
    		object = self.sequence.head;
    		self.sequence = self.sequence.tail;
    	}
    	
    	return object;
    }
    
    @end
`objectEnumerator`方法获取一个`RACSequenceEnumerator`对象用于循环。而`RACSequenceEnumerator`中实现了`nextObject`方法，提供了循环下一步的操作。

测试用例：

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
***
    - (RACSignal *)signal {
    	return [[self signalWithScheduler:[RACScheduler scheduler]] setNameWithFormat:@"[%@] -signal", self.name];
    }
    
    - (RACSignal *)signalWithScheduler:(RACScheduler *)scheduler {
    	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
    		__block RACSequence *sequence = self;
    
    		return [scheduler scheduleRecursiveBlock:^(void (^reschedule)(void)) {
    			if (sequence.head == nil) {
    				[subscriber sendCompleted];
    				return;
    			}
    
    			[subscriber sendNext:sequence.head];
    
    			sequence = sequence.tail;
    			reschedule();
    		}];
    	}] setNameWithFormat:@"[%@] -signalWithScheduler: %@", self.name, scheduler];
    }
该方法返回一个`signal`。当该信号被订阅时，通过`RACScheduler`的`scheduleRecursiveBlock`方法将序列的值逐个发送出去。

测试用例：

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
***

    - (id)foldLeftWithStart:(id)start reduce:(id (^)(id, id))reduce {
    	NSCParameterAssert(reduce != NULL);
    
    	if (self.head == nil) return start;
    	
    	for (id value in self) {
    		start = reduce(start, value);
    	}
    	
    	return start;
    }
通过`for`循环将序列的值与`start`做`reduce`运算，并保存结果用于与序列的下个值进行运算，重复此过程直到序列结束。

测试用例：

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
***

    - (id)foldRightWithStart:(id)start reduce:(id (^)(id, RACSequence *))reduce {
    	NSCParameterAssert(reduce != NULL);
    
    	if (self.head == nil) return start;
    	
    	RACSequence *rest = [RACSequence sequenceWithHeadBlock:^{
    		return [self.tail foldRightWithStart:start reduce:reduce];
    	} tailBlock:nil];
    	
    	return reduce(self.head, rest);
    }
通过`sequenceWithHeadBlock`方法实现序列值从尾部开始进行`reduce`运行，最后获取一个结果。这个与`foldLeftWithStart:reduce:`类似，只是上面的方法是从头部开始运算直到尾部。

测试用例：

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
***

    - (BOOL)any:(BOOL (^)(id))block {
    	NSCParameterAssert(block != NULL);
    
    	return [self objectPassingTest:block] != nil;
    }
    
    - (BOOL)all:(BOOL (^)(id))block {
    	NSCParameterAssert(block != NULL);
    	
    	NSNumber *result = [self foldLeftWithStart:@YES reduce:^(NSNumber *accumulator, id value) {
    		return @(accumulator.boolValue && block(value));
    	}];
    	
    	return result.boolValue;
    }
    
    - (id)objectPassingTest:(BOOL (^)(id))block {
    	NSCParameterAssert(block != NULL);
    
    	return [self filter:block].head;
    }
* `objectPassingTest`通过调用父类`RACStream`的`filter`方法筛选，然后调用`head`拿到筛选的值。
* `any:`判断筛选的值是否存在。
* `all:`通过`foldLeftWithStart`进行`block`操作，获取到最后的结果，判断是否所有值都符合`block`条件。

测试用例：

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
***

    - (RACSequence *)eagerSequence {
    	return [RACEagerSequence sequenceWithArray:self.array offset:0];
    }
通过子类`RACEagerSequence`获取到一个热序列。

测试用例：

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
***

    - (RACSequence *)lazySequence {
    	return self;
    }
返回自身，因为自身就是个冷序列。

测试用例：

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
***
下面还有一些方法，由于不涉及到核心逻辑，就不再分析了，有兴趣的看看就好。

###### 后面会对`RACSequence`的子类进行分析。
