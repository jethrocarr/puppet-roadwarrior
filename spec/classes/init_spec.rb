require 'spec_helper'
describe 'roadwarrior' do

  context 'with defaults for all parameters' do
    it { should contain_class('roadwarrior') }
  end
end
