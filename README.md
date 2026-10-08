# DotNative.Permissions

Checks and requests four runtime permissions on Android and iOS.

```csharp
builder.Services.AddPermissions();
var permissions = services.Permissions;
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

## Service access

Import `DotNative.Permissions` to access the plugin through `IServiceProvider`:

```csharp
using DotNative.Permissions;

var plugin = services.Permissions;
```

The getter calls `GetRequiredService<IPermissions>()` on every access, preserving
DI lifetimes and the usual missing-registration error. Register the plugin with
`AddPermissions(...)` before building the provider.

A `net10.0` application uses the property syntax with C# 14 or later. A
`net9.0` application uses only the method equivalent:

```csharp
var plugin = services.Permissions();
```

The package contains separate `net9.0` and `net10.0` assemblies. NuGet selects
the assembly matching the application target framework. `NET10_0_OR_GREATER`
selects the property; the `#else` branch selects the method.

Build and pack both targets with .NET 10 SDK. A source build using .NET 9 SDK
builds only `net9.0`; it does not produce the .NET 10 assembly.
