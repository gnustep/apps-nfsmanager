//
//  NFSImportParameters.h
//  NFSManager
//
//  Created by Gregory John Casamento on 9/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NFSImportParameters : NSObject <NSCopying>
{
    // Imports
    
    NSString  *_serverName;
    NSString  *_serverDirectory;
    NSString  *_mountPoint;
    NSUInteger _mountFileSystemIndex;
    NSUInteger _setuidIndex;
    NSUInteger _mountThreadIndex;
    NSUInteger _retryIndex;
    
    // Expert options...
    
    NSUInteger _mountTimeout;
    NSUInteger _mountRetries;
    NSUInteger _nfsTimeout;
    NSUInteger _nfsRetries;
    NSUInteger _readBufferSize;
    NSUInteger _writeBufferSize;
    NSString  *_serverIPPort;
}

// Imports...

- (void) setServerName: (NSString *)serverName;
- (NSString *) serverName;

- (void) setServerDirectory: (NSString *)serverDirectory;
- (NSString *) serverDirectory;

- (void) setMountPoint: (NSString *)mountPoint;
- (NSString *) mountPoint;

- (void) setMountFileSystemIndex: (NSUInteger)index;
- (NSUInteger) mountFileSystemIndex;

- (void) setSetuidIndex: (NSUInteger)index;
- (NSUInteger) setuidIndex;

- (void) setMountThreadIndex: (NSUInteger)index;
- (NSUInteger) mountThreadIndex;

- (void) setRetryIndex: (NSUInteger)index;
- (NSUInteger) retryIndex;

// Exoert options...

- (void) setMountTimeout: (NSUInteger)timeout;
- (NSUInteger) mountTimeout;

- (void) setMountRetries: (NSUInteger)retries;
- (NSUInteger) mountRetries;

- (void) setNFSTimeout: (NSUInteger)timeout;
- (NSUInteger) nfsTimeout;

- (void) setNFSRetries: (NSUInteger)retries;
- (NSUInteger) nfsRetries;

- (void) setReadBufferSize: (NSUInteger)size;
- (NSUInteger) readBufferSize;

- (void) setWriteBufferSize: (NSUInteger)size;
- (NSUInteger) writeBufferSize;

- (void) setServerIPPort: (NSString *)port;
- (NSString *) serverIPPort;

@end

NS_ASSUME_NONNULL_END
