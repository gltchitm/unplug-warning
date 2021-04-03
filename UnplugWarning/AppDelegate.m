//
//  AppDelegate.m
//  UnplugWarning
//
//  Created by gltchitm on 4/2/21.
//

#import "AppDelegate.h"

#import <UserNotifications/UserNotifications.h>
#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow* window;

@end

@implementation AppDelegate

bool showingObnoxiousNotification = false;
bool deviceUnplugged = false;
NSTimer* obnoxiousNotificationCloseTimer;

NSTimer* setTimer(NSTimeInterval seconds, id target, SEL selector) {
    return [NSTimer scheduledTimerWithTimeInterval:seconds
               target:target
               selector:selector
               userInfo:nil
               repeats:FALSE];
}
void showObnoxiousNotification(AppDelegate* self) {
    dispatch_async(dispatch_get_main_queue(), ^ {
        showingObnoxiousNotification = true;
        NSWindow* window = [self window];
        NSPoint position;
        NSRect frame = [[NSScreen mainScreen] visibleFrame];
        position.x = frame.origin.x + frame.size.width - [window frame].size.width;
        position.y = frame.origin.y + frame.size.height - [window frame].size.height;
        [window setFrameOrigin:position];
        [window makeKeyAndOrderFront:nil];
        [window setLevel:NSStatusWindowLevel];
        obnoxiousNotificationCloseTimer = setTimer(5.0, self, @selector(hideObnoxiousNotification));
    });
}
void checkPowerSource(void* context) {
    CFTypeRef snapshot = IOPSCopyPowerSourcesInfo();
    CFStringRef powerSource = IOPSGetProvidingPowerSourceType(snapshot);
    
    if (strcmp(CFStringGetCStringPtr(powerSource, kCFStringEncodingUTF8), kIOPSACPowerValue) != 0) {
        if (showingObnoxiousNotification || deviceUnplugged) {
            return;
        }
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Not Charging";
        content.subtitle = @"Your device is no longer charging.";
        UNNotificationRequest* request = [UNNotificationRequest
                                              requestWithIdentifier:@"DeviceUnplugged"
                                              content:content
                                              trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter]
            getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings* _Nonnull settings) {
                [[UNUserNotificationCenter currentNotificationCenter]
                    requestAuthorizationWithOptions:UNAuthorizationOptionAlert
                    completionHandler:^(BOOL granted, NSError* _Nullable error) {
                        if (
                            (!granted && !showingObnoxiousNotification) ||
                            [settings alertStyle] == UNAlertStyleNone ||
                            error
                        ) {
                            showObnoxiousNotification((__bridge AppDelegate*) context);
                        } else {
                            [[UNUserNotificationCenter currentNotificationCenter]
                                addNotificationRequest:request
                                withCompletionHandler:^(NSError* _Nullable error) {
                                    if (error) {
                                        showObnoxiousNotification((__bridge AppDelegate*) context);
                                    } else {
                                        deviceUnplugged = true;
                                        dispatch_async(dispatch_get_main_queue(), ^ {
                                            setTimer(
                                                5.0,
                                                (__bridge AppDelegate*)
                                                context,
                                                @selector(removeNotification)
                                            );
                                        });
                                    }
                                }];
                        }
                    }];
        }];
    } else {
        deviceUnplugged = false;
        if (showingObnoxiousNotification) {
            [(__bridge AppDelegate*) context hideObnoxiousNotification];
        }
    }
    CFRelease(snapshot);
}
- (IBAction)closeButton:(NSButton*)sender {
    [self hideObnoxiousNotification];
}
- (void)removeNotification {
    [[UNUserNotificationCenter currentNotificationCenter]
        removeDeliveredNotificationsWithIdentifiers:@[@"DeviceUnplugged"]];
}
- (void)hideObnoxiousNotification {
    [obnoxiousNotificationCloseTimer invalidate];
    [self.window orderOut:nil];
    showingObnoxiousNotification = false;
}
- (BOOL)canBecomeKeyWindow {
    return FALSE;
}
- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    void* context = (__bridge void*) self;
    CFRunLoopSourceRef ref = IOPSNotificationCreateRunLoopSource(checkPowerSource, context);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), ref, kCFRunLoopDefaultMode);
    CFRelease(ref);
    [self hideObnoxiousNotification];
}

@end
