//
//  TemporaryTests.m
//  TemporaryTests
//
//  Created by Michael Conrads on 24/04/14.
//
//

#import <XCTest/XCTest.h>
#import "MCOFolderScanner.h"
#import <sys/types.h>
#import <pwd.h>

@interface TemporaryTests : XCTestCase

@end

@implementation TemporaryTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test_makeFolder_folderDoesNotExist_folderExists
{
    
    NSString *folderName = [self tmpFolderPathContainingTimestamp];
    
    //call
    [self make_folderAtPath:folderName];
    BOOL folderExists = [[NSFileManager defaultManager] fileExistsAtPath:folderName];
    //assert
    XCTAssert(folderExists, @"Error creating a new folder in tmp");
    [self delete_folderAtPath:folderName];
}

- (void)test_deleteFolder_folderExists_folderIsDeleted
{
    //setup
    NSString *folderPath = [self tmpFolderPathContainingTimestamp];
    BOOL folderExistsBefore = [[NSFileManager defaultManager] fileExistsAtPath:folderPath];
    
    //call
    [self make_folderAtPath:folderPath];
    [self delete_folderAtPath:folderPath];
    
    //assert
    BOOL folderExistsAfter = [[NSFileManager defaultManager] fileExistsAtPath:folderPath];
    XCTAssert(folderExistsBefore == NO, @"Folder already exists");
    XCTAssert(folderExistsAfter == NO, @"Folder has not been deleted correctly");
}



- (void)test_ageOfFolder_newFolder_ageIsBelow10Seconds
{
    //setup
    NSString *testFolderPath = [self tmpFolderPathContainingTimestamp];
    [self make_folderAtPath:testFolderPath];
    NSTimeInterval tenSeconds = 10;
    MCOFolderScanner *sut = [[MCOFolderScanner alloc] init];
    
    //call
    NSTimeInterval folderAge = [sut ageOfFolderAtPath:testFolderPath];
    [self delete_folderAtPath:testFolderPath];
    
    //assert
    XCTAssert(folderAge < tenSeconds, @"age of new folder is large than 10 seconds");
}

- (void)test_moveToTrash_folderExistsAtPath_folderIsMovedToTrash
{
    //setup
    MCOFolderScanner *sut = [[MCOFolderScanner alloc] init];
    NSString *trashDirectory = [[self pathToUserHomeDirectory] stringByAppendingPathComponent:@".Trash"];
    NSString *folderName = [self testFolderNameWithTimeStamp];
    NSString *testFolderPath = [NSString stringWithFormat:@"/tmp/%@",folderName];
    [self make_folderAtPath:testFolderPath];
    
    //call
    [sut moveToTrash:testFolderPath];
    
    //assert
    BOOL folderExistsInOldLocation = [[NSFileManager defaultManager] fileExistsAtPath:testFolderPath];
    BOOL folderIsInTrash = [[NSFileManager defaultManager] fileExistsAtPath:[trashDirectory stringByAppendingPathComponent:folderName]];
    XCTAssert(folderExistsInOldLocation == NO, @"Folder not moved from old location");
    XCTAssert(folderIsInTrash == YES, @"Folder has not been moved to trash");
}



- (NSString *)pathToUserHomeDirectory
{
    struct passwd *pw = getpwuid(getuid());
    return [NSString stringWithUTF8String:pw->pw_dir];
}


- (NSString *)tmpFolderPathContainingTimestamp
{
    return [NSString stringWithFormat:@"/tmp/%@",[self testFolderNameWithTimeStamp]];
}

- (NSString *)testFolderNameWithTimeStamp
{
    return [NSString stringWithFormat:@"TemporaryTest_%li",(NSUInteger)[[NSDate date] timeIntervalSinceReferenceDate]];
}


- (void)delete_folderAtPath:(NSString *)path
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path
                                               error:&error];
    NSLog(@"error deleting: %@",error);
}

- (void)make_folderAtPath:(NSString *)path
{
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
}
@end
