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
    self.timeIntervalToCheck = 60 * 30; //every 30 minutes
    [NSApp activateIgnoringOtherApps:YES];
    
    self.statusItem = ({
        NSStatusItem *statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        statusBarItem.highlightMode = YES;
        statusBarItem.title = @"\u23F3"; //unicode hourglass
        
        //TODO: add tooltip
        [statusBarItem setEnabled:YES];
        statusBarItem.menu = self.menu;
        statusBarItem;
    });
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeIntervalToCheck
                                                  target:self
                                                selector:@selector(deleteOutdatedFilesInTempDirectory:)
                                                userInfo:nil
                                                 repeats:YES];

    self.pathToTempDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:MCOAppDelegateTempDirectoryPathKey];
    self.startAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey:MCOAppDelegateStartAtLoginKey];
}

- (void)deleteOutdatedFilesInTempDirectory:(id)userInfo
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
                
                NSTimeInterval secondsToLive = [self secondsRemainingForFileAtPath:oneFilenameInDirectory];
                
                if(secondsToLive < ageInSeconds)
                {
                    NSLog(@"deleting folder");
                    [foldersToDelete addObject:pathOfFileInDirectory];
                }
//              NSLog(@"file/folder:%@   age: %f secondsToLife:%f",oneFilenameInDirectory,ageInSeconds,secondsToLive);
            }
            [self deleteFilesAtPaths:foldersToDelete];
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


- (NSTimeInterval)secondsRemainingForFileAtPath:(NSString *)filePath
{
    NSScanner *s = [NSScanner scannerWithString:filePath];
    [s scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                      intoString:nil];
    
    NSString *daysToLive;
    BOOL didScanNumber =[s scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                intoString:&daysToLive];
    
    NSTimeInterval remainingSeconds = CGFLOAT_MAX;
    if(didScanNumber)
    {
        remainingSeconds = [daysToLive intValue] * 3600 * 24;
    }
    return remainingSeconds;
}

- (void)deleteFilesAtPaths:(NSArray *)pathsToDelete
{
    NSError *removeFileError;
    for (NSString *oneFolderToDelete in pathsToDelete) {
        

        [[NSFileManager defaultManager] removeItemAtPath:oneFolderToDelete
                                                   error:&removeFileError];
        if(removeFileError)
        {
            NSLog(@"error removing folder: %@", removeFileError);
        }
    }
    
}


#pragma mark - preferences changed

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



- (IBAction)donePressed:(id)sender
{
    [self.preferencesPanel close];
    [self deleteOutdatedFilesInTempDirectory:nil];
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

#pragma mark - login item

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


@end
