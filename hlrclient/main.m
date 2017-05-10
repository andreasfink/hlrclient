//
//  main.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

#import <stdlib.h>
#import <unistd.h>
#import <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>

#import "AppDelegate.h"

#ifdef __APPLE__
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#endif

AppDelegate *g_app_delegate;

int parachute_launch(int argc, const char *argv[]);
int main(int argc,  const char * argv[]);
static const char *g_config_file_name ="/etc/hlrclient/hlrclient.conf";

time_t g_startup_time = 0;
int must_quit = 0;

int main(int argc, const char * argv[])
{
    time_t	tim;
    char	state_array[16];

    [NSUserDefaults standardUserDefaults];

    tim = time(&g_startup_time);
    initstate((unsigned  int)tim,  state_array,  16);

    if(argc>1)
    {
        g_config_file_name = argv[1];
    }
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

    @autoreleasepool
    {
        g_app_delegate = [[AppDelegate alloc]init];
        [g_app_delegate readConfigFile:@(g_config_file_name)];
        NSLog(@"Starting up");
        [NSOperationQueue mainQueue];
        [g_app_delegate applicationDidFinishLaunching:NULL];
    }

    while(must_quit==0)
    {
        @autoreleasepool
        {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    @autoreleasepool
    {
        NSLog(@"******************* SYSTEM TERMINATING *******************");
    }
    return 0;
}


