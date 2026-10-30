# DotNative.Permissions

## Standalone SDK API (preview.18 candidate)

Reference this package and the MAUI, Avalonia or Uno adapter, or use the DotNative
host. Register once on the UI thread after the owning window/root is ready:

```csharp
using DotNative.Plugins;
using DotNative.Permissions;

PluginHost.Register();
var status = await Permissions.RequestAsync(PermissionKind.Camera, cancellationToken);
```

Static calls do not require DI. Applications may supply their own implementation
with `PluginImplementations.Register<IPermissions>(() => new AppPermissions())`; keep the
returned registration alive while it is needed. An application implementation can
be a partial class split across platform files.

This migration requires the matching SDK preview.18 candidate. Packages are not
published to nuget.org. See the [SDK migration and runtime evidence](https://github.com/kantagara/DotNative.Plugins/pull/1)
for exact tested hosts and platform limitations. Existing DI APIs remain available.

Built-in native implementations support Android/iOS. Desktop applications must
provide their own implementation through the registration above.

## Existing API and platform details

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
