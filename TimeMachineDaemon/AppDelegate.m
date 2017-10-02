//
//  AppDelegate.m
//  TimeMachineDaemon
//
//  Created by Volodimir Moskaliuk on 10/2/17.
//  Copyright © 2017 Vladymyr Moskalyuk. All rights reserved.
//

#import "AppDelegate.h"
#import "Message.h"
@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	struct TimeMachineSchedullerMessage messageOut, messageIn;
	initMessage(messageOut, TMS_FORCE_BACKUP);
	if(sendMessage(&messageOut, &messageIn)) {
		exit(1);
	}
	int result;
	memcpy(&result, messageIn.data, sizeof(result));
	NSLog(@"result is %i", result);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


@end
