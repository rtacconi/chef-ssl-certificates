ssl_certificate "only-parts.example.com"

ssl_certificate "example.com"

ssl_certificate "ca-bundle-combined.example.com" do
  ca_bundle_combined true
end

ssl_certificate "*.example.com"