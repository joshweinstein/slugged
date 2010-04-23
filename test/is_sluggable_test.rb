require 'helper'
require 'digest/md5'

class IsSluggableTest < Test::Unit::TestCase
  with_tables :slugs, :users do
    
    context 'with the default slug options' do
      
      setup { setup_slugs! }
      
      should 'correctly sluggify a value' do
        user = User.create(:name => "Bob")
        assert_equal "bob", user.to_param
        assert_equal "bob", user.cached_slug
      end

      should 'generate a uuid in place of a slug' do
        user = User.create(:name => '')
        assert user.cached_slug.present?
      end

      should 'return need to generate a slug when the cahced slug is blank' do
        user = User.new(:name => "Ninja Stuff")
        assert user.cached_slug.blank?
        assert user.should_generate_slug?
        user.save
        assert user.cached_slug.present?
        assert !user.should_generate_slug?
        user.name = 'Awesome'
        assert user.should_generate_slug?
      end
      
      should "let you find a record by it's id as needed" do
        user = User.create :name => "Bob"
        assert_equal user, User.find_using_slug(user.id)
        assert_equal user, User.find_using_slug(user.id.to_i)
      end

      should 'default to generate a uuid' do
        user = User.create :name => ""
        assert_match /\A[a-zA-Z0-9]{32}\Z/, user.cached_slug.gsub("-", "")
        user = User.create
        assert_match /\A[a-zA-Z0-9]{32}\Z/, user.cached_slug.gsub("-", "")
      end

      should 'automatically append a sequence to the end of conflicting slugs' do
        u1 = User.create :name => "ninjas Are awesome"
        u2 = User.create :name => "Ninjas are awesome"
        assert_equal "ninjas-are-awesome",    u1.to_slug
        assert_equal "ninjas-are-awesome--1", u2.to_slug
      end

      should 'let you find out if there is a better way of finding a slug' do
        user = User.create :name => "Bob"
        user.update_attributes! :name => "Ralph"
        assert !User.find_using_slug("ralph").has_better_slug?
        assert User.find_using_slug("bob").has_better_slug?
        assert User.find_using_slug(user.id).has_better_slug?
      end
      
    end
    
    should 'let you disable syncing a slug' do
      setup_slugs! :sync => false
      user = User.create(:name => "Ninja User")
      assert !user.should_generate_slug?
      user.name = "Another User Name"
      assert !user.should_generate_slug?
    end
    
  end
end