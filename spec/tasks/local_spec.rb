require File.expand_path(File.join(File.dirname(__FILE__),'../spec_helper'))

describe Rake::Task['former03:local:check'] do
  it "Should test if there's a git repo" do
    subject.invoke
  end
end

describe Rake::Task['former03:local:mkdir_stage'] do
end
describe Rake::Task['former03:local:stage'] do
end
