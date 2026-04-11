#import "../../InstagramHeaders.h"
#import "../../Tweak.h"
#import "../../Utils.h"

// Seen buttons (in DMs)
// - Enables no seen for messages

// - Enables unlimited views of DM visual messages
%hook IGTallNavigationBarView
- (void)setRightBarButtonItems:(NSArray <UIBarButtonItem *> *)items {
    NSMutableArray *new_items = [[items filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(UIView *value, NSDictionary *_) {
            if ([SCIUtils getBoolPref:@"hide_reels_blend"]) {
                return ![value.accessibilityIdentifier isEqualToString:@"blend-button"];
            }

            return true;
        }]
    ] mutableCopy];

    UIMenu *seenActionsMenu = [UIMenu menuWithTitle:@"" children:@[
        [UIAction actionWithTitle:@"Mark messages as seen"
                            image:[UIImage systemImageNamed:@"checkmark.message"]
                       identifier:nil
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self seenButtonHandler:nil];
        }],
        [UIAction actionWithTitle:@"Toggle visual messages viewed"
                            image:[UIImage systemImageNamed:@"photo.badge.checkmark"]
                       identifier:nil
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self dmVisualMsgsViewedButtonHandler:nil];
        }]
    ]];

    UIBarButtonItem *dropdownButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis.circle"]
                                                                        menu:seenActionsMenu];
    [new_items addObject:dropdownButton];

}

// Messages seen button
%new - (void)seenButtonHandler:(UIBarButtonItem *)sender {
    UIViewController *nearestVC = [SCIUtils nearestViewControllerForView:self];
    if ([nearestVC isKindOfClass:%c(IGDirectThreadViewController)]) {
        [(IGDirectThreadViewController *)nearestVC markLastMessageAsSeen];

        [SCIUtils showToastForDuration:2.5 title:@"Marked messages as seen"];
    }
}
// DM visual messages viewed button
%new - (void)dmVisualMsgsViewedButtonHandler:(UIBarButtonItem *)sender {
    if (dmVisualMsgsViewedButtonEnabled) {
        dmVisualMsgsViewedButtonEnabled = false;
        [sender setTintColor:UIColor.labelColor];

        [SCIUtils showToastForDuration:4.5 title:@"Visual messages can be replayed without expiring"];
    }
    else {
        dmVisualMsgsViewedButtonEnabled = true;
        [sender setTintColor:SCIUtils.SCIColor_Primary];

        [SCIUtils showToastForDuration:4.5 title:@"Visual messages will now expire after viewing"];
    }
}
%end

// Messages seen logic
%hook IGDirectThreadViewListAdapterDataSource
- (BOOL)shouldUpdateLastSeenMessage {
    if ([SCIUtils getBoolPref:@"remove_lastseen"]) {
        return false;
    }
    
    return %orig;
}
%end

// DM stories viewed logic
%hook IGDirectVisualMessageViewerEventHandler
- (void)visualMessageViewerController:(id)arg1 didBeginPlaybackForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 {
    if ([SCIUtils getBoolPref:@"unlimited_replay"]) {
        // Check if dm stories should be marked as viewed
        if (dmVisualMsgsViewedButtonEnabled) {
            %orig;
        }
    }
}
- (void)visualMessageViewerController:(id)arg1 didEndPlaybackForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 mediaCurrentTime:(CGFloat)arg4 forNavType:(NSInteger)arg5 {
    if ([SCIUtils getBoolPref:@"unlimited_replay"]) {
        // Check if dm stories should be marked as viewed
        if (dmVisualMsgsViewedButtonEnabled) {
            %orig;
        }
    }
}
%end
