/*
    SyphonMessageReceiver.m
    Syphon

    Copyright 2010-2011 bangnoise (Tom Butterworth) & vade (Anton Marini).
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "Syphon_Prefix.pch"
#import "SyphonCFMessageReceiver.h"
#import "SyphonMessaging.h"
#import <libkern/OSAtomic.h>

static dispatch_queue_t theQueue = NULL;
static int theCount = 0;

static CFDataRef MessageReturnCallback (
								 CFMessagePortRef local,
								 SInt32 msgid,
								 CFDataRef data,
								 void *info
								 )
{
	id <NSCoding> decoded;
	if (data && CFDataGetLength(data))
	{
		decoded = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)data];
	} else {
		decoded = nil;
	}
	[(SyphonMessageReceiver *)info receiveMessageWithPayload:decoded ofType:msgid];
	return NULL;
}

@implementation SyphonCFMessageReceiver
{
@private
    CFMessagePortRef _port;
}

+ (dispatch_queue_t)addUser
{
    @synchronized(self) {
        theCount++;
        if (!theQueue)
        {
            dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, -1);
            theQueue = dispatch_queue_create("info.v002.syphon.messaging", attributes);
        }
    }
    return theQueue;
}

+ (void)endUser
{
    @synchronized(self) {
        theCount--;
        if (theCount == 0)
        {
            dispatch_release(theQueue);
            theQueue = NULL;
        }
    }
}

- (id)initForName:(NSString *)name protocol:(NSString *)protocolName handler:(void (^)(id data, uint32_t type))handler
{
    self = [super initForName:name protocol:protocolName handler:handler];
	if (self)
	{
		if ([protocolName isEqualToString:SyphonMessagingProtocolCFMessage])
		{
			CFMessagePortContext context = (CFMessagePortContext){0,self,NULL,NULL,NULL};
			_port = CFMessagePortCreateLocal(kCFAllocatorDefault, (CFStringRef)name, MessageReturnCallback, &context, NULL);
		}
		if (_port == NULL)
		{
			[self release];
			return nil;
		}
        CFMessagePortSetDispatchQueue(_port, [[self class] addUser]);
	}
	return self;
}

- (void)dealloc
{
	if (_port) CFRelease(_port);
	[super dealloc];
}

- (void)invalidate
{
	if (_port)
    {
        CFMessagePortInvalidate(_port);
        // we only called addUser if _port was created
        [[self class] endUser];
    }
    [super invalidate];
}
@end
