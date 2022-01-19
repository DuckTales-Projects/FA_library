# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Author, type: :model do
  it 'author needs a name' do
    author = described_class.new(name: 'John')
    expect(author.name).to eq('John')
  end
end
