/** @file XLoader.m
 内部使用NSOperationQueue来实现多线程操作
 */

#import "XLoader.h"
#include <libkern/OSAtomic.h>

/// 仅供内部使用
@interface XLoaderTask:NSObject
{
	int	m_atomic;	//用于同步
	BOOL isRemoved;	//如果此值为TRUE，则表示已经卸载了这个对象。相当于已经针对这个对象调用了unloadObject:
}
@property (nonatomic,strong) id (^loadObject)();
@property (nonatomic,retain) id	key;
@property (nonatomic,retain) id	object;
@property (atomic,assign) BOOL isRemoved;
-(BOOL) load;
@end
@implementation XLoaderTask
@synthesize key;
@synthesize object;
@synthesize loadObject;

-(BOOL) isRemoved
{
	BOOL ret;
	while(OSAtomicCompareAndSwapInt(0, 1, &m_atomic)==false);
	ret = isRemoved;
	while(OSAtomicCompareAndSwapInt(1, 0, &m_atomic)==false);
	return ret;
}
-(void) setIsRemoved:(BOOL)remove
{
	while(OSAtomicCompareAndSwapInt(0, 1, &m_atomic)==false);
	isRemoved = remove;
	while(OSAtomicCompareAndSwapInt(1, 0, &m_atomic)==false);
}
-(BOOL) load
{
	object = loadObject(key);
	if(object)
		return TRUE;
	return FALSE;
}
@end

@interface XLoader(hidden)
+(NSOperationQueue*) xLoaderTaskQueue;
-(void) taskLoadObject:(XLoaderTask*)loaderUnitHidden;
-(void) objectLoaded:(XLoaderTask*)loaderUnitHidden;
-(void) loadFailed:(XLoaderTask*)loaderUnitHidden;
@end

static NSOperationQueue* g_xLoaderTaskQueue	= nil;
@implementation XLoader(hidden)

+(NSOperationQueue*) xLoaderTaskQueue
{
	if(g_xLoaderTaskQueue==nil)
	{
		@synchronized(g_xLoaderTaskQueue)
		{
			if(g_xLoaderTaskQueue==nil)
			{
				g_xLoaderTaskQueue	= [[NSOperationQueue alloc] init];
				g_xLoaderTaskQueue.maxConcurrentOperationCount = 2;
			}
		}
	}
	return g_xLoaderTaskQueue;
}
-(void) taskLoadObject:(XLoaderTask *)task
{
	if(task.isRemoved)
	{
		return;
	}
	BOOL success = [task load];
	if(task.isRemoved)
	{
		return;
	}
	if(success)
		[self performSelectorOnMainThread:@selector(objectLoaded:) withObject:task waitUntilDone:NO];
	else
		[self performSelectorOnMainThread:@selector(loadFailed:) withObject:task waitUntilDone:NO];
}
-(void) objectLoaded:(XLoaderTask*)task
{
	[locker lock];
	[dicTasks removeObjectForKey:task.key];
	[locker unlock];
	if(task.isRemoved)
	{
		return;
	}
	if([delegate respondsToSelector:@selector(loader:loadedObject:forKey:)])
		[delegate loader:self loadedObject:task.object forKey:task.key];
}
-(void) loadFailed:(XLoaderTask*)task;
{
	[locker lock];
	[dicTasks removeObjectForKey:task.key];
	[locker unlock];
	if(task.isRemoved)
		return;
	if([delegate respondsToSelector:@selector(loader:loadFailedForKey:)])
		[delegate loader:self loadFailedForKey:task.key];
}

@end

static XLoader* hidden_DefaultXLoder = nil;

@implementation XLoader
@synthesize delegate;

-(id) init
{
	if((self = [super init]))
	{
		locker	= [[NSLock alloc] init];
		dicTasks	= [[NSMutableDictionary alloc] init];
	}
	return self;
}

+(XLoader*)loader
{
	if(hidden_DefaultXLoder==nil)
	{
		@synchronized(hidden_DefaultXLoder)
		{
			if(hidden_DefaultXLoder==nil)
			{
				hidden_DefaultXLoder = [[XLoader alloc] init];
			}
		}
	}
	return hidden_DefaultXLoder;
}

-(void) load:(id (^)())loadObject forKey:(id)key
{
	if(key==nil || loadObject==nil)
		return;
	[locker lock];

	XLoaderTask* oldTask	= [dicTasks objectForKey:key];
	if(oldTask)
	{
		[locker unlock];
		return;
	}

	XLoaderTask* loadTask	= [[XLoaderTask alloc] init];
	loadTask.key	= key;
	loadTask.loadObject	= loadObject;
	[dicTasks setObject:loadTask forKey:key];

	NSInvocationOperation* op	= [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(taskLoadObject:) object:loadTask];
	[[XLoader xLoaderTaskQueue] addOperation:op];

	[locker unlock];
}

-(void) cancelLoadingObjectByKey:(id)key
{
	[locker lock];
	XLoaderTask* task	= [dicTasks objectForKey:key];
	if(task)
	{
		task.isRemoved	= TRUE;
		[dicTasks removeObjectForKey:key];
	}
	[locker unlock];
}

-(void) cancelLoadingAllObjects
{
	[locker lock];
	NSEnumerator *enumerator = [dicTasks objectEnumerator];
	XLoaderTask* task;
	while ((task = [enumerator nextObject]))
	{
		task.isRemoved	= TRUE;
	}
	[dicTasks removeAllObjects];
	[locker unlock];
}

@end
