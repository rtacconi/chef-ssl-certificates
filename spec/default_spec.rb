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

  let(:runner) {
    runner = ChefSpec::ChefRunner.new(:step_into => ["#{cookbook}_ssl_certificates"])
  }

  it "should deploy certificate with crt and key data" do
    Chef::Recipe.any_instance.stub(:search).with(:certificates, "name:example.com").and_return([{"id" => "example_com", "name" => "example.com", "crt" => "crt_contents", "key" => "pem_content"}])

    runner.converge lwrp_recipe
    runner.should     create_file "/etc/ssl_certs/example.com.crt"
    runner.should     create_file "/etc/ssl_certs/example.com.key"
    runner.should_not create_file "/etc/ssl_certs/example.com.pem"
    runner.should_not create_file "/etc/ssl_certs/example.com.ca-bundle"
  end

  it "should deploy certificate with crt + ca_bundle and key data" do
    Chef::Recipe.any_instance.stub(:search).with(:certificates, "name:example.com").and_return([{"id" => "ca-bundle_example_com", "name" => "ca-bundle.example.com", "crt" => "crt_contents", "key" => "pem_content", "ca_bundle" => "ca_bundle_content"}])

    runner.converge lwrp_recipe
    runner.should     create_file "/etc/ssl_certs/example.com.crt"
    runner.should     create_file "/etc/ssl_certs/example.com.key"
    runner.should_not create_file "/etc/ssl_certs/example.com.pem"
    runner.should     create_file "/etc/ssl_certs/example.com.ca-bundle"
  end

end