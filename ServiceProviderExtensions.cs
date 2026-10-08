using System;
using Microsoft.Extensions.DependencyInjection;

namespace DotNative.Permissions;

public static class PermissionsServiceProviderExtensions
{
#if NET10_0_OR_GREATER
    extension(IServiceProvider services)
    {
        /// <summary>Resolves the registered plugin using the provider's DI lifetime.</summary>
        public IPermissions Permissions => services.GetRequiredService<IPermissions>();
    }
#else
    /// <summary>Resolves the registered plugin using the provider's DI lifetime.</summary>
    public static IPermissions Permissions(this IServiceProvider services) =>
        services.GetRequiredService<IPermissions>();
#endif
}
