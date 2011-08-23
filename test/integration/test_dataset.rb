require 'helper'

module IntegrationTests
  class TestDataset < Test::Unit::TestCase
    def setup
      @tmpdir = Dir.mktmpdir('linkage')
      @tmpurl = "sqlite:/" + File.join(@tmpdir, "foo")
      Sequel.connect(@tmpurl) do |db|
        db.create_table(:foo) { primary_key(:id) }
      end
    end

    def teardown
      FileUtils.remove_entry_secure(@tmpdir)
    end
  end
end
