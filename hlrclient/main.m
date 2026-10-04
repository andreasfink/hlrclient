//
//  main.m
//  hlrclient
//
//  Created by Andreas Fink on 09.04.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibss7config/ulibss7config.h>
#import "AppDelegate.h"

AppDelegate *g_app_delegate = NULL;

int main(int argc, const char * argv[]);

int main(int argc, const char * argv[])
{
    g_app_delegate = [[AppDelegate alloc]init];
    return [g_app_delegate main:argc argv:argv];
}


