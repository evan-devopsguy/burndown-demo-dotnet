using Newtonsoft.Json;

namespace Contoso.Common;

public static class Envelope
{
    public static string Wrap(string service, object payload) =>
        JsonConvert.SerializeObject(new { service, payload });
}
