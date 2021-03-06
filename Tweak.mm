//
//  Tweak.mm
//  Contains all hooks into Apple's code which handles showing the Apple internal settings.
//
//  Created by Joshua Seltzer on 12/15/14.
//
//

#import "AppleInterfaces.h"
#import <UIKit/UIKit.h>

// macros to determine which system software this device is running
#define SYSTEM_VERSION_IOS9     [[[%c(UIDevice) currentDevice] systemVersion] floatValue] >= 9.0

// define the path to the preferences plist
#define SETTINGS_PATH           [NSHomeDirectory() stringByAppendingPathComponent:kJSSettingsPath]

// define the constant for the application bundle ID that we need to check for
static NSString *const kJSAppBundleId = @"com.apple.Preferences";

// constant that defines the string that points to our preference plist
static NSString *const kJSSettingsPath = @"/Library/Preferences/com.joshuaseltzer.advancedsettings8prefs.plist";

// flag that determines if we have presented the advanced settings
static BOOL sJSPresentedSettings = NO;

// check the preferences file to see if the tweak itself is enabled or disabled
BOOL isEnabled()
{
    // attempt to get the preferences from the plist
    NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];

    // See if it we have preferences and if it is enabled.  By default it is enabled
    BOOL isEnabled = YES;
    if (prefs) {
        isEnabled = [[prefs objectForKey:@"enabled"] boolValue];
    }
    
    return isEnabled;
}

// the iOS8 specific hooks
%group iOS8

// hook to see when we long press on an icon
%hook SBIconView

// invoked when the long press timer on a Springboard icon is fired
- (void)longPressTimerFired
{
    // Check to see if the application bundle ID is equal to the settings app.  Disallow the settings
    // to display if we are already in edit mode
    if (!self.isEditing && isEnabled() && [[self.icon applicationBundleID] isEqualToString:kJSAppBundleId]) {
        // set our presentation flag to YES
        sJSPresentedSettings = YES;
        
        // show the advanced settings
        [[%c(SBPrototypeController) sharedInstance] _showSettings];
    } else {
        // perform the original implementation for any other app icon
        %orig;
    }
}

%end

// hook to see when we tap on an icon
%hook SBApplicationIcon

// launches an application
- (void)launchFromLocation:(int)location
{
    // check to see if the application bundle ID is equal to the settings app
    if (isEnabled() && [[self applicationBundleID] isEqualToString:kJSAppBundleId]) {
        if (sJSPresentedSettings) {
            // if we have presented the advanced settings, then reset the flag
            sJSPresentedSettings = NO;
        } else {
            // otherwise, launch the settings app
            %orig;
        }
    } else {
        // perform the original implementation for any other app icon
        %orig;
    }
}

%end

%end

// the iOS9 specific hooks
%group iOS9

// hook to see when we long press on an icon
%hook SBIconView

// fired when the first half long press is invoked
- (void)_handleSecondHalfLongPressTimer:(id)arg1
{
    // Check to see if the application bundle ID is equal to the settings app.  Disallow the settings
    // to display if we are already in edit mode
    if (!self.isEditing && isEnabled() && [[self.icon applicationBundleID] isEqualToString:kJSAppBundleId]) {
        // set our presentation flag to YES
        sJSPresentedSettings = YES;
        
        // show the advanced settings
        [[%c(SBPrototypeController) sharedInstance] _showSettings];
    } else {
        // perform the original implementation for any other app icon
        %orig;
    }
}

%end

// hook to see when we tap on an icon
%hook SBApplicationIcon

// launches an application
- (void)launchFromLocation:(int)arg1 context:(id)arg2
{
    // check to see if the application bundle ID is equal to the settings app
    if (isEnabled() && [[self applicationBundleID] isEqualToString:kJSAppBundleId]) {
        if (sJSPresentedSettings) {
            // if we have presented the advanced settings, then reset the flag
            sJSPresentedSettings = NO;
        } else {
            // otherwise, launch the settings app
            %orig;
        }
    } else {
        // perform the original implementation for any other app icon
        %orig;
    }
}

%end

%end

// constructor which will decide which hooks to include depending which system software the device
// is running
%ctor {
    if (SYSTEM_VERSION_IOS9) {
        %init(iOS9);
    } else {
        %init(iOS8);
    }
}