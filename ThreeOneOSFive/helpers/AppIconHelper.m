#import "AppIconHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

static UIImage *iconFromData(NSData *data, CGFloat targetSize) {
    if (!data) return nil;
    UIImage *image = [UIImage imageWithData:data];
    if (!image) return nil;
    if (image.size.width <= targetSize && image.size.height <= targetSize) return image;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = image.scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(targetSize, targetSize) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [image drawInRect:CGRectMake(0, 0, targetSize, targetSize)];
    }];
}

static NSData *iconDataFromProxy(id proxy) {
    SEL iconSel = NSSelectorFromString(@"iconDataForVariant:");
    if (![proxy respondsToSelector:iconSel]) return nil;

    // Variant availability differs between iOS releases and app types.
    // Stop at the first usable image instead of assuming variant zero exists.
    const int variants[] = {2, 0, 1, 3, 4, 5, 6, 7, 15};
    for (NSUInteger index = 0; index < sizeof(variants) / sizeof(variants[0]); index++) {
        id data = ((id (*)(id, SEL, int))objc_msgSend)(proxy, iconSel, variants[index]);
        if ([data isKindOfClass:[NSData class]] && [data length] > 0) return data;
    }
    return nil;
}

static NSString *stringForFirstKey(NSDictionary *info, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = info[key];
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return nil;
}

static NSString *pathForFirstKey(NSDictionary *info, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = info[key];
        if ([value isKindOfClass:[NSURL class]]) {
            NSString *path = [value path];
            if (path.length > 0) return path;
        }
        if ([value isKindOfClass:[NSString class]] && [value length] > 0) return value;
    }
    return nil;
}

static void addApplicationInfo(NSMutableDictionary *result, NSString *fallbackBundleID, NSDictionary *info) {
    NSString *bundleID = stringForFirstKey(info, @[
        @"CFBundleIdentifier", @"BundleIdentifier", @"ApplicationIdentifier", @"MCMMetadataIdentifier"
    ]);
    if (bundleID.length == 0) bundleID = fallbackBundleID;
    if (bundleID.length == 0) return;

    NSString *name = stringForFirstKey(info, @[
        @"CFBundleDisplayName", @"CFBundleName", @"LocalizedName", @"Name"
    ]);
    NSString *container = pathForFirstKey(info, @[
        @"Container", @"DataContainer", @"DataContainerURL", @"ContainerPath", @"SandboxPath"
    ]);
    NSString *version = stringForFirstKey(info, @[
        @"CFBundleShortVersionString", @"BundleShortVersionString"
    ]);

    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    entry[@"name"] = name.length > 0 ? name : bundleID;
    if (container.length > 0) entry[@"container"] = container;
    if (version.length > 0) entry[@"version"] = version;
    result[bundleID] = entry;
}

static void *mobileInstallationHandle(void) {
    static void *handle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = dlopen("/System/Library/PrivateFrameworks/MobileInstallation.framework/MobileInstallation", RTLD_LAZY | RTLD_LOCAL);
    });
    return handle;
}

static NSDictionary *appsFromMobileInstallation(void) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    void *frameworkHandle = mobileInstallationHandle();

    // Legacy path for older releases where the original symbol is still exported.
    void *lookupFn = dlsym(RTLD_DEFAULT, "MobileInstallationLookup");
    if (!lookupFn && frameworkHandle) {
        lookupFn = dlsym(frameworkHandle, "MobileInstallationLookup");
    }
    if (!lookupFn) return result;

    NSDictionary *apps = nil;
    NSArray *optionSets = @[
        @{@"ApplicationType": @"Any"},
        @{@"ApplicationType": @"User"},
        @{@"ApplicationType": @"System"},
        @{},
    ];
    for (NSDictionary *options in optionSets) {
        apps = ((NSDictionary *(*)(NSDictionary *, void *))lookupFn)(options, NULL);
        if (apps && [apps isKindOfClass:[NSDictionary class]] && apps.count > 0) break;
    }
    if (!apps || apps.count == 0) return result;

    for (NSString *bundleID in apps) {
        @autoreleasepool {
            id rawInfo = apps[bundleID];
            if (![rawInfo isKindOfClass:[NSDictionary class]]) continue;
            addApplicationInfo(result, bundleID, rawInfo);
        }
    }
    return result;
}

static void ensureLaunchServicesLoaded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char *candidates[] = {
            "/System/Library/Frameworks/CoreServices.framework/CoreServices",
            "/System/Library/PrivateFrameworks/MobileCoreServices.framework/MobileCoreServices",
            "/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices",
        };
        for (size_t i = 0; i < sizeof(candidates) / sizeof(candidates[0]); i++) {
            if (dlopen(candidates[i], RTLD_LAZY | RTLD_GLOBAL)) {
                NSLog(@"[3105] ls: loaded %s", candidates[i]);
                return;
            }
        }
        NSLog(@"[3105] ls: CoreServices/MobileCoreServices dlopen failed");
    });
}

static NSDictionary *appsFromWorkspace(void) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    ensureLaunchServicesLoaded();

    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (!workspaceClass) {
        NSLog(@"[3105] ls: LSApplicationWorkspace class unavailable");
        return result;
    }
    SEL defaultWorkspaceSel = NSSelectorFromString(@"defaultWorkspace");
    if (![workspaceClass respondsToSelector:defaultWorkspaceSel]) {
        NSLog(@"[3105] ls: defaultWorkspace selector unavailable");
        return result;
    }
    id workspace = ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultWorkspaceSel);
    if (!workspace) {
        NSLog(@"[3105] ls: defaultWorkspace returned nil");
        return result;
    }

    NSArray *apps = nil;
    NSString *usedSelector = nil;
    for (NSString *selectorName in @[@"allApplications", @"allInstalledApplications"]) {
        SEL allAppsSel = NSSelectorFromString(selectorName);
        if (![workspace respondsToSelector:allAppsSel]) continue;
        id candidate = ((id (*)(id, SEL))objc_msgSend)(workspace, allAppsSel);
        if ([candidate isKindOfClass:[NSArray class]] && [candidate count] > 0) {
            apps = candidate;
            usedSelector = selectorName;
            break;
        }
        NSLog(@"[3105] ls: %@ returned %lu", selectorName,
              (unsigned long)([candidate isKindOfClass:[NSArray class]] ? [candidate count] : 0));
    }
    if (!apps || apps.count == 0) {
        NSLog(@"[3105] ls: workspace enumeration empty");
        return result;
    }
    NSLog(@"[3105] ls: %@ returned %lu proxies", usedSelector, (unsigned long)apps.count);

    NSUInteger withContainer = 0;
    for (id app in apps) {
        @autoreleasepool {
            NSString *bundleID = nil;
            for (NSString *selectorName in @[@"bundleIdentifier", @"applicationIdentifier"]) {
                SEL bundleSel = NSSelectorFromString(selectorName);
                if (![app respondsToSelector:bundleSel]) continue;
                id value = ((id (*)(id, SEL))objc_msgSend)(app, bundleSel);
                if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                    bundleID = value;
                    break;
                }
            }
            if (bundleID.length == 0) continue;

            NSString *name = nil;
            for (NSString *selectorName in @[@"localizedName", @"localizedShortName"]) {
                SEL nameSel = NSSelectorFromString(selectorName);
                if (![app respondsToSelector:nameSel]) continue;
                id value = ((id (*)(id, SEL))objc_msgSend)(app, nameSel);
                if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                    name = value;
                    break;
                }
            }
            if (name.length == 0) name = bundleID;

            NSMutableDictionary *entry = [NSMutableDictionary dictionary];
            entry[@"name"] = name;
            for (NSString *selectorName in @[@"dataContainerURL", @"containerURL"]) {
                SEL containerSel = NSSelectorFromString(selectorName);
                if (![app respondsToSelector:containerSel]) continue;
                id containerValue = ((id (*)(id, SEL))objc_msgSend)(app, containerSel);
                NSString *containerPath = [containerValue isKindOfClass:[NSURL class]] ? [containerValue path] : containerValue;
                if ([containerPath isKindOfClass:[NSString class]] && containerPath.length > 0) {
                    entry[@"container"] = containerPath;
                    withContainer++;
                    break;
                }
            }
            result[bundleID] = entry;
        }
    }
    NSLog(@"[3105] ls: extracted %lu apps (%lu with container)",
          (unsigned long)result.count, (unsigned long)withContainer);
    return result;
}

NSDictionary<NSString *, NSDictionary *> *installedAppInfo(void) {
    NSDictionary *workspace = appsFromWorkspace();
    if (workspace.count > 0) return workspace;
    NSDictionary *mobileInstallation = appsFromMobileInstallation();
    NSLog(@"[3105] ls: workspace empty; MobileInstallation=%lu",
          (unsigned long)mobileInstallation.count);
    return mobileInstallation;
}

// Icon via LSApplicationProxy (per bundle ID)
UIImage *iconForBundleID(NSString *bundleID) {
    static NSCache<NSString *, UIImage *> *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 256;
    });
    UIImage *cached = [cache objectForKey:bundleID];
    if (cached) return cached;

    Class proxyClass = NSClassFromString(@"LSApplicationProxy");
    if (!proxyClass) return nil;
    SEL appProxySel = NSSelectorFromString(@"applicationProxyForIdentifier:");
    if (![proxyClass respondsToSelector:appProxySel]) return nil;
    id proxy = ((id (*)(id, SEL, id))objc_msgSend)(proxyClass, appProxySel, bundleID);
    if (!proxy) return nil;
    UIImage *icon = iconFromData(iconDataFromProxy(proxy), 60.0);
    if (icon) [cache setObject:icon forKey:bundleID];
    return icon;
}

// Name + icon for a single bundle ID via LSApplicationProxy
NSDictionary *appInfoForBundleID(NSString *bundleID) {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"name"] = bundleID;

    ensureLaunchServicesLoaded();

    Class proxyClass = NSClassFromString(@"LSApplicationProxy");
    if (!proxyClass) return result;
    SEL appProxySel = NSSelectorFromString(@"applicationProxyForIdentifier:");
    if (![proxyClass respondsToSelector:appProxySel]) return result;
    id proxy = ((id (*)(id, SEL, id))objc_msgSend)(proxyClass, appProxySel, bundleID);
    if (!proxy) return result;

    result[@"found"] = @YES;

    NSURL *bundleURL = nil;
    SEL bundleURLSel = NSSelectorFromString(@"bundleURL");
    if ([proxy respondsToSelector:bundleURLSel]) {
        id value = ((id (*)(id, SEL))objc_msgSend)(proxy, bundleURLSel);
        if ([value isKindOfClass:[NSURL class]]) bundleURL = value;
    }

    NSBundle *applicationBundle = bundleURL ? [NSBundle bundleWithURL:bundleURL] : nil;
    NSDictionary *localizedInfo = applicationBundle.localizedInfoDictionary;
    NSDictionary *bundleInfo = applicationBundle.infoDictionary;
    NSString *bundleName = stringForFirstKey(localizedInfo, @[
        @"CFBundleDisplayName", @"CFBundleName"
    ]);
    if (bundleName.length == 0) {
        bundleName = stringForFirstKey(bundleInfo, @[
            @"CFBundleDisplayName", @"CFBundleName"
        ]);
    }
    if (bundleName.length > 0) result[@"name"] = bundleName;

    if ([result[@"name"] isEqualToString:bundleID]) {
        for (NSString *selectorName in @[@"localizedName", @"localizedShortName"]) {
            SEL nameSel = NSSelectorFromString(selectorName);
            if (![proxy respondsToSelector:nameSel]) continue;
            NSString *name = ((id (*)(id, SEL))objc_msgSend)(proxy, nameSel);
            if ([name isKindOfClass:[NSString class]] && name.length > 0) {
                result[@"name"] = name;
                break;
            }
        }
    }

    NSString *bundleVersion = stringForFirstKey(bundleInfo, @[
        @"CFBundleShortVersionString"
    ]);
    if (bundleVersion.length > 0) result[@"version"] = bundleVersion;
    if (!result[@"version"]) {
        SEL versionSel = NSSelectorFromString(@"shortVersionString");
        if ([proxy respondsToSelector:versionSel]) {
            NSString *version = ((id (*)(id, SEL))objc_msgSend)(proxy, versionSel);
            if ([version isKindOfClass:[NSString class]] && version.length > 0) {
                result[@"version"] = version;
            }
        }
    }

    for (NSString *selectorName in @[@"dataContainerURL", @"containerURL"]) {
        SEL containerSel = NSSelectorFromString(selectorName);
        if (![proxy respondsToSelector:containerSel]) continue;
        id value = ((id (*)(id, SEL))objc_msgSend)(proxy, containerSel);
        NSString *path = [value isKindOfClass:[NSURL class]] ? [value path] : value;
        if ([path isKindOfClass:[NSString class]] && path.length > 0) {
            result[@"container"] = path;
            break;
        }
    }

    return result;
}

NSString *findFreeFireContainerPath(void) {
    ensureLaunchServicesLoaded();

    NSArray<NSString *> *targetIDs = @[
        @"com.dts.freefireth",
        @"com.dts.freefiremax",
        @"com.dts.freefire",
        @"com.dts.freefirevn"
    ];

    // 1. Check LSApplicationRecord (iOS 15+)
    Class recordClass = NSClassFromString(@"LSApplicationRecord");
    if (recordClass) {
        SEL recordInitSel = NSSelectorFromString(@"initWithBundleIdentifier:allowPlaceholder:error:");
        if ([recordClass instancesRespondToSelector:recordInitSel]) {
            for (NSString *bid in targetIDs) {
                NSError *recErr = nil;
                id record = [recordClass alloc];
                record = ((id (*)(id, SEL, id, BOOL, id*))objc_msgSend)(record, recordInitSel, bid, NO, &recErr);
                if (record) {
                    for (NSString *selectorName in @[@"dataContainerURL", @"containerURL"]) {
                        SEL containerSel = NSSelectorFromString(selectorName);
                        if (![record respondsToSelector:containerSel]) continue;
                        id containerValue = ((id (*)(id, SEL))objc_msgSend)(record, containerSel);
                        NSString *containerPath = [containerValue isKindOfClass:[NSURL class]] ? [containerValue path] : containerValue;
                        if ([containerPath isKindOfClass:[NSString class]] && containerPath.length > 0) {
                            NSLog(@"[3105] findFreeFireContainerPath: found via LSApplicationRecord %@ -> %@", bid, containerPath);
                            return containerPath;
                        }
                    }
                }
            }
        }
    }

    // 2. Check LSApplicationProxy
    Class proxyClass = NSClassFromString(@"LSApplicationProxy");
    if (proxyClass) {
        SEL appProxySel = NSSelectorFromString(@"applicationProxyForIdentifier:");
        if ([proxyClass respondsToSelector:appProxySel]) {
            for (NSString *bid in targetIDs) {
                id proxy = ((id (*)(id, SEL, id))objc_msgSend)(proxyClass, appProxySel, bid);
                if (proxy) {
                    for (NSString *selectorName in @[@"dataContainerURL", @"containerURL"]) {
                        SEL containerSel = NSSelectorFromString(selectorName);
                        if (![proxy respondsToSelector:containerSel]) continue;
                        id value = ((id (*)(id, SEL))objc_msgSend)(proxy, containerSel);
                        NSString *path = [value isKindOfClass:[NSURL class]] ? [value path] : value;
                        if ([path isKindOfClass:[NSString class]] && path.length > 0) {
                            NSLog(@"[3105] findFreeFireContainerPath: found via proxy %@ -> %@", bid, path);
                            return path;
                        }
                    }
                }
            }
        }
    }

    // 3. Check LSApplicationWorkspace
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass) {
        SEL defaultWorkspaceSel = NSSelectorFromString(@"defaultWorkspace");
        if ([workspaceClass respondsToSelector:defaultWorkspaceSel]) {
            id workspace = ((id (*)(id, SEL))objc_msgSend)(workspaceClass, defaultWorkspaceSel);
            if (workspace) {
                // Direct application lookup by bundleID
                SEL appForBidSel = NSSelectorFromString(@"applicationForBundleIdentifier:");
                if ([workspace respondsToSelector:appForBidSel]) {
                    for (NSString *bid in targetIDs) {
                        id app = ((id (*)(id, SEL, id))objc_msgSend)(workspace, appForBidSel, bid);
                        if (app) {
                            for (NSString *selectorName in @[@"dataContainerURL", @"containerURL"]) {
                                SEL containerSel = NSSelectorFromString(selectorName);
                                if (![app respondsToSelector:containerSel]) continue;
                                id containerValue = ((id (*)(id, SEL))objc_msgSend)(app, containerSel);
                                NSString *containerPath = [containerValue isKindOfClass:[NSURL class]] ? [containerValue path] : containerValue;
                                if ([containerPath isKindOfClass:[NSString class]] && containerPath.length > 0) {
                                    NSLog(@"[3105] findFreeFireContainerPath: found via workspace appForBid %@ -> %@", bid, containerPath);
                                    return containerPath;
                                }
                            }
                        }
                    }
                }

                // Enumeration fallback
                NSArray *apps = nil;
                for (NSString *selName in @[@"allApplications", @"allInstalledApplications"]) {
                    SEL sel = NSSelectorFromString(selName);
                    if ([workspace respondsToSelector:sel]) {
                        id res = ((id (*)(id, SEL))objc_msgSend)(workspace, sel);
                        if ([res isKindOfClass:[NSArray class]] && [res count] > 0) {
                            apps = res;
                            break;
                        }
                    }
                }
                if (apps) {
                    for (id app in apps) {
                        NSString *bid = nil;
                        for (NSString *selectorName in @[@"bundleIdentifier", @"applicationIdentifier"]) {
                            SEL bundleSel = NSSelectorFromString(selectorName);
                            if (![app respondsToSelector:bundleSel]) continue;
                            id value = ((id (*)(id, SEL))objc_msgSend)(app, bundleSel);
                            if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
                                bid = value;
                                break;
                            }
                        }
                        if (bid && [bid.lowercaseString containsString:@"freefire"]) {
                            for (NSString *selectorName in @[@"dataContainerURL", @"containerURL"]) {
                                SEL containerSel = NSSelectorFromString(selectorName);
                                if (![app respondsToSelector:containerSel]) continue;
                                id containerValue = ((id (*)(id, SEL))objc_msgSend)(app, containerSel);
                                NSString *containerPath = [containerValue isKindOfClass:[NSURL class]] ? [containerValue path] : containerValue;
                                if ([containerPath isKindOfClass:[NSString class]] && containerPath.length > 0) {
                                    NSLog(@"[3105] findFreeFireContainerPath: found via workspace %@ -> %@", bid, containerPath);
                                    return containerPath;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return nil;
}

BOOL openApplicationForBundleID(NSString *bundleID) {
    if (bundleID.length == 0) return NO;
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    SEL defaultWorkspaceSelector = NSSelectorFromString(@"defaultWorkspace");
    if (!workspaceClass || ![workspaceClass respondsToSelector:defaultWorkspaceSelector]) {
        return NO;
    }
    id workspace = ((id (*)(id, SEL))objc_msgSend)(
        workspaceClass,
        defaultWorkspaceSelector
    );
    if (!workspace) return NO;
    SEL openSelector = NSSelectorFromString(@"openApplicationWithBundleID:");
    if (![workspace respondsToSelector:openSelector]) return NO;
    return ((BOOL (*)(id, SEL, id))objc_msgSend)(workspace, openSelector, bundleID);
}

