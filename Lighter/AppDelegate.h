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
    
    NSString *selectedText;
    
    NSTimer *myTimer;
}


@property(retain)MAAttachedWindow *attachedWindow;;

@property(assign)BOOL popupShowed;

// about view
@property (weak) IBOutlet NSPanel *aboutWindow;

@property (weak) IBOutlet NSButton *raresBtn;

@property (weak) IBOutlet NSButton *websiteBtn;

@property (weak) IBOutlet NSView *popUpView;

@property (weak) IBOutlet NSButton *turnOnBtn;


// count window
@property (weak) IBOutlet NSPanel *counterWindow;

@property (weak) IBOutlet NSTextField *sentencesLabel;

@property (weak) IBOutlet NSTextField *linesLabel;

@property (weak) IBOutlet NSTextField *wordsLabel;

@property (weak) IBOutlet NSTextField *uniqueWordsLabel;

@property (weak) IBOutlet NSTextField *characterLabel;

@property (weak) IBOutlet NSTextField *charactersWithoutSpacesLabel;

@property (weak) IBOutlet NSTextField *spacesLabel;


// about view
- (IBAction)clickedAbout:(id)sender;

- (IBAction)clickedRaresContact:(id)sender;

- (IBAction)clickedWebsite:(id)sender;

- (IBAction)clickedTurnOn:(id)sender;

@end

