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
#import "SyphonMessageReceiver.h"
#import "SyphonMessaging.h"
#import "SyphonCFMessageReceiver.h"
//#import "SyphonMachMessageReceiver.h"

@implementation SyphonMessageReceiver
{
@private
    NSString *_name;
    void (^_handler)(id <NSCoding>, uint32_t);
}

- (id)initForName:(NSString *)name protocol:(NSString *)protocolName handler:(void (^)(id payload, uint32_t type))handler
{
    self = [super init];
    if (self)
	{
		if ([self class] == [SyphonMessageReceiver class])
		{
            [self release];
            if ([protocolName isEqualToString:SyphonMessagingProtocolCFMessage])
			{
                return [[SyphonCFMessageReceiver alloc] initForName:name protocol:protocolName handler:handler];
            }
			/*
			else if ([protocolName isEqualToString:SyphonMessagingProtocolMachMessage])
			{
                return [[SyphonMessageReceiverMachMessage alloc] initForName:name protocol:protocolName handler:handler];
            }
			 */
			else
			{
			    return nil;
            }        
        }
		else
		{
			// SyphonMessageReceiver init here
			if (handler == nil)
			{
				[self release];
				return nil;
			}
			_name = [name copy];
			_handler = [handler copy];
		}
	}
	return self;
}

- (void)invalidate
{
	
}

- (void)dealloc
{
	[_name release];
	[_handler release];
	[super dealloc];
}

- (NSString *)name
{
	return _name;
}

- (void)receiveMessageWithPayload:(id)payload ofType:(uint32_t)type
{
	_handler(payload, type);
}
@end
