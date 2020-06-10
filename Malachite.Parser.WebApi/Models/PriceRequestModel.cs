using System;
using System.ComponentModel.DataAnnotations;
using Nager.PublicSuffix;

public class PriceRequestModel
{
    private static WebTldRuleProvider _provider = new WebTldRuleProvider();

    [Url]
    [Required]
    public String Url 
    { 
        get; 
        set; 
    }
    
    public String Store => DomainName.Domain;

    private Uri Uri => new Uri(Url);

    private DomainName DomainName
    {
        get 
        {
            var domainParser = new DomainParser(_provider);
            return domainParser.Get(Uri);
        }
    }
}