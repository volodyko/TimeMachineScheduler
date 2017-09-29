//
//  Message.h
//  TimeMachineScheduler
//
//  Created by Volodimir Moskaliuk on 9/29/17.
//  Copyright © 2017 Vladymyr Moskalyuk. All rights reserved.
//

#ifndef Message_h
#define Message_h

#include <stdbool.h>

#define kSocketPath "/var/run/com.volodyko.TimeMachineSchedulerHelper.socket"
#define kHelperIdentifier "com.volodyko.TimeMachineSchedulerHelper"
#define kVersionPart1 1
#define kVersionPart2 0
#define kVersionPart3 0

enum TimeMachineSchedulerCommand
{
	TMS_Error = 0,
	TMS_Version = 1,
	TMS_PID = 2,
};

//This command structure version
#define kMessageVersion 1

struct TimeMachineSchedullerMessage
{
	unsigned char version; //kMessageVersion
	unsigned char command; //TimeMachineSchedulerCommand
	unsigned char dataSize; // 0 to 252
	unsigned char data [252]; //command data
};

#define messageSize(message_p) sizeof(*message_p) - sizeof((message_p)->data) + (message_p)->dataSize
#define initMessage(m, c) { m.version = kMessageVersion; m.command = c; m.dataSize = 0; }

int readMessage(int fd, struct TimeMachineSchedullerMessage * message);
int sendMessage(const struct TimeMachineSchedullerMessage * messageOut, struct TimeMachineSchedullerMessage * messageIn);
bool isCurrentVersion(void);

#endif /* Message_h */
