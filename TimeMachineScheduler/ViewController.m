//
//  ViewController.m
//  TimeMachineScheduler
//
//  Created by Vladymyr Moskalyuk on 9/28/17.
//  Copyright © 2017 Vladymyr Moskalyuk. All rights reserved.
//

#import "ViewController.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import "Message.h"

@interface ViewController()

@property(nonatomic, assign) AuthorizationRef authRef;
@property (weak) IBOutlet NSTextField *connectionStatus;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSError *error = nil;

	if (![self blessHelperWithLabel:@kHelperIdentifier error:&error])
	{
		NSString *errorString = [NSString stringWithFormat:@"Something went wrong! %@ / %d", [error domain], (int) [error code] ];
		NSLog(@"%@", errorString);
		[self.connectionStatus setStringValue:errorString];
	}
	else
	{
		/* At this point, the job is available. However, this is a very
		 * simple sample, and there is no IPC infrastructure set up to
		 * make it launch-on-demand. You would normally achieve this by
		 * using XPC (via a MachServices dictionary in your launchd.plist).
		 */
		NSLog(@"Job is available!");
		[self.connectionStatus setStringValue:@"Job is available!"];
		
		[self.connectionStatus setHidden:false];
	}
	// Do any additional setup after loading the view.
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr;
{
	BOOL socketExist = [[NSFileManager defaultManager] fileExistsAtPath:@kSocketPath];
	if(socketExist && isCurrentVersion())
	{
		NSLog(@"Socket exist and current version is: %d.%d.%d", kVersionPart1, kVersionPart2, kVersionPart3);
		return YES;
	}
	
	BOOL result = NO;
	NSError * error = nil;
	
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags        =	kAuthorizationFlagDefaults |
										kAuthorizationFlagInteractionAllowed |
										kAuthorizationFlagPreAuthorize |
										kAuthorizationFlagExtendRights;
	
	/* Obtain the right to install our privileged helper tool (kSMRightBlessPrivilegedHelper). */
	OSStatus status = AuthorizationCreate( &authRights, kAuthorizationEmptyEnvironment, flags, &_authRef);
	if (status != errAuthorizationSuccess)
	{
		error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
	}
	else
	{
		CFErrorRef  cfError;
		
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		result = (BOOL) SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, self->_authRef, &cfError);
		
		if (!result)
		{
			error = CFBridgingRelease(cfError);
		}
	}
	
	if ( ! result && (errorPtr != NULL) )
	{
		assert(error != nil);
		*errorPtr = error;
	}
	
	return result;
}


- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

- (IBAction)setTimeMachineInterval:(id)sender {
	struct TimeMachineSchedullerMessage messageOut, messageIn;
	initMessage(messageOut, TMS_PID);
	if(sendMessage(&messageOut, &messageIn)) {
		NSLog(@"Error send message");
	}
	int pid;
	memcpy(&pid, messageIn.data, sizeof(pid));
	NSLog(@"Helper PID is %i", pid);
}

@end
