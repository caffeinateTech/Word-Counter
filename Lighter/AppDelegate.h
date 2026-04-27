//
//  AppDelegate.h
//  PercentCalculator
//
//  Created by Rares Tamas on 12/17/14.
//  Copyright (c) 2014 Rares Tamas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MAAttachedWindow.h"


@interface AppDelegate : NSObject <NSApplicationDelegate> {
    
    MAAttachedWindow *attachedWindow;
    
    NSStatusItem *statusItem;
    
    NSWindow *window;
    
    NSMenu *mainMenu;
    
    BOOL popupShowed;
    
    BOOL isOn;
    
    BOOL isWindowExpanded;
    
    BOOL isDarkTheme;
    
    NSString *selectedText;
    
    NSTimer *myTimer;
    
    NSTimer *debounceTimer;
    
    NSTimer *interactionInactivityTimer;
    
    id interactionMonitor;
    
    BOOL isCompactMode;
    
    NSRect lastExpandedWindowFrame;
    
    BOOL hasLastExpandedWindowFrame;
    
    NSWindowStyleMask originalCounterWindowStyleMask;
    
    BOOL hasOriginalCounterWindowStyleMask;
    
    NSView *fullCounterContentView;
    
    NSView *compactCounterContentView;
    
    NSMutableArray *compactMetricValueLabels;
    
    NSColor *originalCounterWindowBackgroundColor;
    
    BOOL wasWindowExpandedBeforeCompact;
    
    NSArray<NSTextField *> *compactMetricLabels;
    
    NSInteger lastPasteboardChangeCount;
}


@property(retain)MAAttachedWindow *attachedWindow;;

@property(assign)BOOL popupShowed;

// about view
@property (weak) IBOutlet NSPanel *aboutWindow;

@property (weak) IBOutlet NSButton *raresBtn;

@property (weak) IBOutlet NSButton *websiteBtn;

@property (weak) IBOutlet NSView *popUpView;

@property (weak) IBOutlet NSButton *turnOnBtn;

@property (weak) IBOutlet NSButton *onShowAdvancedButton;

@property (weak) IBOutlet NSButton *cutResultsButton;

@property (weak) IBOutlet NSButton *themeButton;

@property (weak) IBOutlet NSButton *quitButton;

@property (weak) IBOutlet NSButton *aboutButton;

@property (weak) IBOutlet NSTextField *aboutTextField;

@property (weak) IBOutlet NSButton *launchAtLoginCheckboxButton;

@property (weak) IBOutlet NSButton *autoMinimizeCheckboxButton;


// count window
@property (weak) IBOutlet NSPanel *counterWindow;

@property (weak) IBOutlet NSTextField *sentencesLabel;

@property (weak) IBOutlet NSTextField *linesLabel;

@property (weak) IBOutlet NSTextField *wordsLabel;

@property (weak) IBOutlet NSTextField *uniqueWordsLabel;

@property (weak) IBOutlet NSTextField *characterLabel;

@property (weak) IBOutlet NSTextField *charactersWithoutSpacesLabel;

@property (weak) IBOutlet NSTextField *spacesLabel;

@property (weak) IBOutlet NSTextField *readingTimeLabel;

@property (weak) IBOutlet NSTextField *syllableCountLabel;

@property (weak) IBOutlet NSTextField *lettersLabel;

@property (weak) IBOutlet NSTextField *websiteTitleLabel;

@property (weak) IBOutlet NSTextField *contactTitleLabel;

// about view
- (IBAction)clickedAbout:(id)sender;

- (IBAction)clickedRaresContact:(id)sender;

- (IBAction)clickedWebsite:(id)sender;

- (IBAction)clickedTurnOn:(id)sender;

- (IBAction)onShowAdvancedButtonClick:(id)sender;

- (IBAction)onCopyButtonClicked:(id)sender;

- (IBAction)onThemeButtonClicked:(id)sender;

@end

