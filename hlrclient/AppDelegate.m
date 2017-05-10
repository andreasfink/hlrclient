//
//  AppDelegate.m
//  hlrclient
//
//  Created by Andreas Fink on 10.05.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "AppDelegate.h"
#import <ulibgsmmap/ulibgsmmap.h>
#import "MSCInstance.h"


#define CONFIG_ERROR(s)     [NSException exceptionWithName:[NSString stringWithFormat:@"CONFIG_ERROR FILE %s line:%ld",__FILE__,(long)__LINE__] reason:s userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]

@implementation AppDelegate

- (AppDelegate *)init
{
    self = [super init];
    if(self)
    {
        logHandler = [[UMLogHandler alloc]initWithConsole];
        stdLogFeed = [[UMLogFeed alloc]initWithHandler:logHandler];
        taskQueue = [[UMTaskQueueMulti alloc]initWithNumberOfThreads:8
                                                                name:@"main-task-queue"
                                                       enableLogging:NO
                                                      numberOfQueues:UMLAYER_QUEUE_COUNT];
        sctp_dict           = [[UMSynchronizedDictionary alloc]init];
        m2pa_dict           = [[UMSynchronizedDictionary alloc]init];
        mtp3_dict           = [[UMSynchronizedDictionary alloc]init];
        m3ua_as_dict        = [[UMSynchronizedDictionary alloc]init];
        m3ua_asp_dict       = [[UMSynchronizedDictionary alloc]init];
        sccp_dict           = [[UMSynchronizedDictionary alloc]init];
        sccp_next_hop_dict  = [[UMSynchronizedDictionary alloc]init];
        tcap_dict           = [[UMSynchronizedDictionary alloc]init];
        mtp3_link_dict      = [[UMSynchronizedDictionary alloc]init];
        mtp3_linkset_dict   = [[UMSynchronizedDictionary alloc]init];
        gsmmap_dict         = [[UMSynchronizedDictionary alloc]init];
        msc_dict            = [[UMSynchronizedDictionary alloc]init];

        tidPool = [[UMTCAP_TransactionIdPool alloc]initWithPrefabricatedIds:100000];
    }
    return self;
}

- (UMLogFeed *)logFeed
{
    return stdLogFeed;
}

static BOOL isRunningTests(void)
{
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    NSString* injectBundle = environment[@"XCInjectBundle"];
    return [[injectBundle pathExtension] isEqualToString:@"xctest"]; // For SenTestKit; use "xctest" for XCTest
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (isRunningTests())
    {
        NSLog(@"Running tests");
    }
    NSArray *keys = [mtp3_dict allKeys];
    for (NSString *key in keys)
    {
        UMLayerMTP3 *mtp3 = mtp3_dict[key];
        [mtp3 start];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (void)applicationGoToHot
{

}
- (void)applicationGoToStandby
{

}

- (void)  httpGetPost:(UMHTTPRequest *)req
{
    @autoreleasepool
    {
        NSString *path = req.url.relativePath;
        if([path hasPrefix:@"/msc"])
        {
            [mainMscInstance httpGetPost:req];
        }
        else if([path isEqualToString:@"/status"])
        {
            [self handleStatus:req];
        }
        else if([path isEqualToString:@"/"])
        {
            NSString *s = [self webIndex];
            [req setResponseHtmlString:s];
        }
        else if([path isEqualToString:@"/css/style.css"])
        {
            [req setResponseCssString:[AppDelegate css]];
        }
        else
        {
            NSString *s = @"Result: Error\nReason: Unknown request\n";
            [req setResponseTypeText];
            req.responseData = [s dataUsingEncoding:NSUTF8StringEncoding];
            req.responseCode =  404;
        }
    }
}

- (NSString *)webIndex
{
    static NSMutableString *s = NULL;
    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];

    [s appendString:@"<html>\n"];
    [s appendString:@"<header>\n"];
    [s appendString:@"    <link rel=\"stylesheet\" href=\"/css/style.css\" type=\"text/css\">\n"];
    [s appendFormat:@"    <title>HLR Client</title>\n"];
    [s appendString:@"</header>\n"];
    [s appendString:@"<body>\n"];

    [s appendString:@"<h2>HLR Client</h2>\n"];
    [s appendString:@"<UL>\n"];
    [s appendString:@"<LI><a href=\"/msc/sendRoutingInfoForSM\">sendRoutingInfoForSM</a></LI>\n"];
    [s appendString:@"<LI><a href=\"/status\">status</a></LI>\n"];
    [s appendString:@"</UL>\n"];
    [s appendString:@"</body>\n"];
    [s appendString:@"</html>\n"];
    return s;
}

- (void)readConfigFile:(NSString *)filename
{
    config = [[UMConfig alloc]initWithFileName:filename];
    [config allowMultiGroup:@"sctp"];
    [config allowMultiGroup:@"m2pa"];
    [config allowMultiGroup:@"mtp3"];
    [config allowMultiGroup:@"mtp3-linkset"];
    [config allowMultiGroup:@"mtp3-link"];
    [config allowMultiGroup:@"sccp"];
    [config allowMultiGroup:@"sccp-next-hop"];
    [config allowMultiGroup:@"sccp-route"];
    [config allowMultiGroup:@"tcap"];
    [config allowMultiGroup:@"gsmmap"];
    [config allowMultiGroup:@"webserver"];
    [config allowMultiGroup:@"msc"];
    [config allowMultiGroup:@"m3ua-asp"];
    [config allowMultiGroup:@"m3ua-as"];
    [config allowMultiGroup:@"mtp3-route"];
    [config read];

    NSArray *sctp_configs = [config getMultiGroups:@"sctp"];
    for(NSDictionary *sctp_config in sctp_configs)
    {
        if( [sctp_config configEnabledWithYesDefault])
        {
            NSString *name = [sctp_config configName];
            if(name)
            {
                UMLayerSctp *sctp = [[UMLayerSctp alloc]initWithTaskQueueMulti:taskQueue];
                sctp.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"sctp"];
                sctp.logFeed.name = name;
                [sctp setConfig:sctp_config applicationContext:self];
                sctp_dict[name] = sctp;
            }
            else
            {
                @throw(CONFIG_ERROR(@"SCTP config without a name"));
            }
        }
    }

    NSArray *m2pa_configs = [config getMultiGroups:@"m2pa"];
    for(NSDictionary *m2pa_config in m2pa_configs)
    {
        if([m2pa_config configEnabledWithYesDefault])
        {
            NSString *name = [m2pa_config configName];
            if(name)
            {
                UMLayerM2PA *m2pa = [[UMLayerM2PA alloc]initWithTaskQueueMulti:taskQueue];
                m2pa.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"m2pa"];
                m2pa.logFeed.name = name;
                [m2pa setConfig:m2pa_config applicationContext:self];
                m2pa_dict[name] = m2pa;
            }
            else
            {
                @throw(CONFIG_ERROR(@"M2PA config without a name"));
            }
        }
    }

    NSArray *mtp3_configs = [config getMultiGroups:@"mtp3"];
    for(NSDictionary *mtp3_config in mtp3_configs)
    {
        if([mtp3_config configEnabledWithYesDefault])
        {
            NSString *name = [mtp3_config configName];
            if(name)
            {
                UMLayerMTP3 *mtp3 = [[UMLayerMTP3 alloc]initWithTaskQueueMulti:taskQueue];
                mtp3.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"mtp3"];
                mtp3.logFeed.name = name;
                [mtp3 setConfig:mtp3_config applicationContext:self];
                mtp3_dict[name] = mtp3;
            }
            else
            {
                @throw(CONFIG_ERROR(@"MTP3 config without a name"));
            }
        }
    }

    NSArray *mtp3_linkset_configs = [config getMultiGroups:@"mtp3-linkset"];
    for(NSDictionary *mtp3_linkset_config in mtp3_linkset_configs)
    {
        if([mtp3_linkset_config configEnabledWithYesDefault])
        {
            NSString *name = [mtp3_linkset_config configName];
            if(name)
            {
                UMMTP3LinkSet *linkset = [[UMMTP3LinkSet alloc]init];
                linkset.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"mtp3-linkset"];
                linkset.logFeed.name = name;
                [linkset setConfig:mtp3_linkset_config applicationContext:self];
                [linkset.mtp3 addLinkset:linkset];
                mtp3_linkset_dict[name] = linkset;
            }
            else
            {
                @throw(CONFIG_ERROR(@"MTP3-LINKSET config without a name"));
            }
        }
    }

    NSArray *mtp3_link_configs = [config getMultiGroups:@"mtp3-link"];
    for(NSDictionary *mtp3_link_config in mtp3_link_configs)
    {
        if([mtp3_link_config configEnabledWithYesDefault])
        {
            NSString *name = [mtp3_link_config configName];
            if(name)
            {
                UMMTP3Link *link = [[UMMTP3Link alloc]init];
                link.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"mtp3-link"];
                link.logFeed.name = name;
                [link setConfig:mtp3_link_config applicationContext:self];
                mtp3_link_dict[name] = link;

                NSString *attachTo = mtp3_link_config[@"attach-to"];
                UMLayerM2PA *m2pa  = m2pa_dict[attachTo];
                if(m2pa == NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"Can not find m2pa layer '%@' referred from mtp3 link '%@'",attachTo,name];
                    @throw(CONFIG_ERROR(s));
                }
                link.m2pa = m2pa;

                NSString *linksetName = mtp3_link_config[@"linkset"];
                UMMTP3LinkSet *linkset  = mtp3_linkset_dict[linksetName];
                if(linkset == NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"Can not find linkset '%@' referred from mtp3 link '%@'",linksetName,name];
                    @throw(CONFIG_ERROR(s));
                }
                [linkset addLink:link];
                [link attach];
            }
            else
            {
                @throw(CONFIG_ERROR(@"MTP3-LINK config without a name"));
            }
        }
    }


    NSArray *m3ua_as_configs = [config getMultiGroups:@"m3ua-as"];
    for(NSDictionary *m3ua_as_config in m3ua_as_configs)
    {
        if([m3ua_as_config configEnabledWithYesDefault])
        {
            NSString *name = [m3ua_as_config configName];
            if(name)
            {
                UMM3UAApplicationServer *m3ua_as = [[UMM3UAApplicationServer alloc]init];
                m3ua_as.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"m3ua-as"];
                m3ua_as.logFeed.name = name;
                [m3ua_as setDefaultValues];
                [m3ua_as setConfig:m3ua_as_config applicationContext:self];
                [m3ua_as setDefaultValuesFromMTP3];
                [m3ua_as.mtp3 addLinkset:m3ua_as];
                m3ua_as_dict[name] = m3ua_as;
            }
            else
            {
                @throw(CONFIG_ERROR(@"M3UA-AS config without a name"));
            }
        }
    }

    NSArray *m3ua_asp_configs = [config getMultiGroups:@"m3ua-asp"];
    for(NSDictionary *m3ua_asp_config in m3ua_asp_configs)
    {
        if([m3ua_asp_config configEnabledWithYesDefault])
        {
            NSString *name = [m3ua_asp_config configName];
            if(name)
            {
                UMM3UAApplicationServerProcess *m3ua_asp = [[UMM3UAApplicationServerProcess alloc]init];
                m3ua_asp.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"m3ua-asp"];
                m3ua_asp.logFeed.name = name;
                [m3ua_asp setConfig:m3ua_asp_config applicationContext:self];
                [m3ua_asp.as addAsp:m3ua_asp];
                m3ua_asp_dict[name] = m3ua_asp;
            }
            else
            {
                @throw(CONFIG_ERROR(@"M3UA-ASP config without a name"));
            }
        }
    }

    NSArray *mtp3_route_configs = [config getMultiGroups:@"mtp3-route"];
    for(NSDictionary *mtp3_route_config in mtp3_route_configs)
    {
        if([mtp3_route_config configEnabledWithYesDefault])
        {
            NSString *instance = [mtp3_route_config configEntry:@"mtp3"];
            NSString *route = [mtp3_route_config configEntry:@"route"];
            NSString *linkset = [mtp3_route_config configEntry:@"linkset"];
            UMLayerMTP3 *mtp3_instance = [self getMTP3:instance];
            if(mtp3_instance == NULL)
            {
                @throw(CONFIG_ERROR(@"MTP3-ROUTE instance not found"));
            }

            UMMTP3LinkSet *mtp3_linkset = [mtp3_instance getLinksetByName:linkset];
            if(mtp3_linkset == NULL)
            {
                @throw(CONFIG_ERROR(@"MTP3-ROUTE linkset not found in instance"));
            }

            NSArray *a = [route componentsSeparatedByString:@"/"];
            if([a count] == 1)
            {
                UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:a[0] variant:mtp3_instance.variant];
                [mtp3_linkset.routingTable updateRouteAvailable:pc mask:0 linksetName:linkset];
            }
            else if([a count]==2)
            {
                UMMTP3PointCode *pc = [[UMMTP3PointCode alloc]initWithString:a[0] variant:mtp3_instance.variant];
                [mtp3_linkset.routingTable updateRouteAvailable:pc mask:(pc.maxmask - [a[1] intValue]) linksetName:linkset];
            }
            else
            {
                @throw(CONFIG_ERROR(@"MTP3-ROUTE too many slashes in route"));
            }
        }
    }

    NSArray *sccp_configs = [config getMultiGroups:@"sccp"];
    for(NSDictionary *sccp_config in sccp_configs)
    {
        if([sccp_config configEnabledWithYesDefault])
        {
            NSString *name = [sccp_config configName];
            if(name)
            {
                UMLayerSCCP *sccp = [[UMLayerSCCP alloc]initWithTaskQueueMulti:taskQueue];
                sccp.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"sccp"];
                sccp.logFeed.name = name;
                [sccp setConfig:sccp_config applicationContext:self];
                sccp_dict[name] = sccp;
            }
            else
            {
                @throw(CONFIG_ERROR(@"SCCP config without a name"));
            }
        }
    }

    NSArray *scpp_next_hop_configs = [config getMultiGroups:@"sccp-next-hop"];
    for(NSDictionary *scpp_next_hop_config in scpp_next_hop_configs)
    {
        if([scpp_next_hop_config configEnabledWithYesDefault])
        {
            NSString *name = [scpp_next_hop_config configName];
            NSString *sccp_name = [scpp_next_hop_config configEntry:@"sccp"];
            NSString *mtp3_name = [scpp_next_hop_config configEntry:@"attach-to"];
            NSString *dpc_string = [scpp_next_hop_config configEntry:@"dpc"];
            UMLayerMTP3 *mtp3 = mtp3_dict[mtp3_name];
            if(mtp3 == NULL)
            {
                NSString *s = [NSString stringWithFormat:@"Can not find mtp3 layer '%@' referred from sccp-next-hop '%@'",mtp3_name,name];
                @throw(CONFIG_ERROR(s));
            }
            UMLayerSCCP *sccp = sccp_dict[sccp_name];
            if(sccp == NULL)
            {
                NSString *s = [NSString stringWithFormat:@"Can not find sccp layer '%@' referred from sccp-next-hop '%@'",sccp_name,name];
                @throw(CONFIG_ERROR(s));
            }

            SccpL3Provider *l3provider = [[SccpL3Provider alloc]init];
            l3provider.name = mtp3_name;
            l3provider.variant = mtp3.variant;
            l3provider.mtp3Layer = mtp3;
            l3provider.opc = sccp.attachedTo.opc;

            SccpNextHop *nextHop = [[SccpNextHop alloc]init];
            nextHop.dpc = [[UMMTP3PointCode alloc]initWithString:dpc_string variant:mtp3.variant];
            nextHop.provider = l3provider;
            nextHop.name = name;
            sccp_next_hop_dict[name] = nextHop;
        }
    }


    NSArray *scpp_route_configs = [config getMultiGroups:@"sccp-route"];
    for(NSDictionary *scpp_route_config in scpp_route_configs)
    {
        if([scpp_route_config configEnabledWithYesDefault])
        {
            NSString *name = [scpp_route_config configName];
            if(name)
            {
                NSString *sccp_name = [scpp_route_config configEntry:@"sccp"];
                UMLayerSCCP *sccp = sccp_dict[sccp_name];
                if(sccp == NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"Can not find sccp layer '%@' referred from sccp-route '%@'",sccp_name,name];
                    @throw(CONFIG_ERROR(s));
                }

                NSString *sccp_next_hop_name = [scpp_route_config configEntry:@"next-hop"];
                SccpNextHop *nextHop = sccp_next_hop_dict[sccp_next_hop_name];
                if(nextHop==NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"next-hop '%@' is not found for sccp-route '%@'",sccp_next_hop_name,name];
                    @throw(CONFIG_ERROR(s));
                }
                if ([[scpp_route_config configEntry:@"default"] boolValue]!=YES)
                {
                    NSString *s = [NSString stringWithFormat:@"currently only default=YES is implemented for sccp-route '%@'",name];
                    @throw(CONFIG_ERROR(s));
                }
                else
                {
                    sccp.defaultNextHop = nextHop;
                }
            }
            else
            {
                @throw(CONFIG_ERROR(@"SCCP-ROUTE config without a name"));
            }
        }
    }

    NSArray *tcap_configs = [config getMultiGroups:@"tcap"];
    for(NSDictionary *tcap_config in tcap_configs)
    {
        if([tcap_config configEnabledWithYesDefault])
        {
            NSString *name = [tcap_config configName];
            if(name)
            {
                UMLayerTCAP *tcap = [[UMLayerTCAP alloc]initWithTaskQueueMulti:taskQueue tidPool:tidPool];
                tcap.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"tcap"];
                tcap.logFeed.name = name;
                NSString *attachTo = [tcap_config configEntry:@"attach-to"];
                UMLayerSCCP *sccp  = sccp_dict[attachTo];
                if(sccp == NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"Can not find sccp layer '%@' referred from tcap layer '%@'",attachTo,name];
                    @throw(CONFIG_ERROR(s));
                }
                [tcap setConfig:tcap_config applicationContext:self];
                tcap.attachedLayer = sccp;
                [tcap startUp];
                tcap_dict[name] = tcap;
            }
            else
            {
                @throw(CONFIG_ERROR(@"TCAP config without a name"));
            }
        }
    }


    NSArray *gsmmap_configs = [config getMultiGroups:@"gsmmap"];
    for(NSDictionary *gsmmap_config in gsmmap_configs)
    {
        if([gsmmap_config configEnabledWithYesDefault])
        {
            NSString *name = [gsmmap_config configName];
            if(name)
            {
                UMLayerGSMMAP *gsmmap = [[UMLayerGSMMAP alloc]initWithTaskQueueMulti:taskQueue];
                gsmmap.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"gsmmap"];
                gsmmap.logFeed.name = name;
                NSString *attachTo = [gsmmap_config configEntry:@"attach-to"];
                UMLayerTCAP *tcap  = tcap_dict[attachTo];
                if(tcap == NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"Can not find tcap layer '%@' referred from gsmmap layer '%@'",attachTo,name];
                    @throw(CONFIG_ERROR(s));
                }
                [gsmmap setConfig:gsmmap_config applicationContext:self];
                gsmmap.tcap = tcap;
                gsmmap_dict[name] = gsmmap;
                tcap.tcapDefaultUser = gsmmap;
                [gsmmap startUp];
            }
            else
            {
                @throw(CONFIG_ERROR(@"GSMMAP config without a name"));
            }
        }
    }

    NSArray *msc_configs = [config getMultiGroups:@"msc"];
    for(NSDictionary *msc_config in msc_configs)
    {
        if([msc_config configEnabledWithYesDefault])
        {
            NSString *name = [msc_config configName];
            if(name)
            {
                MSCInstance *msc = [[MSCInstance alloc]initWithTaskQueueMulti:taskQueue];
                msc.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"msc"];
                msc.logFeed.name = name;
                NSString *attachTo = [msc_config configEntry:@"attach-to"];
                UMLayerGSMMAP *map  = gsmmap_dict[attachTo];
                if(map == NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"Can not find gsmmap layer '%@' referred from msc layer '%@'",attachTo,name];
                    @throw(CONFIG_ERROR(s));
                }
                msc.gsmMap = map;
                map.user = msc;

                [msc setConfig:msc_config applicationContext:self];
                msc_dict[name] = msc;
                if(mainMscInstance==NULL)
                {
                    /* the first found instance is becoming the main instance */
                    mainMscInstance = msc;
                }
            }
            else
            {
                @throw(CONFIG_ERROR(@"MSC config without a name"));
            }
        }
    }


    NSArray *web_configs = [config getMultiGroups:@"webserver"];
    for(NSDictionary *web_config in web_configs)
    {
        if([web_config configEnabledWithYesDefault])
        {
            NSString *name = [web_config configName];
            if(name)
            {
                int webPort = [[web_config configEntry:@"port"] intValue];
                if(webPort == 0)
                {
                    webPort = 8080;
                }
                UMHTTPServer *webServer = NULL;
                if([[web_config configEntry:@"ssl"] boolValue])
                {
                    NSString *keyFile = [[web_config configEntry:@"ssl-key"] stringValue];
                    NSString *certFile = [[web_config configEntry:@"ssl-cert"] stringValue];

                    webServer = [[UMHTTPSServer alloc]initWithPort:webPort
                                                        sslKeyFile:keyFile
                                                       sslCertFile:certFile];
                }
                else
                {
                    webServer = [[UMHTTPServer alloc]initWithPort:webPort];
                }
                if(webServer)
                {
                    id<UMHTTPServerHttpGetPostDelegate> forwarder = self;
                    webServer.httpGetPostDelegate = forwarder;
                    webServer.logFeed = [[UMLogFeed alloc]initWithHandler:logHandler section:@"http"];
                    webServer.logFeed.name = name;
                    webserver_dict[name] = webServer;
                    webServer.authenticateRequestDelegate = self;
                    [webServer start];
                }
            }
            else
            {
                @throw(CONFIG_ERROR(@"WEBSERVER config without a name"));
            }
        }
    }
}


- (void)  handleStatus:(UMHTTPRequest *)req
{
    NSMutableString *status = [[NSMutableString alloc]init];


    NSArray *keys = [m2pa_dict allKeys];
    for(NSString *key in keys)
    {
        UMLayerM2PA *m2pa = m2pa_dict[key];
        [status appendFormat:@"M2PA-LINK:%@:%@\n",m2pa.layerName,[m2pa m2paStatusString:m2pa.m2pa_status]];
    }

    keys = [mtp3_linkset_dict allKeys];
    for(NSString *key in keys)
    {
        UMMTP3LinkSet *linkset = mtp3_linkset_dict[key];
        [linkset updateLinksetStatus];
        if(linkset.activeLinks > 0)
        {
            [status appendFormat:@"MTP3-LINKSET:%@:IS:%d/%d/%d\n",
             linkset.name,
             linkset.readyLinks,
             linkset.activeLinks,
             linkset.totalLinks];
        }
        else
        {
            [status appendFormat:@"MTP3-LINKSET:%@:OOS:%d/%d/%d\n",
             linkset.name,
             linkset.readyLinks,
             linkset.activeLinks,
             linkset.totalLinks];

        }
    }

    keys = [mtp3_dict allKeys];
    for(NSString *key in keys)
    {
        UMLayerMTP3 *mtp3 = mtp3_dict[key];
        if(mtp3.ready)
        {
            [status appendFormat:@"MTP3-INSTANCE:%@:IS\n",mtp3.layerName];
        }
        else
        {
            [status appendFormat:@"MTP3-INSTANCE:%@:OOS\n",mtp3.layerName];
        }
    }

    keys = [sccp_dict allKeys];
    for(NSString *key in keys)
    {
        UMLayerSCCP *sccp = sccp_dict[key];
        [status appendFormat:@"SCCP-INSTANCE:%@:%@\n",sccp.layerName,sccp.status];
    }

    keys = [tcap_dict allKeys];
    for(NSString *key in keys)
    {
        UMLayerTCAP *tcap = tcap_dict[key];
        [status appendFormat:@"TCAP-INSTANCE:%@:%@\n",tcap.layerName,tcap.status];
    }

    keys = [gsmmap_dict allKeys];
    for(NSString *key in keys)
    {
        UMLayerGSMMAP *map = gsmmap_dict[key];
        [status appendFormat:@"GSMMAP-INSTANCE:%@:%@\n",map.layerName,map.status];
    }

    keys = [msc_dict allKeys];
    for(NSString *key in keys)
    {
        MSCInstance *v = msc_dict[key];
        [status appendFormat:@"MSC-INSTANCE:%@:%@\n",v.layerName,v.status];
    }
    [req setResponsePlainText:status];
    return;
}

- (NSDictionary *)cnamResponseForMsisdn:(NSString *)msisdn
{
    return @{@"cnam" : @"John Doe"};
}

+ (NSString *)css
{
    static NSMutableString *s = NULL;

    if(s)
    {
        return s;
    }
    s = [[NSMutableString alloc]init];

    [s appendString:@"/*-- [START] css/style.css --*/\n"];
    [s appendString:@"\n"];
    [s appendString:@"body\n"];
    [s appendString:@"{\n"];
    [s appendString:@"	border: none;\n"];
    [s appendString:@"	padding: 20px;\n"];
    [s appendString:@"	margin: 0px;\n"];
    [s appendString:@"	background-color:white;\n"];
    [s appendString:@"	color: black;\n"];
    [s appendString:@"	font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"	font-size: 11px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"h1 {\n"];
    [s appendString:@"	font-size: 22px;\n"];
    [s appendString:@"	font-weight: normal;\n"];
    [s appendString:@"	padding-left: 0px;\n"];
    [s appendString:@"	margin-top: 15px;\n"];
    [s appendString:@"	margin-bottom: 20px;\n"];
    [s appendString:@"	color: #639c35;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"h2 {\n"];
    [s appendString:@"	font-size: 16px;\n"];
    [s appendString:@"	margin-bottom: 8px;\n"];
    [s appendString:@"	margin-top: 10px;\n"];
    [s appendString:@"	color: #639c35;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"\n"];
    [s appendString:@"h3 {\n"];
    [s appendString:@"	font-size: 13px;\n"];
    [s appendString:@"	margin-bottom: 8px;\n"];
    [s appendString:@"	margin-top: 10px;\n"];
    [s appendString:@"	\n"];
    [s appendString:@"	color: black;\n"];
    [s appendString:@"	font-weight: bold;\n"];
    [s appendString:@"	font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"	font-size: 13px;\n"];
    [s appendString:@"\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"a {\n"];
    [s appendString:@"	color: #000066;\n"];
    [s appendString:@"	text-decoration: underline;\n"];
    [s appendString:@"	font-weight: bold;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"a:hover {\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"\n"];
    [s appendString:@"hr {\n"];
    [s appendString:@"	height: 1px;\n"];
    [s appendString:@"	margin-bottom: 1em;\n"];
    [s appendString:@"	border-width: 0px;\n"];
    [s appendString:@"	border-bottom-width: 1px;\n"];
    [s appendString:@"	border-color: #000000;\n"];
    [s appendString:@"	border-style: solid;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@"\n"];
    [s appendString:@".mandatory {\n"];
    [s appendString:@"	color: red;\n"];
    [s appendString:@"	font-weight: bold;\n"];
    [s appendString:@"	font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"	font-size: 11px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@".optional {\n"];
    [s appendString:@"	color: green;\n"];
    [s appendString:@"	font-weight: lighter;\n"];
    [s appendString:@"	font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"	font-size: 11px;\n"];
    [s appendString:@"}\n"];
    [s appendString:@"\n"];
    [s appendString:@".subtitle {\n"];
    [s appendString:@"	color: black;\n"];
    [s appendString:@"	font-weight: bold;\n"];
    [s appendString:@"	font-family: 'Metrophobic', \"Lucida Grande\", \"Lucida Sans Unicode\", arial, Helvetica, Verdana;\n"];
    [s appendString:@"	font-size: 12px;\n"];
    [s appendString:@"}\n"];
    return s;
}

- (UMHTTPAuthenticationStatus)httpAuthenticateRequest:(UMHTTPRequest *)req
                                                realm:(NSString **)realm
{
    return UMHTTP_AUTHENTICATION_STATUS_NOT_REQUESTED;
}

- (UMLayerSctp *)getSCTP:(NSString *)name
{
    return sctp_dict[name];
}

- (UMLayerM2PA *)getM2PA:(NSString *)name
{
    return m2pa_dict[name];
}

- (UMLayerMTP3 *)getMTP3:(NSString *)name
{
    return mtp3_dict[name];
}

- (UMLayerSCCP *)getSCCP:(NSString *)name
{
    return sccp_dict[name];
}

- (UMLayerTCAP *)getTCAP:(NSString *)name
{
    return tcap_dict[name];
}

- (UMLayerGSMMAP *)getGSMMAP:(NSString *)name
{
    return gsmmap_dict[name];
}


- (UMMTP3Link *)getMTP3_Link:(NSString *)name
{
    return mtp3_link_dict[name];
}

- (UMMTP3LinkSet *)getMTP3_LinkSet:(NSString *)name
{
    return mtp3_linkset_dict[name];
}

- (UMM3UAApplicationServerProcess *)getM3UA_ASP:(NSString *)name
{
    return m3ua_asp_dict[name];
}

- (UMM3UAApplicationServer *)getM3UA_AS:(NSString *)name
{
    return  m3ua_as_dict[name];
}

- (MSCInstance *)getMSC:(NSString *)name
{
    return  msc_dict[name];
}

- (SccpNextHop *)getSCCP_NextHop:(NSString *)name
{
    return  sccp_next_hop_dict[name];
}


/* this is used for incoming telnet sessions to authorize by IP */
- (BOOL) isAddressWhitelisted:(NSString *)ipAddress
{
    return YES;
}

@end
