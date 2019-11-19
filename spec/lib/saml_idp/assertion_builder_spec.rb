require 'spec_helper'
module SamlIdp
  describe AssertionBuilder do
    let(:reference_id) { "abc" }
    let(:issuer_uri) { "http://sportngin.com" }
    let(:name_id) { "jon.phenow@sportngin.com" }
    let(:audience_uri) { "http://example.com" }
    let(:saml_request_id) { "123" }
    let(:saml_acs_url) { "http://saml.acs.url" }
    let(:algorithm) { :sha256 }
    let(:authn_context_classref) {
      Saml::XML::Namespaces::AuthnContext::ClassRef::PASSWORD
    }
    let(:expiry) { 3*60*60 }
    let (:encryption_opts) do
      {
        cert: Default::X509_CERTIFICATE,
        block_encryption: 'aes256-cbc',
        key_transport: 'rsa-oaep-mgf1p',
      }
    end
    let(:new_cert) { false }
    subject { described_class.new(
      reference_id,
      issuer_uri,
      name_id,
      audience_uri,
      saml_request_id,
      saml_acs_url,
      algorithm,
      authn_context_classref,
      expiry,
      new_cert
    ) }

    context "No Request ID" do
      let(:saml_request_id) { nil }

      it "builds a legit raw XML file" do
        Timecop.travel(Time.zone.local(2010, 6, 1, 13, 0, 0)) do
          expect(subject.raw).to eq("<Assertion xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"_abc\" IssueInstant=\"2010-06-01T13:00:00Z\" Version=\"2.0\"><Issuer>http://sportngin.com</Issuer><Subject><NameID Format=\"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress\">foo@example.com</NameID><SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\"><SubjectConfirmationData NotOnOrAfter=\"2010-06-01T13:03:00Z\" Recipient=\"http://saml.acs.url\"></SubjectConfirmationData></SubjectConfirmation></Subject><Conditions NotBefore=\"2010-06-01T12:59:55Z\" NotOnOrAfter=\"2010-06-01T16:00:00Z\"><AudienceRestriction><Audience>http://example.com</Audience></AudienceRestriction></Conditions><AuthnStatement AuthnInstant=\"2010-06-01T13:00:00Z\" SessionIndex=\"_abc\"><AuthnContext><AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</AuthnContextClassRef></AuthnContext></AuthnStatement><AttributeStatement><Attribute Name=\"email-address\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\" FriendlyName=\"emailAddress\"><AttributeValue>foo@example.com</AttributeValue></Attribute></AttributeStatement></Assertion>")
        end
      end
    end

    it "builds a legit raw XML file" do
      Timecop.travel(Time.zone.local(2010, 6, 1, 13, 0, 0)) do
        expect(subject.raw).to eq("<Assertion xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"_abc\" IssueInstant=\"2010-06-01T13:00:00Z\" Version=\"2.0\"><Issuer>http://sportngin.com</Issuer><Subject><NameID Format=\"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress\">foo@example.com</NameID><SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\"><SubjectConfirmationData InResponseTo=\"123\" NotOnOrAfter=\"2010-06-01T13:03:00Z\" Recipient=\"http://saml.acs.url\"></SubjectConfirmationData></SubjectConfirmation></Subject><Conditions NotBefore=\"2010-06-01T12:59:55Z\" NotOnOrAfter=\"2010-06-01T16:00:00Z\"><AudienceRestriction><Audience>http://example.com</Audience></AudienceRestriction></Conditions><AuthnStatement AuthnInstant=\"2010-06-01T13:00:00Z\" SessionIndex=\"_abc\"><AuthnContext><AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</AuthnContextClassRef></AuthnContext></AuthnStatement><AttributeStatement><Attribute Name=\"email-address\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\" FriendlyName=\"emailAddress\"><AttributeValue>foo@example.com</AttributeValue></Attribute></AttributeStatement></Assertion>")
      end
    end

    describe "without attributes" do
      let(:config) { SamlIdp::Configurator.new }
      before do
        config.name_id.formats = {
          "1.1" => {
            email_address: ->(p) { "foo@example.com" }
          }
        }
        allow(SamlIdp).to receive(:config).and_return(config)
      end

      it "doesn't include attribute statement" do
        Timecop.travel(Time.zone.local(2010, 6, 1, 13, 0, 0)) do
          expect(subject.raw).to eq("<Assertion xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"_abc\" IssueInstant=\"2010-06-01T13:00:00Z\" Version=\"2.0\"><Issuer>http://sportngin.com</Issuer><Subject><NameID Format=\"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress\">foo@example.com</NameID><SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\"><SubjectConfirmationData InResponseTo=\"123\" NotOnOrAfter=\"2010-06-01T13:03:00Z\" Recipient=\"http://saml.acs.url\"></SubjectConfirmationData></SubjectConfirmation></Subject><Conditions NotBefore=\"2010-06-01T12:59:55Z\" NotOnOrAfter=\"2010-06-01T16:00:00Z\"><AudienceRestriction><Audience>http://example.com</Audience></AudienceRestriction></Conditions><AuthnStatement AuthnInstant=\"2010-06-01T13:00:00Z\" SessionIndex=\"_abc\"><AuthnContext><AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</AuthnContextClassRef></AuthnContext></AuthnStatement></Assertion>")
        end
      end
    end

    describe "with principal.asserted_attributes" do
      it "delegates attributes to principal" do
        Principal = Struct.new(:email, :asserted_attributes)
        principal = Principal.new('foo@example.com', { emailAddress: { getter: :email } })
        builder = described_class.new(
          reference_id,
          issuer_uri,
          principal,
          audience_uri,
          saml_request_id,
          saml_acs_url,
          algorithm,
          authn_context_classref,
          expiry,
          nil,
          nil,
          new_cert
        )
        Timecop.travel(Time.zone.local(2010, 6, 1, 13, 0, 0)) do
          expect(builder.raw).to eq("<Assertion xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"_abc\" IssueInstant=\"2010-06-01T13:00:00Z\" Version=\"2.0\"><Issuer>http://sportngin.com</Issuer><Subject><NameID Format=\"urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress\">foo@example.com</NameID><SubjectConfirmation Method=\"urn:oasis:names:tc:SAML:2.0:cm:bearer\"><SubjectConfirmationData InResponseTo=\"123\" NotOnOrAfter=\"2010-06-01T13:03:00Z\" Recipient=\"http://saml.acs.url\"></SubjectConfirmationData></SubjectConfirmation></Subject><Conditions NotBefore=\"2010-06-01T12:59:55Z\" NotOnOrAfter=\"2010-06-01T16:00:00Z\"><AudienceRestriction><Audience>http://example.com</Audience></AudienceRestriction></Conditions><AuthnStatement AuthnInstant=\"2010-06-01T13:00:00Z\" SessionIndex=\"_abc\"><AuthnContext><AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</AuthnContextClassRef></AuthnContext></AuthnStatement><AttributeStatement><Attribute Name=\"emailAddress\" NameFormat=\"urn:oasis:names:tc:SAML:2.0:attrname-format:uri\" FriendlyName=\"emailAddress\"><AttributeValue>foo@example.com</AttributeValue></Attribute></AttributeStatement></Assertion>")
        end
      end
    end

    it "builds encrypted XML" do
      builder = described_class.new(
        reference_id,
        issuer_uri,
        name_id,
        audience_uri,
        saml_request_id,
        saml_acs_url,
        algorithm,
        authn_context_classref,
        expiry,
        encryption_opts,
        nil,
        false
      )
      encrypted_xml = builder.encrypt
      expect(encrypted_xml).to_not match(audience_uri)
    end

    describe "with custom session_expiry configuration" do
      let(:config) { SamlIdp::Configurator.new }
      before do
        config.session_expiry = 8
        allow(SamlIdp).to receive(:config).and_return(config)
      end

      it "sets default session_expiry from config" do
        builder = described_class.new(
          reference_id,
          issuer_uri,
          name_id,
          audience_uri,
          saml_request_id,
          saml_acs_url,
          algorithm,
          authn_context_classref,
          expiry,
          encryption_opts,
          nil,
          new_cert
        )
        expect(builder.session_expiry).to eq(8)
      end
    end
  end
end
