#import "ManageInstall.h"
#import <manage_install/manage_install-Swift.h>

@implementation ManageInstall
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftInstallPlugin registerWithRegistrar:registrar];
}
@end
