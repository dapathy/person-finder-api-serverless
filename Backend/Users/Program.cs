using Microsoft.Extensions.Hosting;
using System.Threading.Tasks;

namespace Users
{
	public class Program
	{
		public static async Task Main()
		{
			var host = new HostBuilder()
				.ConfigureFunctionsWorkerDefaults()
				.Build();

			await host.RunAsync();
		}
	}
}