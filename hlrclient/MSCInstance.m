//
//  MSCInstance.m
//  hrlclient
//
//  Created by Andreas Fink on 07.11.16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "MSCInstance.h"
#import "MSCSession.h"
#import "MSCSession_SendRoutingInfoForSM.h"
#import <ulibsms/ulibsms.h>
#import "AppDelegate.h"
@implementation MSCInstance


- (NSString *)instancePrefix
{
    return @"M";
}

#pragma mark -
#pragma mark handle incoming components


- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm
{
    UMHTTPAuthenticationStatus status = [super httpAuthenticateRequest:req realm:realm];
    if(status == UMHTTP_AUTHENTICATION_STATUS_PASSED)
    {
        return status;
    }
    if([req.path isEqualToString:@"/msc"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([req.path isEqualToString:@"/msc/"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([req.path isEqualToString:@"/msc/index.html"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    else if([req.path isEqualToString:@"/msc/index.php"])
    {
        return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
    }
    return UMHTTP_AUTHENTICATION_STATUS_FAILED;
}

- (void)  httpGetPost:(UMHTTPRequest *)req
{
    @autoreleasepool
    {
        /* pages requesting auth will have UMHTTP_AUTHENTICATION_STATUS_FAILED or UMHTTP_AUTHENTICATION_STATUS_PASSED
         pages not requiring auth will have UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED */
        
        if(req.authenticationStatus == UMHTTP_AUTHENTICATION_STATUS_FAILED)
        {
            [req setResponsePlainText:@"not-authorization-vlr"];
            [req setRequireAuthentication];
            return;
        }
        /*
         if(![req.connection.socket.connectedRemoteAddress isEqualToString:@"ipv4:localhost"])
         {
         }
         */
        NSDictionary *p = req.params;
        int pcount=0;
        for(NSString *n in p.allKeys)
        {
            if(([n isEqualToString:@"user"])  || ([n isEqualToString:@"pass"]))
            {
                continue;
            }
            pcount++;
        }
        @try
        {
            NSString *path = req.url.relativePath;

            if([path hasSuffix:@".php"])
            {
                path = [path substringToIndex:path.length - 4];
            }
            if([path hasSuffix:@".html"])
            {
                path = [path substringToIndex:path.length - 5];
            }
            if([path hasSuffix:@"/"])
            {
                path = [path substringToIndex:path.length - 1];
            }

            if([path isEqualToStringCaseInsensitive:@"/msc/index"])
            {
                path = @"/msc";
            }

            if([path isEqualToStringCaseInsensitive:@"/msc"])
            {
                [req setResponseHtmlString:[MSCInstance webIndexForm]];
            }
            else if([path isEqualToStringCaseInsensitive:@"/msc/sendRoutingInfoForSM"])
            {
                if(pcount==0)
                {
                    [req setResponseHtmlString:[MSCSession_SendRoutingInfoForSM webForm:0]];
                }
                else
                {
                    MSCSession_SendRoutingInfoForSM *t = [[MSCSession_SendRoutingInfoForSM alloc]initWithHttpReq:req
                                                                                                                instance:self];
                    [self queueFromUpper:t];
                }
            }
        }
        @catch(NSException *e)
        {
            
            NSMutableDictionary *d1 = [[NSMutableDictionary alloc]init];
            if(e.name)
            {
                d1[@"name"] = e.name;
            }
            if(e.reason)
            {
                d1[@"reason"] = e.reason;
            }
            if(e.userInfo)
            {
                d1[@"user-info"] = e.userInfo;
            }
            NSDictionary *d =   @{ @"error" : @{ @"exception": d1 } };
            [req setResponsePlainText:[d jsonString]];
        }
    }
}

+ (NSString *)webIndexForm
{
    static NSMutableString *s = NULL;
    
    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];
    [SS7GenericInstance webHeader:s title:@"MSC"];
    [s appendString:@"<a href=\"/\">main menu</a>\n"];
    [s appendString:@"<h2>MSC Menu</h2>\n"];
    [s appendString:@"<UL>\n"];
    [s appendString:@"<LI><a href=\"/msc/sendRoutingInfoForSM\">sendRoutingInfoForSM</a>\n"];
    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}

-(void) setConfig:(NSDictionary *)cfg applicationContext:(id)appContext
{
    [super setConfig:cfg applicationContext:appContext];
}


- (void)urlLoadCompletedForReference:(id)ref data:(NSData *)data status:(NSInteger)statusCode
{
}

- (void)httpRequestTimeout:(UMHTTPRequest *)req
{
}

@end
