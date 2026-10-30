using DotNative.Plugins;

namespace DotNative.Permissions;

public static class Permissions
{
    public static IPermissions Create() => PluginImplementations.Resolve<IPermissions>(() =>
    {
        var runtime = PluginRuntime.Current;
        if (runtime.Target.Platform is not (NativePlatform.Android or NativePlatform.IOS))
            throw new PlatformNotSupportedException("Built-in permissions support Android/iOS. Register an IPermissions implementation for this platform with PluginImplementations.Register.");
        return new ChannelPermissions(runtime.Channels);
    });
    public static Task<PermissionStatus> CheckAsync(PermissionKind permission, CancellationToken cancellationToken = default) =>
        Create().CheckAsync(permission, cancellationToken);
    public static Task<PermissionStatus> RequestAsync(PermissionKind permission, CancellationToken cancellationToken = default) =>
        Create().RequestAsync(permission, cancellationToken);
}
