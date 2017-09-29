//
//  Message.c
//  TimeMachineScheduler
//
//  Created by Volodimir Moskaliuk on 9/29/17.
//  Copyright © 2017 Vladymyr Moskalyuk. All rights reserved.
//

#include "Message.h"
#include <errno.h>
#include <poll.h>
#include <syslog.h>
#include <unistd.h>
#include <sys/socket.h>
#include <string.h>

#define MAX_PATH_SIZE 128

// return 0 - yes / 1 - no
int readBytes(int size, int fd, unsigned char *buffer)
{
	int bytesLeft = size;
	unsigned char *pointer = buffer;
	struct pollfd fds;
	fds.fd = fd;
	fds.events = POLLIN;
	
	while (0 < bytesLeft) {
		int bytesReady = poll(&fds, 1, 1000); // wait one second
		if(bytesReady == -1)
		{
			syslog(LOG_NOTICE, "poll() error = %d\n", errno);
			return 1;
		}
		if(bytesReady == 0)
		{
			syslog(LOG_NOTICE, "no data available on soket");
			return 1;
		}
		ssize_t bytesRead = read(fd, pointer, bytesLeft);
		if(bytesRead == 0)
		{
			syslog(LOG_NOTICE, "poll() said that data was available but we didn't get any!");
			return 1;
		}
		bytesLeft -= bytesRead;
		pointer += bytesRead;
	}
	return 0;
}

int readMessage(int fd, struct TimeMachineSchedullerMessage * message)
{
	if(readBytes(1, fd, &(message->version)))
	{
		return 1;
	}
	if(message->version != kMessageVersion)
	{
		syslog(LOG_NOTICE, "expected message format version %i but got %i", kMessageVersion, message->version);
		return 1;
	}
	if(readBytes(1, fd, &(message->command)))
	{
		return 1;
	}
	if(readBytes(1, fd, &(message->dataSize)))
	{
		return 1;
	}
	return readBytes(message->dataSize, fd, message->data);
}

int sendMessage(const struct TimeMachineSchedullerMessage * messageOut, struct TimeMachineSchedullerMessage * messageIn) {
	int socket_fd = socket(PF_UNIX, SOCK_STREAM, 0);
	if(socket_fd == -1) {
		syslog(LOG_ERR, "socket() failed");
		return 1;
	}
	
	int size = sizeof(struct sockaddr) + MAX_PATH_SIZE;
	char address_data[size];
	struct sockaddr *address = (struct sockaddr*) &address_data;
	address->sa_len = size;
	address->sa_family = AF_UNIX;
	strncpy(address->sa_data, kSocketPath, MAX_PATH_SIZE);
	if(connect(socket_fd, address, size) == -1) {
		syslog(LOG_ERR, "Socket connect() failed");
		return 1;
	}
	int bytesCount = messageSize(messageOut);
	size_t bytesWritten = write(socket_fd, messageOut, bytesCount);
	if(bytesCount != bytesWritten) {
		syslog(LOG_ERR, "tried to write %i, but wrote %zu", bytesCount, bytesWritten);
		close(socket_fd);
		return 1;
	}
	if(readMessage(socket_fd, messageIn)) {
		syslog(LOG_ERR, "Error reading from socket");
		close(socket_fd);
		return 1;
	}
	close(socket_fd);
	return 0;
}

bool isCurrentVersion() {
	struct TimeMachineSchedullerMessage messageOut, messageIn;
	initMessage(messageOut, TMS_Version)
	if(sendMessage(&messageOut, &messageIn)) return false;
	return messageIn.command = kMessageVersion
		&& messageIn.data[0] == kVersionPart1
		&& messageIn.data[1] == kVersionPart2
		&& messageIn.data[2] == kVersionPart3;
}
