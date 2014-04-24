//
//  MCOAppDelegate.m
//  Temporary
//
//  Created by Michael Conrads on 24/04/14.
//
//

#import "MCOAppDelegate.h"

@interface MCOAppDelegate ()
@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (unsafe_unretained) IBOutlet NSPanel *preferencesPanel;

@property (weak) IBOutlet NSMenu *menu;
@property (nonatomic, strong, readwrite) NSTimer *timer;

@property (nonatomic, assign, readwrite) NSTimeInterval timeIntervalToCheck;
@property (nonatomic, strong, readwrite) NSString *pathToTempDirectory;
@property (weak) IBOutlet NSButton *startAtLoginCheckbox;

@property (weak) IBOutlet NSTextField *textfield;
@property (nonatomic, strong, readwrite) NSOpenPanel *openPanel;
@property (nonatomic, assign, readwrite) BOOL startAtLogin;
@end

NSString * const MCOAppDelegateTempDirectoryPathKey = @"de.pre-apha.Temporary.MCOAppDelegateTempDirectoryPath";
NSString * const MCOAppDelegateStartAtLoginKey = @"de.pre-apha.Temporary.MCOAppDelegateStartAtLogin";

@implementation MCOAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.timeIntervalToCheck = 60 * 30;
    [NSApp activateIgnoringOtherApps:YES];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setTitle:@"⌛️"];
    [self.statusItem setToolTip:@"doing stuff..."];
    [self.statusItem setEnabled:YES];
    self.statusItem.menu = self.menu;
    

    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeIntervalToCheck
                                                  target:self
                                                selector:@selector(checkDirectory:)
                                                userInfo:nil
                                                 repeats:YES];

    self.pathToTempDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:MCOAppDelegateTempDirectoryPathKey];
    self.startAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey:MCOAppDelegateStartAtLoginKey];
}

- (void)checkDirectory:(id)userInfo
{
    if(self.pathToTempDirectory != nil)
    {
        NSError *error;
        NSArray *filesInTmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.pathToTempDirectory
                                                                                           error:&error];
        NSDate *now = [NSDate date];
        
        NSMutableArray *foldersToDelete = [NSMutableArray array];
        
        if(error == nil)
        {
            for (NSString *oneFilenameInDirectory in filesInTmpDirectory)
            {
                NSString *pathOfFileInDirectory = [self.pathToTempDirectory stringByAppendingPathComponent:oneFilenameInDirectory];
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathOfFileInDirectory
                                                                                                error:&error];
                
                
                NSDate *folderAge = fileAttributes[NSFileCreationDate];
                NSTimeInterval ageInSeconds = [now timeIntervalSinceDate:folderAge];
                
                
                NSTimeInterval secondsToLive = ({
                    NSScanner *s = [NSScanner scannerWithString:oneFilenameInDirectory];
                    [s scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                      intoString:nil];
                    
                    NSString *daysToLive;
                    BOOL scanned =[s scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                                intoString:&daysToLive];
                    
                    NSTimeInterval t = CGFLOAT_MAX;
                    if(scanned)
                    {
                        t = [daysToLive intValue] * 3600 * 24;
                    }
                    t;
                });
                
                if(secondsToLive < ageInSeconds)
                {
                    NSLog(@"deleting folder");
                    [foldersToDelete addObject:pathOfFileInDirectory];
                }
                
                NSLog(@"file/folder:%@   age: %f secondsToLife:%f",oneFilenameInDirectory,ageInSeconds,secondsToLive);
                
            }
            
            [self deleteFolders:foldersToDelete];
        }
        else
        {
            NSLog(@"error accessing folder: %@",error);
        }
        
    }
    else
    {
        NSLog(@"path not set");
    }
    
}

- (void)deleteFolders:(NSArray *)foldersToDelete
{
    
    NSError *removingFolderError;
    for (NSString *oneFolderToDelete in foldersToDelete) {
        

        [[NSFileManager defaultManager] removeItemAtPath:oneFolderToDelete
                                                   error:&removingFolderError];
        if(removingFolderError)
        {
            NSLog(@"error removing folder: %@", removingFolderError);
        }
    }
    
}

- (IBAction)preferencesClicked:(id)sender
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];

    [self.preferencesPanel makeKeyAndOrderFront:self.preferencesPanel];
    self.textfield.stringValue = self.pathToTempDirectory ? self.pathToTempDirectory  : @"";
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
        [self addAppAsLoginItem];
    }
    else
    {
        self.startAtLogin = NO;
        [self deleteAppFromLoginItem];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:self.startAtLogin
                                            forKey:MCOAppDelegateStartAtLoginKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



-(void) addAppAsLoginItem
{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];

	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];

	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems)
    {
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                     kLSSharedFileListItemLast, NULL, NULL,
                                                                     url, NULL, NULL);
		if (item)
        {
			CFRelease(item);
        }
	}
	CFRelease(loginItems);
}

-(void) deleteAppFromLoginItem
{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems)
    {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);

		for(int i = 0; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                        objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(__bridge NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
	}
}


- (IBAction)donePressed:(id)sender
{
    [self.preferencesPanel close];
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
    
    [self.openPanel beginWithCompletionHandler:^(NSInteger result) {
        if(result == NSFileHandlingPanelOKButton)
        {
            NSArray *a = [self.openPanel URLs];
            NSURL *url = [a firstObject];
            self.pathToTempDirectory = [url path];
            
            [[NSUserDefaults standardUserDefaults] setValue:self.pathToTempDirectory
                                                     forKey:MCOAppDelegateTempDirectoryPathKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.textfield.stringValue = self.pathToTempDirectory;
        }
    }];
    
}

@end
