//
//  NSManagedObjectContext+MagicalThreading.m
//  Magical Record
//
//  Created by Saul Mora on 3/9/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import <objc/runtime.h>
#import "NSManagedObjectContext+MagicalThreading.h"
#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"

static NSString const * kMagicalRecordManagedObjectContextKey = @"MagicalRecord_NSManagedObjectContextForThreadKey";
static char *cdQueueKey;

@implementation NSManagedObjectContext (MagicalThreading)

+ (void)MR_resetContextForCurrentThread
{
    [[NSManagedObjectContext MR_contextForCurrentThread] reset];
}

+ (NSManagedObjectContext *) MR_contextForCurrentThread;
{
	if ([NSThread isMainThread])
	{
		return [self MR_defaultContext];
	}
	else
	{
        const char *qName = dispatch_queue_get_label(dispatch_get_current_queue());
        NSString *queueName = [NSString stringWithCString:qName encoding:NSUTF8StringEncoding];
        if ([queueName isEqualToString:@"CoreData"]) {
            return [NSManagedObjectContext HAW_contextForCoreDataQueue];
        }
        
		NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext *threadContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextKey];
		if (threadContext == nil)
		{
			threadContext = [self MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
			[threadDict setObject:threadContext forKey:kMagicalRecordManagedObjectContextKey];
		}
		return threadContext;
	}
}

+ (NSManagedObjectContext *) HAW_contextForCoreDataQueue {
    NSManagedObjectContext *ctx = objc_getAssociatedObject(self, &cdQueueKey);
    if (ctx == nil) {
        ctx = [self MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
        objc_setAssociatedObject(self, &cdQueueKey, ctx, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ctx;
}

@end
