require "spec_helper"

describe Heroku::Command::Pipeline do

  subject { output }

  before do
    stub_request(:post, /api.heroku.com\/login.*/)
  end

  context "without downstreams configured" do
    describe "downstream-requiring operations" do
      before do
        stub_pipeline_request(:get, "dev", "downstreams").to_return(:body => Heroku::OkJson.encode([]))
        stub_pipeline_request(:get, "dev", "downstreams").with(:query => { "depth" => 1 }).to_return(:body => Heroku::OkJson.encode([]))
      end

      [
          lambda { heroku "pipeline -a dev" },
          lambda { heroku "pipeline:diff -a dev" },
          lambda { heroku "pipeline:promote -a dev" }
      ].each do |e|
        it { e.should raise_error Heroku::Command::CommandFailed, /Downstream app not specified/ }
      end
    end

    describe "#add" do
      before do
        stub_pipeline_request(:post, "staging", "downstreams", "prod")
        heroku "pipeline:add prod -a staging"
      end

      it { should include "Added downstream app: prod" }
    end

    describe "#remove" do
      before do
        stub_pipeline_request(:delete, "staging", "downstreams", "prod")
        heroku "pipeline:remove prod -a staging"
      end

      it { should include "Removed downstream app: prod" }
    end
  end

  context "with downstreams configured" do
    before do
      stub_pipeline_request(:get, "dev",     "downstreams").to_return(:body => Heroku::OkJson.encode(["staging", "prod"]))
      stub_pipeline_request(:get, "dev",     "downstreams").with(:query => { "depth" => 1 }).to_return(:body => Heroku::OkJson.encode(["staging"]))
      stub_pipeline_request(:get, "staging", "downstreams").to_return(:body => Heroku::OkJson.encode(["prod"]))
      stub_pipeline_request(:get, "staging", "downstreams").with(:query => { "depth" => 1 }).to_return(:body => Heroku::OkJson.encode(["prod"]))
    end

    describe "#index" do
      before do
        heroku "pipeline -a dev"
      end

      it { should include "dev ---> staging ---> prod" }
    end

    describe "#index with depth" do
      before do
        heroku "pipeline -a dev -d 1"
      end

      it { should include "dev ---> staging" }
    end

    describe "#diff" do
      before do
        stub_pipeline_request(:get, "staging", "diff").to_return(:body => Heroku::OkJson.encode(["COMMIT_A", "COMMIT_B"]))
        heroku "pipeline:diff -a staging"
      end

      it { should include "Comparing staging to prod...done, staging ahead by 2 commits" }
      it { should include "COMMIT_A" }
      it { should include "COMMIT_B" }
    end

    describe "#promote" do
      before do
        stub_pipeline_request(:post, "staging", "promote").to_return(:status => 202, :headers => { "Location" => "/v1/mocking" })
        stub_request(:get,  v1 + "/mocking").to_return(:body => Heroku::OkJson.encode("release" => "v0"))
        heroku "pipeline:promote prod -a staging"
      end

      it { should include "Promoting staging to prod....done, v0" }
    end
  end

  def stub_pipeline_request(method, app, *extras)
    stub_request(method, v1 + extras.unshift("/apps/#{app}/pipeline").join("/"))
  end

  def v1
     "https://#{Cisaurus::DEFAULT_HOST}/v1"
  end
end
