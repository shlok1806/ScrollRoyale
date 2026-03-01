#import <Capacitor/Capacitor.h>

CAP_PLUGIN(ScrollRoyalePlugin, "ScrollRoyale",
    CAP_PLUGIN_METHOD(createMatch,      CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(joinMatch,        CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(getMatch,         CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(leaveMatch,       CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(fetchContentFeed, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(connect,          CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(disconnect,       CAPPluginReturnNone);
    CAP_PLUGIN_METHOD(sendGameState,    CAPPluginReturnNone);
    CAP_PLUGIN_METHOD(sendTelemetry,    CAPPluginReturnPromise);
)
