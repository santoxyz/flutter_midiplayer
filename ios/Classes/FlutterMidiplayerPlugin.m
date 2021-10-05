#import "FlutterMidiplayerPlugin.h"
#if __has_include(<flutter_midiplayer/flutter_midiplayer-Swift.h>)
#import <flutter_midiplayer/flutter_midiplayer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_midiplayer-Swift.h"
#endif

@implementation FlutterMidiplayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMidiplayerPlugin registerWithRegistrar:registrar];
}
@end
