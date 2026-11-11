#import <Foundation/Foundation.h>
#import <mach/mach_time.h>

typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
typedef struct __IOHIDEvent *IOHIDEventRef;

typedef struct {
    void (*notification)(void *target, void *context, IOHIDServiceClientRef service, uint32_t type, CFDictionaryRef property);
    bool (*setProperty)(void *target, void *context, IOHIDServiceClientRef service, CFStringRef key, CFTypeRef value);
    CFTypeRef (*copyProperty)(void *target, void *context, IOHIDServiceClientRef service, CFStringRef key);
    IOHIDEventRef (*copyEvent)(void *target, void *context, IOHIDServiceClientRef service, uint32_t type, IOHIDEventRef matching, uint32_t options);
    int (*setOutputEvent)(void *target, void *context, IOHIDServiceClientRef service, IOHIDEventRef event);
} VirtualServiceCallbacks;

extern IOHIDEventSystemClientRef IOHIDEventSystemClientCreateWithType(CFAllocatorRef allocator, uint32_t type, CFDictionaryRef attributes);
extern void IOHIDEventSystemClientSetDispatchQueue(IOHIDEventSystemClientRef client, dispatch_queue_t queue);
extern void IOHIDEventSystemClientActivate(IOHIDEventSystemClientRef client);
extern IOHIDServiceClientRef IOHIDVirtualServiceClientCreateWithCallbacks(IOHIDEventSystemClientRef client, CFDictionaryRef attributes, VirtualServiceCallbacks *callbacks, void *target, void *context);
extern Boolean IOHIDVirtualServiceClientDispatchEvent(IOHIDServiceClientRef service, IOHIDEventRef event);
extern IOHIDEventRef IOHIDEventCreateVendorDefinedEvent(CFAllocatorRef allocator, uint64_t timestamp, uint32_t usagePage, uint32_t usage, uint32_t version, const uint8_t *data, CFIndex length, uint32_t options);
extern IOHIDEventRef IOHIDEventCreateKeyboardEvent(CFAllocatorRef allocator, uint64_t timestamp, uint32_t usagePage, uint32_t usage, Boolean down, uint32_t options);
extern CFDataRef IOCFSerialize(CFTypeRef object, CFOptionFlags options);

static const uint32_t kControlUsagePage = 0xFF61;
static const uint32_t kControlUsage = 0x5B;
static const uint32_t kClientTypeSimple = 4;
static const CFOptionFlags kSerializeToBinary = 1;

static NSDictionary *serviceProperties;
static BOOL verbose;

static void logLine(NSString *line) {
    if (verbose) { fprintf(stderr, "duo-hinge: %s\n", line.UTF8String); }
}

static void onNotification(void *target, void *context, IOHIDServiceClientRef service, uint32_t type, CFDictionaryRef property) {
    logLine([NSString stringWithFormat:@"service notification %u", type]);
}

static bool onSetProperty(void *target, void *context, IOHIDServiceClientRef service, CFStringRef key, CFTypeRef value) {
    return true;
}

static CFTypeRef onCopyProperty(void *target, void *context, IOHIDServiceClientRef service, CFStringRef key) {
    id value = serviceProperties[(__bridge NSString *)key];
    return value ? CFBridgingRetain(value) : NULL;
}

static IOHIDEventRef onCopyEvent(void *target, void *context, IOHIDServiceClientRef service, uint32_t type, IOHIDEventRef matching, uint32_t options) {
    return NULL;
}

static int onSetOutputEvent(void *target, void *context, IOHIDServiceClientRef service, IOHIDEventRef event) {
    return 0;
}

static BOOL dispatchControl(IOHIDServiceClientRef service, NSDictionary *control) {
    NSData *payload = CFBridgingRelease(IOCFSerialize((__bridge CFTypeRef)control, kSerializeToBinary));
    if (payload.length == 0 || payload.length > 256) {
        fprintf(stderr, "duo-hinge: payload of %lu bytes is outside the relay's 1...256 limit\n", (unsigned long)payload.length);
        return NO;
    }
    IOHIDEventRef event = IOHIDEventCreateVendorDefinedEvent(kCFAllocatorDefault, mach_absolute_time(), kControlUsagePage, kControlUsage, 0, payload.bytes, (CFIndex)payload.length, 0);
    if (!event) { return NO; }
    Boolean sent = IOHIDVirtualServiceClientDispatchEvent(service, event);
    CFRelease((CFTypeRef)event);
    logLine([NSString stringWithFormat:@"%@ -> %@", control, sent ? @"sent" : @"NOT sent"]);
    return sent;
}

static BOOL dispatchStandby(IOHIDServiceClientRef service, BOOL showing) {
    IOHIDEventRef event = IOHIDEventCreateKeyboardEvent(kCFAllocatorDefault, mach_absolute_time(), kControlUsagePage, kControlUsage, showing, 0);
    if (!event) { return NO; }
    Boolean sent = IOHIDVirtualServiceClientDispatchEvent(service, event);
    CFRelease((CFTypeRef)event);
    logLine([NSString stringWithFormat:@"standby %d -> %@", showing, sent ? @"sent" : @"NOT sent"]);
    return sent;
}

static void usage(void) {
    fprintf(stderr,
        "usage: duo-hinge <angle> [options]\n"
        "  <angle>                 hinge angle in degrees: 0 closed, 180 open flat\n"
        "  --from <angle>          sweep from this angle instead of jumping\n"
        "  --duration <seconds>    sweep duration (default 0.6 with --from)\n"
        "  --orientation <name>    also set portrait, pud, landscape-left, landscape-right, faceup, facedown or ambiguous\n"
        "  --standby <0|1>         also report the StandBy state\n"
        "  --hold <seconds>        keep the virtual service alive this long after the last event (default 1)\n"
        "  --verbose\n");
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSMutableArray<NSString *> *arguments = [NSMutableArray array];
        for (int index = 1; index < argc; index++) { [arguments addObject:@(argv[index])]; }

        NSString *angleArgument;
        NSString *fromArgument;
        NSString *orientation;
        NSString *standby;
        double duration = 0.6;
        double hold = 1;
        for (NSUInteger index = 0; index < arguments.count; index++) {
            NSString *argument = arguments[index];
            NSString *(^next)(void) = ^NSString *{
                return index + 1 < arguments.count ? arguments[index + 1] : nil;
            };
            if ([argument isEqualToString:@"--verbose"]) { verbose = YES; }
            else if ([argument isEqualToString:@"--from"]) { fromArgument = next(); index++; }
            else if ([argument isEqualToString:@"--duration"]) { duration = next().doubleValue; index++; }
            else if ([argument isEqualToString:@"--orientation"]) { orientation = next(); index++; }
            else if ([argument isEqualToString:@"--standby"]) { standby = next(); index++; }
            else if ([argument isEqualToString:@"--hold"]) { hold = next().doubleValue; index++; }
            else if (!angleArgument && ![argument hasPrefix:@"--"]) { angleArgument = argument; }
            else { usage(); return 64; }
        }
        if (!angleArgument) { usage(); return 64; }
        double angle = angleArgument.doubleValue;
        if (angle < 0 || angle > 180) {
            fprintf(stderr, "duo-hinge: angle must be between 0 and 180\n");
            return 64;
        }

        serviceProperties = @{
            @"PrimaryUsagePage": @(kControlUsagePage),
            @"PrimaryUsage": @(kControlUsage),
            @"DeviceUsagePage": @(kControlUsagePage),
            @"DeviceUsage": @(kControlUsage),
            @"DeviceUsagePairs": @[@{@"DeviceUsagePage": @(kControlUsagePage), @"DeviceUsage": @(kControlUsage)}],
            @"VendorID": @0,
            @"ProductID": @0,
            @"Transport": @"Virtual",
            @"Product": @"duo-hinge",
            @"PhysicalDeviceUniqueID": @"duo-hinge",
        };

        dispatch_queue_t queue = dispatch_queue_create("duo-hinge", DISPATCH_QUEUE_SERIAL);
        IOHIDEventSystemClientRef client = IOHIDEventSystemClientCreateWithType(kCFAllocatorDefault, kClientTypeSimple, NULL);
        if (!client) {
            fprintf(stderr, "duo-hinge: could not connect to the HID event system\n");
            return 1;
        }
        IOHIDEventSystemClientSetDispatchQueue(client, queue);
        IOHIDEventSystemClientActivate(client);

        static VirtualServiceCallbacks callbacks = { onNotification, onSetProperty, onCopyProperty, onCopyEvent, onSetOutputEvent };
        IOHIDServiceClientRef service = IOHIDVirtualServiceClientCreateWithCallbacks(client, (__bridge CFDictionaryRef)serviceProperties, &callbacks, NULL, NULL);
        if (!service) {
            fprintf(stderr, "duo-hinge: the HID event system refused the virtual service\n");
            return 1;
        }
        logLine(@"virtual service registered");
        [NSThread sleepForTimeInterval:0.5];

        BOOL delivered = YES;
        if (orientation) {
            delivered &= dispatchControl(service, @{@"source": @"orientation-picker-control", @"type": @"enum", @"value": orientation});
        }
        if (standby) {
            delivered &= dispatchStandby(service, standby.boolValue);
        }

        if (fromArgument) {
            double from = fromArgument.doubleValue;
            int steps = MAX(1, (int)(duration * 60));
            for (int step = 0; step <= steps; step++) {
                double progress = (double)step / steps;
                double eased = progress * progress * (3 - 2 * progress);
                delivered &= dispatchControl(service, @{@"source": @"hinge-slider-control", @"type": @"range", @"value": @(from + (angle - from) * eased)});
                [NSThread sleepForTimeInterval:duration / steps];
            }
        } else {
            delivered &= dispatchControl(service, @{@"source": @"hinge-slider-control", @"type": @"range", @"value": @(angle)});
        }

        [NSThread sleepForTimeInterval:hold];
        if (!delivered) {
            fprintf(stderr, "duo-hinge: at least one event was not accepted\n");
            return 1;
        }
        printf("hinge %.1f\n", angle);
        return 0;
    }
}
