module Spree
  Product.class_eval do
    scope :google_base_scope, includes(:taxons, {:master => :images})
    
    def google_base_description
      description
    end
    
    def google_base_condition
      'new'
    end
    
    def google_base_availability
      on_hand > 0 ? 'in stock' : 'out of stock'
    end

    def on_hand
      variants_with_only_master.stock_items.first.count_on_hand
    end

    def google_base_image_link
      image = images.first and
          image_path = image.attachment.url(:product) and
          [Spree::GoogleBase::Config[:public_domain], image_path].join
    end

    def google_base_brand
      property(:brand)
    end

    def google_product_category

      Spree::GoogleBase::Config[:product_category]

    end

    def google_base_product_type
      google_base_taxon_type
    end

    def google_base_taxon_type
      return unless taxons.any?

      taxons[0].self_and_ancestors.map(&:name).join(" > ")
    end
  end
end
