//
//  main.m
//  TimeMachineHelper
//
//  Created by Vladymyr Moskalyuk on 9/28/17.
//  Copyright © 2017 Vladymyr Moskalyuk. All rights reserved.
//

#include <syslog.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
	@autoreleasepool {
	    // insert code here...
		syslog(LOG_NOTICE, "Hello world! uid = %d, euid = %d, pid = %d\n", (int) getuid(), (int) geteuid(), (int) getpid());
		(void) sleep(10);
	}
	return EXIT_SUCCESS;

}
