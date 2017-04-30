require "spec_helper"

describe Rabbitmq::Actors do
  it "has a version number" do
    expect(Rabbitmq::Actors::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
