//
//  NFSImportParameters.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/4/23.
//

#import "NFSImportParameters.h"

@implementation NFSImportParameters

- (instancetype) init
{
    self = [super init];
    
    if (self != nil)
    {
        _serverName = nil;
        _serverDirectory = nil;
        _serverIPPort = nil;
    }
    
    return self;
}


// Imports...

- (void) setServerName: (NSString *)serverName
{
#ifdef GNUSTEP
    ASSIGN(_serverName, serverName);
#else
    _serverName = serverName;
#endif
}

- (NSString *) serverName
{
    return _serverName;
}

- (void) setServerDirectory: (NSString *)serverDirectory
{
#ifdef GNUSTEP
    ASSIGN(_serverDirectory, serverDirectory);
#else
    _serverDirectory = serverDirectory;
#endif

}

- (NSString *) serverDirectory
{
    return _serverDirectory;
}

- (void) setMountPoint: (NSString *)mountPoint
{
#ifdef GNUSTEP
    ASSIGN(_mountPoint, mountPoint);
#else
    _mountPoint = mountPoint;
#endif
}

- (NSString *) mountPoint
{
    return _mountPoint;
}

- (void) setMountFileSystemIndex: (NSUInteger)index
{
    _mountFileSystemIndex = index;
}

- (NSUInteger) mountFileSystemIndex
{
    return _mountFileSystemIndex;
}

- (void) setSetuidIndex: (NSUInteger)index
{
    _setuidIndex = index;
}

- (NSUInteger) setuidIndex
{
    return _setuidIndex;
}

- (void) setMountThreadIndex: (NSUInteger)index
{
    _mountThreadIndex = index;
}

- (NSUInteger) mountThreadIndex
{
    return _mountThreadIndex;
}

- (void) setRetryIndex: (NSUInteger)index
{
    _retryIndex = index;
}

- (NSUInteger) retryIndex
{
    return _retryIndex;
}

// Exoert options...

- (void) setMountTimeout: (NSUInteger)timeout
{
    _mountTimeout = timeout;
}

- (NSUInteger) mountTimeout
{
    return _mountTimeout;
}

- (void) setMountRetries: (NSUInteger)retries
{
    _mountRetries = retries;
}

- (NSUInteger) mountRetries
{
    return _mountRetries;
}

- (void) setNFSTimeout: (NSUInteger)timeout
{
    _nfsTimeout = timeout;
}

- (NSUInteger) nfsTimeout
{
    return _nfsTimeout;
}

- (void) setNFSRetries: (NSUInteger)retries
{
    _nfsRetries = retries;
}

- (NSUInteger) nfsRetries;
{
    return _nfsRetries;
}

- (void) setReadBufferSize: (NSUInteger)size
{
    _readBufferSize = size;
}

- (NSUInteger) readBufferSize
{
    return _readBufferSize;
}

- (void) setWriteBufferSize: (NSUInteger)size
{
    _writeBufferSize = size;
}

- (NSUInteger) writeBufferSize
{
    return _writeBufferSize;
}

- (void) setServerIPPort: (NSString *)port
{
#ifdef GNUSTEP
    ASSIGN(_serverIPPort, port);
#else
    _serverIPPort = port;
#endif
}

- (NSString *) serverIPPort
{
    return _serverIPPort;
}

- (id) copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone: zone] init];

    if (copy != nil)
    {
        [copy setServerName: [self serverName]];
        [copy setServerDirectory: [self serverDirectory]];
        [copy setMountPoint: [self mountPoint]];
        [copy setMountFileSystemIndex: [self mountFileSystemIndex]];
        [copy setSetuidIndex: [self setuidIndex]];
        [copy setMountThreadIndex: [self mountThreadIndex]];
        [copy setRetryIndex: [self retryIndex]];
        [copy setMountTimeout: [self mountTimeout]];
        [copy setMountRetries: [self mountRetries]];
        [copy setNFSTimeout: [self nfsTimeout]];
        [copy setNFSRetries: [self nfsRetries]];
        [copy setReadBufferSize: [self readBufferSize]];
        [copy setWriteBufferSize: [self writeBufferSize]];
        [copy setServerIPPort: [self serverIPPort]];
    }

    return copy;
}

@end
