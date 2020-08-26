require 'spec_helper'
module SamlIdp
  describe NameIdFormatter do
    subject { described_class.new list, name_id_attr }

    describe "with one item" do
      let(:list) { { email_address: ->() { "foo@example.com" } } }
      let(:name_id_attr) { nil }

      it "has a valid all" do
        expect(subject.all).to eq ["urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress"]
      end

    end

    describe "with hash describing versions" do
      let(:list) {
        {
          "1.1" => { email_address: -> {} },
          "2.0" => { undefined: -> {} },
        }
      }
      let(:name_id_attr) { nil }

      it "has a valid all" do
        expect(subject.all).to eq [
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
          "urn:oasis:names:tc:SAML:2.0:nameid-format:undefined",
        ]
      end
    end

    describe "with actual list" do
      let(:list) { [:email_address, :undefined] }
      let(:name_id_attr) { nil }

      it "has a valid all" do
        expect(subject.all).to eq [
          "urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress",
          "urn:oasis:names:tc:SAML:2.0:nameid-format:undefined",
        ]
      end
    end

    describe "with name_id_attr" do
      let(:list) { [:email_address, :undefined] }
      let(:name_id_attr) { { unspecified: ->() { "foo" } } }

      it "has a valid name id attr format" do
        expect(subject.chosen[:name]).to eq "urn:oasis:names:tc:SAML:2.0:nameid-format:unspecified"
      end
    end
  end
end
