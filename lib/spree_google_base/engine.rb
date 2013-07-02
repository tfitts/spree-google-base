module SpreeGoogleBase
  class Engine < Rails::Engine
    engine_name 'spree_google_base'

    config.autoload_paths += %W( #{config.root}/lib )

    initializer "spree.google_base.environment", :before => :load_config_initializers do |app|
      Spree::GoogleBase::Config = Spree::GoogleBaseConfiguration.new

      # See http://support.google.com/merchants/bin/answer.py?hl=en&answer=188494#US for all other fields
      SpreeGoogleBase::FeedBuilder::GOOGLE_BASE_ATTR_MAP = [
        ['g:id', 'id'],
        ['title', 'google_base_title'],
        ['description', 'google_base_description'],
        ['g:google_product_category','google_base_product_category'],
        ['g:product_type', 'google_base_product_type'],
        ['g:condition', 'google_base_condition'],
        ['g:availability', 'google_base_availability'],
        ['g:price', 'google_base_price'],
        ['g:sale_price', 'google_base_sale_price'],
        ['g:sale_price_effective_date', 'google_base_sale_price_effective'],
        ['g:brand', 'google_base_brand'],
        ['g:gtin','google_base_gtin'],
        ['g:mpn', 'google_base_mpn'],
        ['g:shipping_weight', 'google_base_shipping_weight'],
        ['g:adult', 'google_base_adult']
      ]
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

  end
end
