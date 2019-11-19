require 'builder'

module SamlIdp
  class SignatureBuilder
    attr_accessor :signed_info_builder, :new_cert

    def initialize(signed_info_builder, new_cert)
      self.signed_info_builder = signed_info_builder
      self.new_cert = new_cert
    end

    def raw
      builder = Builder::XmlMarkup.new
      builder.tag! "ds:Signature", "xmlns:ds" => "http://www.w3.org/2000/09/xmldsig#" do |signature|
        signature << signed_info
        signature.tag! "ds:SignatureValue", signature_value
        signature.KeyInfo xmlns: "http://www.w3.org/2000/09/xmldsig#" do |key_info|
          key_info.tag! "ds:X509Data" do |x509|
            x509.tag! "ds:X509Certificate", x509_certificate
          end
        end
      end
    end

    def x509_certificate
      extract_x509_certificate(certificate_by_options)
    end
    private :x509_certificate

    def certificate_by_options
      if new_cert
        SamlIdp.config.new_x509_certificate
      else
        SamlIdp.config.x509_certificate
      end
    end

    private def extract_x509_certificate(cert)
      return if cert.blank?

      cert
      .to_s
      .gsub(/-----BEGIN CERTIFICATE-----/,"")
      .gsub(/-----END CERTIFICATE-----/,"")
      .gsub(/\n/, "")
    end

    def signed_info
      signed_info_builder.raw
    end
    private :signed_info

    def signature_value
      signed_info_builder.signed
    end
    private :signature_value

  end
end
