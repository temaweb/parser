using System;
using System.Net.Http;
using System.Threading.Tasks;
using HtmlAgilityPack;

public partial class JoomStore : IStore
{
    private readonly HttpClient _client = new HttpClient();

    public async Task<String> GetProductPrice(string link)
    {
        var node = await LoadPricePageAsync(link);
        return node.Price;
    }

    private async Task<JoomPricePage> LoadPricePageAsync(String link)
    {       
        var content = await ReadWebPageAsync(link);
        var root = CreateHtmlDocumentNode(content);

        return new JoomPricePage(root);
    }

    private async Task<String> ReadWebPageAsync(String link)
    {
        var response = await _client.GetAsync(link);
        if (response.IsSuccessStatusCode)
            return await response.Content.ReadAsStringAsync();

        throw new HttpRequestException($"Request {link} returns {response.StatusCode}");
    }

    private HtmlNode CreateHtmlDocumentNode(String content)
    {
        var htmlDocument = new HtmlDocument();
        htmlDocument.LoadHtml(content);
        return htmlDocument.DocumentNode;
    }
}