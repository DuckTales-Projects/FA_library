# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Books', type: :request do
  describe 'GET /books' do
    subject(:get_index) { get books_path, params: page }

    let(:page) { { page: 1 } }

    context 'when books exits' do
      let(:list) { create_list(:book, 9) }
      let(:my_book) { create(:book, title: 'crash') }

      before do
        list
        my_book
        get_index
      end

      it 'returns all the books' do
        expect(response).to have_http_status :ok
        expect(JSON(response.body).size).to eq 3
        expect(JSON(response.body)['total_books']).to eq 10
        expect(JSON(response.body)['list'].size).to eq 10
        expect(JSON(response.body)['pagination']).to eq '1 of 1'
        expect(JSON(response.body)['list'].last['title']).to eq 'crash'
      end
    end

    context 'when using pagination' do
      let(:list) { create_list(:book, 55) }

      let(:set_page2) do
        page[:page] = 2
        get_index
      end

      let(:set_page3) do
        page[:page] = 3
        get_index
      end

      before { list }

      it 'with page 2' do
        set_page2

        expect(response).to have_http_status :ok
        expect(JSON(response.body)['total_books']).to eq 55
        expect(JSON(response.body)['list'].size).to eq 25
        expect(JSON(response.body)['pagination']).to eq '2 of 3'
      end

      it 'with page 3' do
        set_page3

        expect(response).to have_http_status :ok
        expect(JSON(response.body)['total_books']).to eq 55
        expect(JSON(response.body)['list'].size).to eq 5
        expect(JSON(response.body)['pagination']).to eq '3 of 3'
      end
    end

    context 'when books not exits' do
      before { get_index }

      it 'must return an empty JSON' do
        expect(response).to have_http_status :ok
        expect(JSON(response.body)['list'].empty?).to eq true
      end
    end
  end

  describe 'GET /books/:id' do
    subject(:get_book) { get book_path(id) }

    context 'when books exits' do
      let(:my_book) { create(:book, title: 'Sem lama não há lótus') }
      let(:id) { my_book.id }

      before { get_book }

      it 'return my book' do
        expect(response).to have_http_status :ok
        expect(JSON(response.body)['id']).to eq id
        expect(JSON(response.body)['title']).to eq 'Sem lama não há lótus'
        expect(JSON(response.body)['genre']).to eq my_book.genre
        expect(JSON(response.body)['language']).to eq my_book.language
        expect(JSON(response.body)['edition']).to eq my_book.edition
        expect(JSON(response.body)['place']).to eq my_book.place
        expect(JSON(response.body)['year']).to eq my_book.year
      end
    end

    context 'when books not exits' do
      let(:id) { Faker::Number.within(range: 900..1000) }
      let(:message) { "Couldn't find Book with 'id'=#{id}" }

      before { get_book }

      it 'is not found' do
        expect(response).to have_http_status :not_found
        expect(JSON(response.body)['message']).to eq message
      end
    end
  end

  describe 'POST /books' do
    subject(:create_book) { post books_path, params: params }

    context 'when creating' do
      let(:author) { create(:author) }
      let(:publisher) { create(:publisher) }
      let(:params) { { book: attributes_for(:book, author_id: author.id, publisher_id: publisher.id) } }

      before { create_book }

      it 'must return my book' do
        expect(response).to have_http_status :created
        expect(JSON(response.body)['title']).to eq params.values[0].values[0]
        expect(JSON(response.body)['genre']).to eq params.values[0].values[1]
      end
    end

    context 'when creating with invalid attributes' do
      let(:params) { { book: attributes_for(:book) } }
      let(:message) { 'Validation failed: Author must exist, Publisher must exist' }

      before { create_book }

      it 'is a unprocessable entity' do
        expect(response).to have_http_status :unprocessable_entity
        expect(JSON(response.body)['message']).to eq message
      end
    end

    context 'when creating with invalid params' do
      let(:params) { {} }
      let(:message) { 'param is missing or the value is empty: book' }

      before { create_book }

      it 'is a bad request' do
        expect(response).to have_http_status :bad_request
        expect(JSON(response.body)['message']).to eq message
      end
    end
  end

  describe 'PUT /books/:id' do
    subject(:update_book) { put book_path(id), params: params }

    let(:params) { { book: attributes_for(:book, title: '1984') } }
    let(:my_book) { create(:book) }
    let(:id) { my_book.id }

    context 'when book exists' do
      before { update_book }

      it 'updates the book' do
        my_book.reload

        expect(response).to have_http_status :no_content
        expect(my_book.title).to eq '1984'
      end
    end

    context 'when book not exists' do
      let(:id) { Faker::Number.within(range: 900..1000) }
      let(:message) { "Couldn't find Book with 'id'=#{id}" }

      before { update_book }

      it 'is not found' do
        expect(response).to have_http_status :not_found
        expect(JSON(response.body)['message']).to eq message
      end
    end

    context 'when invalid attributes' do
      let(:params) { { book: attributes_for(:book, title: nil) } }
      let(:message) { "Validation failed: Title can't be blank" }

      before { update_book }

      it 'is a unprocessable entity' do
        expect(response).to have_http_status :unprocessable_entity
        expect(JSON(response.body)['message']).to eq message
      end
    end

    context 'when creating with invalid params' do
      let(:params) { {} }
      let(:message) { 'param is missing or the value is empty: book' }

      before { update_book }

      it 'is a bad request' do
        expect(response).to have_http_status :bad_request
        expect(JSON(response.body)['message']).to eq message
      end
    end
  end

  describe 'DELETE /books/:id' do
    subject(:delete_book) { delete book_path(id) }

    context 'when book exists' do
      let(:my_book) { create(:book) }
      let(:id) { my_book.id }

      before { delete_book }

      it 'delete my book' do
        expect(response).to have_http_status :ok
        expect(JSON(response.body)['message']).to eq "#{my_book.title} was deleted"
      end
    end

    context 'when book not exists' do
      let(:id) { Faker::Number.within(range: 900..1000) }
      let(:message) { "Couldn't find Book with 'id'=#{id}" }

      before { delete_book }

      it 'is not found' do
        expect(response).to have_http_status :not_found
        expect(JSON(response.body)['message']).to eq message
      end
    end
  end
end
