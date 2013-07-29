module Spree
  Product.class_eval do
    scope :google_base_scope, includes(:taxons, {:master => :images})

    # <title>
    def google_base_title
      self.name
    end

    # <description>
    def google_base_description
      self.description
    end

    # <g:google_product_category> Apparel & Accessories > Clothing > Dresses
    def google_base_product_category
      self.property(:gm_product_category) || Spree::GoogleBase::Config[:product_category]
    end

    # <g:product_type> Home & Garden > Kitchen & Dining > Appliances > Refrigerators
    def google_base_product_type
      google_base_taxon_type
    end

    def google_base_taxon_type
      return unless taxons.any?
      taxonomy_name = 'Categories'    # need configurable parameter here
      parent_taxon = Spree::Taxon.find_by_name(taxonomy_name)
      taxons[parent_taxon.id].self_and_descendants.map(&:name).join(" > ")
    end

    # <g:condition> new | used | refurbished
    def google_base_condition
      'new'
    end

    # <g:availability> in stock | available for order | out of stock | preorder
    def google_base_availability
      self.total_on_hand > 0 ? 'in stock' : 'out of stock'
    end

    # <g:price> 15.00 USD
    def google_base_price
      format("%.2f %s", self.price, self.currency).to_s
    end

    # <g:sale_price> 15.00 USD
    def google_base_sale_price
      unless self.property(:gm_sale_price).nil?
        format("%.2f %s", self.property(:gm_sale_price), self.currency).to_s
      end
    end

    # <g:sale_price_effective_date> 2011-03-01T13:00-0800/2011-03-11T15:30-0800
    def google_base_sale_price_effective
      unless self.property(:gm_sale_price_effective).nil?
        return # TODO
      end
    end

    # <g:brand>
    def google_base_brand
      self.property(:brand)
    end

    # <g:gtin> 8-, 12-, or 13-digit number (UPC, EAN, JAN, or ISBN)
    def google_base_gtin
      self.master.gtin
    end

    # <g:mpn> Alphanumeric characters
    def google_base_mpn
      self.sku.gsub(/[^0-9a-z ]/i, '')
    end

    # <g:gender> Male, Female, Unisex
    def google_base_gender
      self.property(:gm_gender)
    end

    # <g:age_group> Adult, Kids
    def google_base_age_group
      self.property(:gm_age_group)
    end

    # <g:color>
    def google_base_color
      self.property(:gm_color)
    end

    # <g:size>
    def google_base_size
      self.property(:gm_size)
    end

    # <g:shipping_weight> # lb, oz, g, kg.
    def google_base_shipping_weight
      weight_units = 'oz'       # need a configuration parameter here
      format("%s %s", self.weight, weight_units)
    end

    # <g:adult> TRUE | FALSE
    def google_base_adult
      self.property(:gm_adult).upcase unless self.property(:gm_adult).nil?
    end

    # <g:adwords_grouping> single text value
    def google_base_adwords_group
      self.property(:gm_adwords_group)
    end
  end
end
