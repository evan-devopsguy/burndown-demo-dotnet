using System;
using System.Net.Http;
using System.Text.Encodings.Web;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace Contoso.Platform
{
    /// <summary>
    /// Outbound HTTP conventions for Contoso services: correlation headers,
    /// service identity, and the platform-standard service descriptor payload.
    /// </summary>
    public class PlatformClient : IDisposable
    {
        private static readonly Regex ServiceNamePattern =
            new Regex("^[a-z][a-z0-9-]{2,40}$", RegexOptions.Compiled);

        private readonly HttpClient _http;

        public string ServiceName { get; }

        public PlatformClient(string serviceName)
        {
            if (!ServiceNamePattern.IsMatch(serviceName ?? string.Empty))
                throw new ArgumentException("Service name must be kebab-case.", nameof(serviceName));

            ServiceName = serviceName;
            _http = new HttpClient();
            _http.DefaultRequestHeaders.Add("X-Contoso-Service", serviceName);
        }

        public string DescribeService()
        {
            return "{\"service\":\"" + HtmlEncoder.Default.Encode(ServiceName) + "\",\"sdk\":\"1.4.2\"}";
        }

        public Task<string> GetAsync(string url) => _http.GetStringAsync(url);

        public void Dispose() => _http.Dispose();
    }
}
