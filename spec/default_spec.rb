require "chefspec"

cookbook = "ssl_certificates"
recipe = "#{cookbook}::default"

describe recipe do

  let(:chef_run) { ChefSpec::ChefRunner.new.converge recipe }

  it "should create ssl certificates directory" do
    chef_run.should create_directory "/etc/ssl_certs"
  end

end


lwrp_recipe = "#{cookbook}::test"

describe lwrp_recipe do

  let(:chef_run) {
    ChefSpec::ChefRunner.new(:step_into => ["#{cookbook}_ssl_certificates"])
  }

  let(:data_bag_data) {
    {
      "id"        => "example_com",
      "name"      => "example.com",
      "crt"       => "crt_content",
      "ca_bundle" => "ca_bundle_content",
      "key"       => "key_content",
      "pem"       => "pem_content"
    }
  }

  let(:data_bag_only_parts) {
    {
      "id"   => "only-parts_example_com",
      "name" => "only-parts.example.com",
      "crt"  => "crt_contents",
      "key"  => "key_content"
    }
  }

  let(:data_bag_ca_bundle_combined) {
    {
      "id"        => "ca-bundle-combined_example_com",
      "name"      => "ca-bundle-combined.example.com",
      "crt"       => "crt_content",
      "ca_bundle" => "ca_bundle_content",
      "key"       => "key_content",
      "pem"       => "pem_content"
    }
  }

  let(:data_bag_wildcard) {
    {
        "id"   => "wildcard_example_com",
        "name" => "wildcard.example.com",
        "crt"  => "crt_contents",
        "key"  => "key_content"
    }
  }

  before(:all) do

    ::Chef::Recipe.any_instance.stub(:search).with(:certificates, "name:only-parts.example.com").and_return([ data_bag_only_parts ])
    ::Chef::Recipe.any_instance.stub(:search).with(:certificates, "name:example.com").and_return([ data_bag_data ])
    ::Chef::Recipe.any_instance.stub(:search).with(:certificates, "name:ca-bundle-combined.example.com").and_return([ data_bag_ca_bundle_combined ])
    ::Chef::Recipe.any_instance.stub(:search).with(:certificates, "name:example.com_wildcard").and_return([ data_bag_wildcard ])

    chef_run.converge lwrp_recipe
  end

  it "should only create requested certificate files" do

    files_should_exist = %w{
      crt
      key
    }

    files_should_not_exist = %w{
      pem
      ca-bundle
    }

    files_should_exist.each do |f|
      chef_run.should     create_file "/etc/ssl_certs/only-parts.example.com.#{f}"
    end

    files_should_not_exist.each do |f|
      chef_run.should_not create_file "/etc/ssl_certs/only-parts.example.com.#{f}"
    end

  end

  it "should create certificate files .crt, .ca-bundle, .pem and .key if requested" do

    files_should_exist = %w{
      crt
      key
      ca-bundle
      pem
    }

    files_should_exist.each do |f|
      chef_run.should     create_file "/etc/ssl_certs/example.com.#{f}"
    end

  end

  it "should create certificate files with the expected content" do

    %w{
      crt
      ca-bundle
      key
      pem
    }.each do |extension|
      chef_run.should create_file_with_content "/etc/ssl_certs/example.com.#{extension}", data_bag_data[extension.gsub(/-/, "_")]
    end
  end

  it "should create .crt file comined out of .crt and .ca-bundle if requested" do

    expected_content = data_bag_ca_bundle_combined["crt"] + "\n" + data_bag_ca_bundle_combined["ca_bundle"]

    chef_run.should create_file_with_content "/etc/ssl_certs/ca-bundle-combined.example.com.crt", expected_content

  end

  it "should create wildcard certificates" do

    chef_run.should create_file "/etc/ssl_certs/example.com_wildcard.crt"

  end
end