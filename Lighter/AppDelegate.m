//
//  AppDelegate.m
//  PercentCalculator
//
//  Created by Rares Tamas on 12/17/14.
//  Copyright (c) 2014 Rares Tamas. All rights reserved.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>

#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize aboutWindow, raresBtn, popUpView, attachedWindow, popupShowed, websiteBtn;

@synthesize counterWindow, wordsLabel, linesLabel, uniqueWordsLabel, characterLabel, sentencesLabel, charactersWithoutSpacesLabel, spacesLabel, turnOnBtn;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"firstTimeRunning", nil]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    /*
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    */
    
    popupShowed = NO;
    isOn = NO;
    
    [aboutWindow orderOut:self];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:mainMenu];
    [statusItem setHighlightMode:YES];
    statusItem.enabled = YES;
    [statusItem setToolTip:@"Word-Counter"];  // app name
    [statusItem setImage:[NSImage imageNamed:@"MenuBarIcon.png"]];
    [[statusItem image] setTemplate:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(openPopUp:)];
    
    // For dark mode in yosemite
    SInt32 OSXversionMajor, OSXversionMinor;
    if (Gestalt(gestaltSystemVersionMajor, &OSXversionMajor) == noErr && Gestalt(gestaltSystemVersionMinor, &OSXversionMinor) == noErr) {
        
        if (OSXversionMajor == 10 && OSXversionMinor >= 10) {
            
            [statusItem.image setTemplate:YES];
        }
    }
    
    // check if app is running for the first time
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeRunning"] == YES) {
        
        [self openPopUp:nil];
        
        BOOL firstTimeRun = NO;
        
        [[NSUserDefaults standardUserDefaults] setBool:firstTimeRun forKey:@"firstTimeRunning"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    [self coloredTitleButton:raresBtn andColor:[NSColor blueColor]];
    [self coloredTitleButton:websiteBtn andColor:[NSColor blueColor]];
}



// ========================================
// take string from the paste board (cmd+c)
// ========================================
- (NSString *)stringForType {
    
    NSPasteboard *myPasteboard  = [NSPasteboard generalPasteboard];
    
    selectedText = [myPasteboard  stringForType:NSPasteboardTypeString];
    
    return selectedText;
}



// =============================================
// turn on or of the app (show the counter view)
// =============================================
- (IBAction)clickedTurnOn:(id)sender {
        
    if (isOn == NO) {
        
        isOn = YES;
        
        [turnOnBtn setTitle:@"Turn Off"];
                
        NSScreen *screen = [NSScreen mainScreen];
        
        [counterWindow setFrame:NSMakeRect(screen.frame.size.width - counterWindow.frame.size.width, screen.frame.size.height - counterWindow.frame.size.height, counterWindow.frame.size.width, counterWindow.frame.size.height) display:YES];
        
        [counterWindow setCollectionBehavior:NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces |NSWindowCollectionBehaviorFullScreenAuxiliary];
        
        [counterWindow setLevel: NSStatusWindowLevel];
            
        [counterWindow makeKeyAndOrderFront:self];
        
        myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTick) userInfo:nil repeats:YES];
    }
    else {
        
        isOn = NO;
        
        [turnOnBtn setTitle:@"Turn On"];
        
        [counterWindow orderOut:nil];
        
        if (myTimer != nil) {
            
            [myTimer invalidate];
            
            myTimer = nil;
        }
    }
}



// ============================
// refresh every second numbers
// ============================
- (void)onTick {
   
    [self stringForType];
    
    [self showNumbers];
}



// ===================
// get number of lines
// ===================
- (NSUInteger)numberOfLines {
    
    NSString *string = selectedText;
    NSUInteger numberOfLines = 0;
    NSRange searchRange = NSMakeRange(0, 0);
    
    while (searchRange.location < [string length]) {
        
        searchRange.location = NSMaxRange([string lineRangeForRange:searchRange]);
        numberOfLines++;
    }
    
    return numberOfLines;
}



// ===================
// get number of words
// ===================
- (NSUInteger)numberOfWords {
    
    NSString *string = selectedText;
    __block NSUInteger numberOfWords = 0;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByWords
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                numberOfWords++;
                            }];
    return numberOfWords;
}



// ==========================
// get number of unique words
// ==========================
- (NSUInteger)numberOfUniqueWords {
    
    NSString *string = [selectedText lowercaseString];
    NSMutableSet *uniqueWords = [NSMutableSet set];
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByWords
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                [uniqueWords addObject:substring];
                            }];
    
    return [uniqueWords count];
}



// =======================
// get number of sentences
// =======================
- (NSUInteger)numberOfSentences {
    
    NSString *string = selectedText;
    __block NSUInteger numberOfSentences = 0;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationBySentences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                numberOfSentences++;
                            }];
    
    return numberOfSentences;
}



// ========================
// get number of characters
// ========================
- (NSUInteger)numberOfCharacters {
    
    NSString *string = selectedText;
    
    return [string length];
}



// =======================================
// get number of characters without spaces
// =======================================
- (NSUInteger)numberOfCharactersWithoutSpaces {
    
    NSString *string = selectedText;
    
    int times = (int)[[string componentsSeparatedByString:@" "] count] -1;
    
    int number = (int)[string length] - times;
    
    return number;
}



// ====================
// get number of spaces
// ====================
- (NSUInteger)numberOfSpaces {
    
    NSString *string = selectedText;
    
    int times = (int)[[string componentsSeparatedByString:@" "] count] -1;
    
    return times;
}



// ======================
// show numbers in labels
// ======================
- (void)showNumbers {
    
    [sentencesLabel setStringValue:[NSString stringWithFormat:@"Sentences: %lu", (unsigned long)[self numberOfSentences]]];
    [linesLabel setStringValue:[NSString stringWithFormat:@"Lines: %lu",(unsigned long)[self numberOfLines]]];
    [wordsLabel setStringValue:[NSString stringWithFormat:@"Words: %lu", (unsigned long)[self numberOfWords]]];
    [uniqueWordsLabel setStringValue:[NSString stringWithFormat:@"Unique words: %lu", (unsigned long)[self numberOfUniqueWords]]];
    [characterLabel setStringValue:[NSString stringWithFormat:@"Characters: %lu", (unsigned long)[self numberOfCharacters]]];
    [charactersWithoutSpacesLabel setStringValue:[NSString stringWithFormat:@"Characters without spaces: %lu", (unsigned long)[self numberOfCharactersWithoutSpaces]]];
    [spacesLabel setStringValue:[NSString stringWithFormat:@"Spaces: %lu", (unsigned long)[self numberOfSpaces]]];
}



// ========================
// show popUp from menu bar
// ========================
- (void)openPopUp:(id)sender {
    
    if (![counterWindow isVisible]) {
        isOn = NO;
        
        [turnOnBtn setTitle:@"Turn On"];
        
    }
    else {
        isOn = YES;
        
        [turnOnBtn setTitle:@"Turn Off"];
    }
    
    if (popupShowed == NO) {
        
        NSRect frame = [[statusItem valueForKey:@"window"] frame];
        
        NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
        attachedWindow = [[MAAttachedWindow alloc] initWithView:popUpView
                                                attachedToPoint:pt
                                                       inWindow:nil
                                                         onSide:MAPositionBottom
                                                     atDistance:5.0];
        
        attachedWindow.appDelegateObject = self;
        
        [attachedWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
        
        popupShowed = YES;
    }
    else {
        
        [attachedWindow orderOut:nil];
        
        popupShowed = NO;
    }
}


// =================
// show about window
// =================
- (IBAction)clickedAbout:(id)sender {

    [aboutWindow makeKeyAndOrderFront:self];
}



// =========================
// set color to buttons text
// =========================
- (void)coloredTitleButton:(NSButton *)myButton andColor: (NSColor *)myColor {
    
    NSColor *color = myColor;
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[myButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [myButton setAttributedTitle:colorTitle];
}



// ==================
// send mail to rares
// ==================
- (IBAction)clickedRaresContact:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"mailto:office@caffeinatetech.com"]];
}

// ========================
// send user to our website
// ========================
- (IBAction)clickedWebsite:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://www.caffeinatetech.com"]];
}


@end
