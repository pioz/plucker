# frozen_string_literal: true

require 'test_helper'

class TestPlucker < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Plucker::VERSION
  end

  def test_pluck_symbol
    create(:author, name: 'Henry')

    authors = Author.plucker(:name)

    assert_equal 1, authors.size
    author = authors.first

    assert_kind_of Struct, author
    assert_equal 'Henry', author.name
    assert_equal ['Henry'], author.to_a
    assert_raises NoMethodError do
      author.id
    end
  end

  def test_pluck_all
    time = Time.parse('2023-11-21 00:00:00 UTC')
    create(:author, id: 1, name: 'Henry', created_at: time, updated_at: time)

    authors = Author.plucker(:all)

    assert_equal 1, authors.size
    author = authors.first

    assert_equal [1, 'Henry', time, time], author.to_a
  end

  def test_pluck_join_table_all
    create(:post, title: 'How to make pizza', body: 'Anim ullamco.', author: create(:author, name: 'Henry'))

    posts = Post.joins(:author).plucker(:*, 'authors.*')

    assert_equal 1, posts.size
    post = posts.first

    assert post.id
    assert post.author_id
    assert_equal 'How to make pizza', post.title
    assert_equal 'Anim ullamco.', post.body
    assert post.created_at
    assert post.updated_at
    assert_equal post.author_id, post.authors_id
    assert_equal 'Henry', post.authors_name
    assert post.authors_created_at
    assert post.authors_updated_at
  end

  def test_pluck_string
    create(:post, title: 'How to make pizza', body: 'Anim ullamco.')

    posts = Post.plucker('title', 'posts.body')

    assert_equal 1, posts.size
    post = posts.first

    assert_kind_of Struct, post
    assert_equal 'How to make pizza', post.title
    assert_equal 'Anim ullamco.', post.posts_body
    assert_equal ['How to make pizza', 'Anim ullamco.'], post.to_a
    assert_raises NoMethodError do
      post.id
    end
  end

  def test_pluck_hash
    create(:post, title: 'How to make pizza', body: 'Anim ullamco.')

    posts = Post.plucker(text: :body)

    assert_equal 1, posts.size
    post = posts.first

    assert_kind_of Struct, post
    assert_equal 'Anim ullamco.', post.text
    assert_equal ['Anim ullamco.'], post.to_a
    assert_raises NoMethodError do
      post.body
    end
  end

  def test_pluck_many
    create(:author, name: 'Henry')
    create(:author, name: 'Joseph')

    authors = Author.plucker(:name)

    assert_equal 2, authors.size
    assert_equal [{ 'name' => 'Henry' }, { 'name' => 'Joseph' }], authors.as_json
  end

  def test_pluck_complex
    create(:post, title: 'How to make pizza', body: 'Anim ullamco.', author: create(:author, name: 'Henry'), comments: build_pair(:comment))
    create(:post, title: 'How to make pasta', body: 'Lorem ipsum mollit id nulla veniam.', author: create(:author, name: 'Henry'), comments: build_list(:comment, 3))

    posts = Post.joins(:author, :comments).group(:id).plucker(:title, 'authors.name', { comments_count: 'COUNT(comments.id)' })

    assert_equal 2, posts.size
    post1, post2 = *posts

    assert_equal 'How to make pizza', post1.title
    assert_equal 'Henry', post1.authors_name
    assert_equal 2, post1.comments_count
    assert_equal 'How to make pasta', post2.title
    assert_equal 'Henry', post2.authors_name
    assert_equal 3, post2.comments_count
    assert_equal [
      { 'title' => 'How to make pizza', 'authors_name' => 'Henry', 'comments_count' => 2 },
      { 'title' => 'How to make pasta', 'authors_name' => 'Henry', 'comments_count' => 3 }
    ], posts.as_json
  end

  def test_struct_block
    create(:author, name: 'Henry')

    authors = Author.plucker(:name) do
      def upcase_name
        self.name.upcase
      end

      def as_json
        super.tap do |json|
          json['upcase_name'] = self.upcase_name
        end
      end
    end

    assert_equal 1, authors.size
    author = authors.first

    assert_equal 'Henry', author.name
    assert_equal 'HENRY', author.upcase_name

    assert_equal [{ 'name' => 'Henry', 'upcase_name' => 'HENRY' }], authors.as_json
  end

  def test_pluck_not_existing_column
    create(:author, name: 'Henry')

    error = assert_raises ActiveRecord::StatementInvalid do
      Author.plucker(:age)
    end

    assert_equal 'SQLite3::SQLException: no such column: age', error.message
  end

  def test_invalid_plucker_argument
    error = assert_raises RuntimeError do
      Post.plucker(1)
    end

    assert_equal "Invalid plucker argument: '1'", error.message
  end
end
