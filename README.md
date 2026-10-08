# DotNative.Permissions

Checks and requests four runtime permissions on Android and iOS.

```csharp
builder.Services.AddPermissions();
var permissions = services.GetRequiredService<IPermissions>();
var status = await permissions.RequestAsync(PermissionKind.Camera, cancellationToken);
if (status == PermissionStatus.Granted)
{
    // Start the camera feature.
}
```

Supported kinds are camera, microphone, foreground location, and notifications.
Statuses are `Granted`, `Denied`, `Restricted`, `PermanentlyDenied`, and
`NotDetermined`. Android distinguishes permanent denial after a request. iOS
reports denial but does not distinguish permanent denial from a regular denial.

| Platform | Status |
| --- | --- |
| Android | Camera, microphone, fine location and notifications (API 33+) |
| iOS | Camera, microphone, when-in-use location and user notifications |
| macOS | Not implemented |
| Windows | Not implemented |
| Linux | Not implemented |

Declare only the Android permissions the app uses in its manifest. Camera,
record audio, fine location, and Android 13+ notifications require the matching
`uses-permission` entries. On iOS, provide `NSCameraUsageDescription`,
`NSMicrophoneUsageDescription`, and `NSLocationWhenInUseUsageDescription` when
requesting those capabilities. DotNative does not inject permission declarations
or purpose strings. This port does not request background location, Bluetooth,
contacts, photos, or calendar access.

Upstream reference: [permission_handler](https://pub.dev/packages/permission_handler),
MIT. This DotNative implementation is independently authored and licensed MIT.
