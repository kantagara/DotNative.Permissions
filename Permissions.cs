using DotNative.Plugins;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace DotNative.Permissions;

public enum PermissionKind
{
    Camera,
    Microphone,
    Location,
    Notifications,
}

public enum PermissionStatus
{
    Granted,
    Denied,
    Restricted,
    PermanentlyDenied,
    NotDetermined,
}

public interface IPermissions
{
    Task<PermissionStatus> CheckAsync(
        PermissionKind permission,
        CancellationToken cancellationToken = default
    );
    Task<PermissionStatus> RequestAsync(
        PermissionKind permission,
        CancellationToken cancellationToken = default
    );
}

public static class PermissionsServices
{
    public static IServiceCollection AddPermissions(this IServiceCollection services)
    {
        services.TryAddSingleton<IPermissions, ChannelPermissions>();
        return services;
    }
}

internal sealed class ChannelPermissions(IPlatformChannels channels) : IPermissions
{
    private MethodChannel Channel => channels.Get("dotnative.permissions");

    public Task<PermissionStatus> CheckAsync(
        PermissionKind permission,
        CancellationToken cancellationToken = default
    ) => Read("check", permission, cancellationToken);

    public Task<PermissionStatus> RequestAsync(
        PermissionKind permission,
        CancellationToken cancellationToken = default
    ) => Read("request", permission, cancellationToken);

    private async Task<PermissionStatus> Read(
        string method,
        PermissionKind permission,
        CancellationToken token
    )
    {
        var result = await Channel
            .InvokeAsync(
                method,
                new Dictionary<string, object?>
                {
                    ["permission"] = permission.ToString().ToLowerInvariant(),
                },
                token
            )
            .ConfigureAwait(false);
        if (
            result is not string text
            || !Enum.TryParse<PermissionStatus>(text, true, out var status)
        )
            throw new InvalidDataException("Invalid permission response.");
        return status;
    }
}
