#import <HookKit/Core.h>
#import <Modulous/Loader.h>
#import <RootBridge.h>

// 模块描述键名:cocoons annotate 注解加密(strings 里不可见)
__attribute__((annotate("obfuscate")))
static NSString* const kKeyModuleInfo = kKeyModuleInfo;
__attribute__((annotate("obfuscate")))
static NSString* const kKeyPriority = kKeyPriority;
__attribute__((annotate("obfuscate")))
static NSString* const kKeyCFBundleIdentifier = kKeyCFBundleIdentifier;
__attribute__((annotate("obfuscate")))
static NSString* const kKeyIdentifier = kKeyIdentifier;

@implementation HookKitCore {
    ModulousLoader* loader;
    NSMutableDictionary<NSString *, __kindof HookKitModule *>* registeredModules;
}

+ (instancetype)sharedInstance {
    static HookKitCore* sharedInstance = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (__kindof HookKitModule *)defaultModule {
    static __kindof HookKitModule* defaultModule = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^{
        // load the highest priority module
        NSArray<NSDictionary *>* modulous_infos = [[loader getModuleInfo] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
            NSDictionary* info_a = [a objectForKey:kKeyModuleInfo];
            NSDictionary* info_b = [b objectForKey:kKeyModuleInfo];
            NSNumber* prio_a = [info_a objectForKey:kKeyPriority];
            NSNumber* prio_b = [info_b objectForKey:kKeyPriority];

            if(!prio_a) {
                prio_a = @(100);
            }

            if(!prio_b) {
                prio_b = @(100);
            }

            return [prio_a compare:prio_b];
        }];

        if(modulous_infos) {
            for(NSDictionary* modulous_info in modulous_infos) {
                NSString* modulous_identifier = [modulous_info objectForKey:kKeyCFBundleIdentifier];
                NSDictionary* info = [modulous_info objectForKey:kKeyModuleInfo];

                if(info) {
                    NSString* module_identifier = [info objectForKey:kKeyIdentifier];
                    
                    [loader loadModulesWithIdentifiers:@[modulous_identifier]];
                    defaultModule = [self getModuleWithIdentifier:module_identifier];
                }

                if(defaultModule) {
                    break;
                }
            }
        }
    });

    return defaultModule;
}

- (NSArray<NSDictionary *> *)getModuleInfo {
    NSMutableArray<NSDictionary *>* infos = [NSMutableArray new];
    NSArray<NSDictionary *>* modulous_infos = [loader getModuleInfo];

    if(modulous_infos) {
        for(NSDictionary* modulous_info in modulous_infos) {
            NSDictionary* info = [modulous_info objectForKey:kKeyModuleInfo];

            if(info) {
                [infos addObject:info];
            }
        }
    }

    return [infos copy];
}

- (NSDictionary *)getModuleInfoWithIdentifier:(NSString *)identifier {
    NSArray<NSDictionary *>* modulous_infos = [loader getModuleInfo];

    if(modulous_infos) {
        for(NSDictionary* modulous_info in modulous_infos) {
            NSDictionary* info = [modulous_info objectForKey:kKeyModuleInfo];

            if(info && [[info objectForKey:kKeyIdentifier] isEqualToString:identifier]) {
                return info;
            }
        }
    }

    return nil;
}

- (__kindof HookKitModule *)getModuleWithIdentifier:(NSString *)identifier {
    __kindof HookKitModule* result = nil;

    @synchronized(registeredModules) {
        result = [registeredModules objectForKey:identifier];
    }

    if(!result) {
        NSArray<NSDictionary *>* modulous_infos = [loader getModuleInfo];

        if(modulous_infos) {
            for(NSDictionary* modulous_info in modulous_infos) {
                NSString* modulous_identifier = [modulous_info objectForKey:kKeyCFBundleIdentifier];
                NSDictionary* info = [modulous_info objectForKey:kKeyModuleInfo];

                if(info && [[info objectForKey:kKeyIdentifier] isEqualToString:identifier]) {
                    // load module with modulous
                    [loader loadModulesWithIdentifiers:@[modulous_identifier]];
                }
            }
        }

        @synchronized(registeredModules) {
            result = [registeredModules objectForKey:identifier];
        }
    }

    return result;
}

- (void)registerModule:(__kindof HookKitModule *)module withIdentifier:(NSString *)identifier {
    if(module && identifier) {
        @synchronized(registeredModules) {
            [registeredModules setObject:module forKey:identifier];
        }
    }
}

- (instancetype)init {
    if((self = [super init])) {
        loader = [ModulousLoader loaderWithPath:[RootBridge getJBPath:@"/Library/Modulous/HookKit"]];
        registeredModules = [NSMutableDictionary new];
    }

    return self;
}
@end