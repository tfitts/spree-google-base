require 'net/ftp'

module SpreeGoogleBase
  class FeedBuilder
    include Spree::Core::Engine.routes.url_helpers

    attr_reader :store, :domain, :title

    def self.generate_and_transfer
      self.builders.each do |builder|
        builder.generate_and_transfer_store
      end
    end

    def self.generate
      self.builders.each do |builder|
        builder.generate_store
      end
    end

    def self.transfer
      self.builders.each do |builder|
        builder.transfer_xml
      end
    end

    def self.builders
      if defined?(Spree::Store)
        Spree::Store.all.map{ |store| self.new(:store => store) }
      else
        [self.new]
      end
    end

    def initialize(opts = {})
      raise "Please pass a public address as the second argument, or configure :public_path in Spree::GoogleBase::Config" unless
        opts[:store].present? or (opts[:path].present? or Spree::GoogleBase::Config[:public_domain])

      @store = opts[:store] if opts[:store].present?
      @title = @store ? @store.name : Spree::GoogleBase::Config[:store_name]

      @domain = @store ? @store.domains.match(/[\w\.]+/).to_s : opts[:path]
      @domain ||= Spree::GoogleBase::Config[:public_domain]
    end

    def ar_scope
      if @store
        Spree::Product.by_store(@store).google_base_scope.scoped
      else
        Spree::Product.google_base_scope.scoped
      end
    end

    def generate_store
      delete_xml_if_exists

      File.open(path, 'w') do |file|
        generate_xml file
      end
    end

    def generate_and_transfer_store
      delete_xml_if_exists

      File.open(path, 'w') do |file|
        generate_xml file
      end

      transfer_xml
      cleanup_xml
    end

    def path
      "#{::Rails.root}/tmp/#{filename}"
    end

    def filename
      "google_merchant.xml"
    end

    def delete_xml_if_exists
      File.delete(path) if File.exists?(path)
    end

    def validate_record(product)
      return false if product.images.length == 0
      return false if product.google_base_title.nil?
      return false if product.google_base_product_category.nil?
      return false if product.google_base_availability.nil?
      return false if product.google_base_price.nil?
      return false if product.google_base_description.nil?
      return false if product.google_base_brand.nil?
      return false if product.google_base_gtin.nil?
      return false if product.google_base_mpn.nil?
      return false if product.google_base_shipping_weight.nil?

      unless product.google_base_sale_price.nil?
        return false if product.google_base_sale_price_effective.nil?
      end

      true
    end

    def generate_xml output
      xml = Builder::XmlMarkup.new(:target => output)
      xml.instruct!

      xml.rss(:version => '2.0', :"xmlns:g" => "http://base.google.com/ns/1.0") do
        xml.channel do
          build_meta(xml)

          ar_scope.find_each(:batch_size => 300) do |product|
            next unless validate_record(product)
            build_product(xml, product)
          end
        end
      end
    end

    def transfer_xml
      raise "Please configure your Google Base :ftp_username and :ftp_password by configuring Spree::GoogleBase::Config" unless
        Spree::GoogleBase::Config[:ftp_username] and Spree::GoogleBase::Config[:ftp_password]

      ftp = Net::FTP.new('uploads.google.com')
      ftp.passive = true
      ftp.login(Spree::GoogleBase::Config[:ftp_username], Spree::GoogleBase::Config[:ftp_password])
      ftp.put(path, filename)
      ftp.quit
    end

    def cleanup_xml
      File.delete(path)
    end

    def build_product(xml, product)
      xml.item do
        xml.tag!('link', product_url(product.permalink, :host => domain))
        build_images(xml, product)

        GOOGLE_BASE_ATTR_MAP.each do |k, v|
          value = product.send(v)
          xml.tag!(k, value.to_s) if value.present?
        end

        build_adwords_labels(xml, product)
      end
    end

    def build_images(xml, product)
      return if product.images.nil?

      main_image, *more_images = product.images

      return unless main_image
      xml.tag!('g:image_link', image_url(main_image).sub(/\?.*$/, '').sub(/^\/\//, 'http://'))

      more_images.each do |image|
        xml.tag!('g:additional_image_link', image_url(image).sub(/\?.*$/, '').sub(/^\/\//, 'http://'))
      end
    end

    def image_url image
      base_url = image.attachment.url
      base_url = "#{domain}/#{base_url}" unless Spree::Config[:use_s3]

      base_url
    end

    def build_adwords_labels(xml, product)     # <g:adwords_labels>
      return if product.property(:gm_adwords_label).nil?

      labels = self.property(:gm_adwords_label).to_a
      labels.each do |l|
        xml.tag!('g:adwords_labels', l)
      end
    end

    def build_meta(xml)
      xml.title @title
      xml.link @domain
    end

  end
end
