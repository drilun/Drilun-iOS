//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "MockSSKEnvironment.h"
#import "OWSBatchMessageProcessor.h"
#import "OWSBlockingManager.h"
#import "OWSFakeCallMessageHandler.h"
#import "OWSFakeContactsManager.h"
#import "OWSFakeContactsUpdater.h"
#import "OWSFakeMessageSender.h"
#import "OWSFakeNetworkManager.h"
#import "OWSFakeNotificationsManager.h"
#import "OWSFakeProfileManager.h"
#import "OWSIdentityManager.h"
#import "OWSMessageDecrypter.h"
#import "OWSMessageManager.h"
#import "OWSMessageReceiver.h"
#import "OWSPrimaryStorage.h"
#import "TSAccountManager.h"
#import "TSSocketManager.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG

@interface OWSPrimaryStorage (Tests)

@property (atomic) BOOL areAsyncRegistrationsComplete;
@property (atomic) BOOL areSyncRegistrationsComplete;

@end

#pragma mark -

@implementation MockSSKEnvironment

+ (void)activate
{
    MockSSKEnvironment *instance = [self new];
    [self setShared:instance];
    [instance configure];
}

- (instancetype)init
{
    OWSPrimaryStorage *primaryStorage = [MockSSKEnvironment createPrimaryStorageForTests];
    id<ContactsManagerProtocol> contactsManager = [OWSFakeContactsManager new];
    TSNetworkManager *networkManager = [OWSFakeNetworkManager new];
    OWSMessageSender *messageSender = [OWSFakeMessageSender new];

    OWSMessageManager *messageManager = [[OWSMessageManager alloc] initWithPrimaryStorage:primaryStorage];
    OWSBlockingManager *blockingManager = [[OWSBlockingManager alloc] initWithPrimaryStorage:primaryStorage];
    OWSIdentityManager *identityManager = [[OWSIdentityManager alloc] initWithPrimaryStorage:primaryStorage];
    id<OWSUDManager> udManager = [[OWSUDManagerImpl alloc] initWithPrimaryStorage:primaryStorage];
    OWSMessageDecrypter *messageDecrypter = [[OWSMessageDecrypter alloc] initWithPrimaryStorage:primaryStorage];
    OWSBatchMessageProcessor *batchMessageProcessor =
        [[OWSBatchMessageProcessor alloc] initWithPrimaryStorage:primaryStorage];
    OWSMessageReceiver *messageReceiver = [[OWSMessageReceiver alloc] initWithPrimaryStorage:primaryStorage];
    TSSocketManager *socketManager = [[TSSocketManager alloc] init];
    TSAccountManager *tsAccountManager = [[TSAccountManager alloc] initWithPrimaryStorage:primaryStorage];

    self = [super initWithContactsManager:contactsManager
                            messageSender:messageSender
                           profileManager:[OWSFakeProfileManager new]
                           primaryStorage:primaryStorage
                          contactsUpdater:[OWSFakeContactsUpdater new]
                           networkManager:networkManager
                           messageManager:messageManager
                          blockingManager:blockingManager
                          identityManager:identityManager
                                udManager:udManager
                         messageDecrypter:messageDecrypter
                    batchMessageProcessor:batchMessageProcessor
                          messageReceiver:messageReceiver
                            socketManager:socketManager
                         tsAccountManager:tsAccountManager];
    if (!self) {
        return nil;
    }
    self.callMessageHandler = [OWSFakeCallMessageHandler new];
    self.notificationsManager = [OWSFakeNotificationsManager new];
    return self;
}

+ (OWSPrimaryStorage *)createPrimaryStorageForTests
{
    OWSPrimaryStorage *primaryStorage = [[OWSPrimaryStorage alloc] initStorage];
    [OWSPrimaryStorage protectFiles];
    return primaryStorage;
}

- (void)configure
{
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [OWSStorage registerExtensionsWithMigrationBlock:^() {
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

@end

#endif

NS_ASSUME_NONNULL_END
