//
//  MCOAppDelegate.m
//  Temporary
//
//  Created by Michael Conrads on 24/04/14.
//
//

#import "MCOAppDelegate.h"
#import "MCOTemporaryFilesManager.h"
#import "MCOLoginItemsService.h"




NSString * const MCOAppDelegateTempDirectoryPathKey = @"de.pre-apha.Temporary.MCOAppDelegateTempDirectoryPath";
NSString * const MCOAppDelegateStartAtLoginKey = @"de.pre-apha.Temporary.MCOAppDelegateStartAtLogin";



@interface MCOAppDelegate ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSPanel *preferencesPanel;
@property (weak) IBOutlet NSMenu *menu;
@property (weak) IBOutlet NSButton *startAtLoginCheckbox;
@property (weak) IBOutlet NSTextField *pathTextfield;
@property (weak) IBOutlet NSTextField *timeTextfield;

@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (nonatomic, strong, readwrite) NSOpenPanel *openPanel;

@property (nonatomic, strong, readwrite) MCOTemporaryFilesManager *tempFilesManager;

@property (nonatomic, assign, readwrite) BOOL startAtLogin;
@end

@implementation MCOAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [NSApp activateIgnoringOtherApps:YES];
    
    self.statusItem = ({
        NSStatusItem *statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        statusBarItem.highlightMode = YES;
        NSString *unicodeBlackHourglass = @"\u29D7";
        statusBarItem.title = unicodeBlackHourglass;

        //TODO: add useful tooltip
        [statusBarItem setEnabled:YES];
        statusBarItem.menu = self.menu;
        statusBarItem;
    });


    self.tempFilesManager = [[MCOTemporaryFilesManager alloc] initWithPath:[[NSUserDefaults standardUserDefaults] stringForKey:MCOAppDelegateTempDirectoryPathKey]];
    
    self.startAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey:MCOAppDelegateStartAtLoginKey];
}



#pragma mark - preferences changed

- (IBAction)preferencesClicked:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
    
    [self.preferencesPanel makeKeyAndOrderFront:self.preferencesPanel];
    self.pathTextfield.stringValue = self.tempFilesManager.pathToTempDirectory;
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    [f setMinimumFractionDigits:1];
    [f setMaximumFractionDigits:2];
    [f setRoundingMode:NSNumberFormatterRoundUp];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    
    self.timeTextfield.stringValue = [f stringFromNumber:@(self.tempFilesManager.timeIntervalToCheck / 3600.f)];
    
    if(self.startAtLogin)
    {
        self.startAtLoginCheckbox.state = NSOnState;
    }
    else
    {
        self.startAtLoginCheckbox.state = NSOffState;
    }
}

- (IBAction)startAtLoginChanged:(id)sender
{
    if(self.startAtLoginCheckbox.state == NSOnState)
    {
        self.startAtLogin = YES;
        [MCOLoginItemsService addApplicationToLoginItems];
    }
    else
    {
        self.startAtLogin = NO;
        [MCOLoginItemsService removeApplicationFromLoginItems];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:self.startAtLogin
                                            forKey:MCOAppDelegateStartAtLoginKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)textfieldEdited:(id)sender
{
    self.tempFilesManager.timeIntervalToCheck = [self.timeTextfield floatValue] * 3600;
}

- (IBAction)donePressed:(id)sender
{
    [self.preferencesPanel close];
    self.tempFilesManager.timeIntervalToCheck = [self.timeTextfield floatValue] * 3600;
    [self.tempFilesManager deleteOutdatedFilesInTempDirectory];
}

- (IBAction)quitPressed:(id)sender
{
    [[NSRunningApplication currentApplication] terminate];
}

- (IBAction)selectFolderPressed:(id)sender
{
    if(self.openPanel == nil)
    {
        self.openPanel = [NSOpenPanel openPanel];
        self.openPanel.canChooseFiles = NO;
        self.openPanel.canChooseDirectories = YES;
        self.openPanel.canCreateDirectories = YES;
        self.openPanel.allowsMultipleSelection = NO;
    }
    
    [self.openPanel beginWithCompletionHandler:^(NSInteger result)
    {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSArray *a = [self.openPanel URLs];
            NSURL *url = [a firstObject];
            
            self.tempFilesManager.pathToTempDirectory = [url path];
            
            [[NSUserDefaults standardUserDefaults] setValue:self.tempFilesManager.pathToTempDirectory
                                                     forKey:MCOAppDelegateTempDirectoryPathKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            self.pathTextfield.stringValue = self.tempFilesManager.pathToTempDirectory;
        }
    }];
    
}


@end
