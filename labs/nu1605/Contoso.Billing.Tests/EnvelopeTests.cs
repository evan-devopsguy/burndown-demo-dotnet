using Contoso.Common;

namespace Contoso.Billing.Tests;

// Test framework trimmed for the demo; the project exists for its package pin.
public static class EnvelopeTests
{
    public static bool WrapsServiceName() => Envelope.Wrap("billing-api", new { }).Contains("billing-api");
}
