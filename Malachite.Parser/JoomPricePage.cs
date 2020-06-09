using System;
using HtmlAgilityPack;
using Fizzler.Systems.HtmlAgilityPack;

public partial class JoomStore
{
    private class JoomPricePage
    {
        private readonly HtmlNode _root;
        
        private String _amount;               

        private String _currency;

        public String Amount
        {
            get
            {
               return _amount ?? (_amount = ReadMeta("amount")); 
            }
        }

        public String Currency
        {
            get
            {
               return _currency ?? (_currency = ReadMeta("currency")); 
            }
        }

        public String Price
        {
            get 
            {
                return $"{Amount} {Currency}";
            }
        }

        public JoomPricePage(HtmlNode root)
        {
            _root = root ?? throw new ArgumentNullException(nameof(root));
        }

        private String ReadMeta(string property)
        {
            var node = _root.QuerySelector($"meta[property='product:price:{property}']");
            if (node == null)
                throw new NotSupportedException("Страница не поддерживается");

            return node.GetAttributeValue("content", String.Empty);
        }
    }
}