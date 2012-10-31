require "spec_helper"

describe Heroku::Command::Pipeline do

  subject { output }

  before(:all) do
    @us = ENV['HEROKU_TEST_UPSTREAM_APP']
    @ds = ENV['HEROKU_TEST_DOWNSTREAM_APP']
  end

  describe "#index" do
    context "basic" do
      before(:each) do
        heroku "pipeline -a #{@us}"
      end

      it { should include "#{@us} ---> #{@ds}" }
    end
  end

  describe "#promote" do
    context "basic" do
      before do
        heroku "pipeline:promote -a #{@us}"
      end

      it {
        should include "Promoting #{@us} to #{@ds}..."
        should include "done, v"
      }
    end
  end

end
