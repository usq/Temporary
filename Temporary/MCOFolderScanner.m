//
//  MCOFolderScanner.m
//  Temporary
//
//  Created by Michael Conrads on 09/05/14.
//
//

#import "MCOFolderScanner.h"
#import <sys/types.h>
#import <pwd.h>

@implementation MCOFolderScanner

- (NSTimeInterval)ageOfFolderAtPath:(NSString *)folderPath
{
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:folderPath
                                                                                error:&error];
    
    NSTimeInterval folderAge = CGFLOAT_MAX;
    if(error == nil)
    {
        NSDate *now = [NSDate date];
        NSDate *creationDate = attributes[NSFileCreationDate];
        folderAge = [now timeIntervalSinceDate:creationDate];
    }
    return folderAge;
}

- (void)moveToTrash:(NSString *)folderPath
{
    NSString *trashDirectory = [[self pathToUserHomeDirectory] stringByAppendingPathComponent:@".Trash"];
    NSString *folderName = [[folderPath componentsSeparatedByString:@"/"] lastObject];
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:folderPath
                                            toPath:[trashDirectory stringByAppendingPathComponent:folderName]
                                             error:&error];
}

- (NSString *)pathToUserHomeDirectory
{
    struct passwd *pw = getpwuid(getuid());
    return [NSString stringWithUTF8String:pw->pw_dir];
}


@end
