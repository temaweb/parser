using System;
using System.ComponentModel.DataAnnotations;

public class PriceRequestModel
{
    [Url]
    [Required]
    public String Url 
    { 
        get; 
        set; 
    }
    
    public String Store
    {
        get 
        {
            return Uri.Host;
        }
    }

    private Uri Uri 
    {
        get
        {
            return new Uri(Url);
        }
    }
}