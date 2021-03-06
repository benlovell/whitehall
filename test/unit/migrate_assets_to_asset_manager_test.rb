require "test_helper"

class MigrateAssetsToAssetManagerTest < ActiveSupport::TestCase
  setup do
    Services.asset_manager.stubs(:whitehall_asset).raises(GdsApi::HTTPNotFound.new(404))

    organisation_logo_dir = File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'organisation', 'logo', '1')
    FileUtils.mkdir_p(organisation_logo_dir)

    @organisation_logo_path = File.join(organisation_logo_dir, 'logo.jpg')
    dummy_asset_path = Rails.root.join('test', 'fixtures', 'images', '960x640_jpeg.jpg')
    FileUtils.cp(dummy_asset_path, @organisation_logo_path)

    @organisation_logo_file = File.open(@organisation_logo_path)

    @subject = MigrateAssetsToAssetManager.new('system/uploads/organisation/logo')
  end

  test 'it calls create_whitehall_asset for each file in the list' do
    Services.asset_manager.expects(:create_whitehall_asset)
      .with(has_entry(:file, responds_with(:read, File.read(@organisation_logo_path))))

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the legacy file path' do
    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:legacy_url_path, '/government/uploads/system/uploads/organisation/logo/1/logo.jpg')
    )

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the legacy last modified time' do
    expected_last_modified = File.stat(@organisation_logo_file.path).mtime

    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:legacy_last_modified, expected_last_modified)
    )

    @subject.perform
  end

  test 'it calls create_whitehall_asset with the legacy etag' do
    expected_etag = [
      File.stat(@organisation_logo_path).mtime.to_i.to_s(16),
      File.stat(@organisation_logo_path).size.to_i.to_s(16),
    ].join('-')

    Services.asset_manager.expects(:create_whitehall_asset).with(
      has_entry(:legacy_etag, expected_etag)
    )

    @subject.perform
  end

  test 'it does not call create_whitehall_asset if the asset already exists in asset manager' do
    Services.asset_manager.stubs(:whitehall_asset).returns('id' => 'http://asset-manager/assets/asset-id')
    Services.asset_manager.expects(:create_whitehall_asset).never

    @subject.perform
  end

  test 'to_s is a count of the number of files to be migrated' do
    assert_equal 'Migrating 1 file', @subject.to_s
  end
end

class AssetFilePathsTest < ActiveSupport::TestCase
  setup do
    organisation_logo_dir = File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'organisation', 'logo', '1')
    other_asset_dir = File.join(Whitehall.clean_uploads_root, 'system', 'uploads', 'other')

    FileUtils.mkdir_p(organisation_logo_dir)
    FileUtils.mkdir_p(other_asset_dir)

    organisation_logo_path = File.join(organisation_logo_dir, 'logo.jpg')
    other_asset_path = File.join(other_asset_dir, 'other_asset.png')
    dummy_asset_path = Rails.root.join('test', 'fixtures', 'images', '960x640_jpeg.jpg')

    FileUtils.cp(dummy_asset_path, organisation_logo_path)
    FileUtils.cp(dummy_asset_path, other_asset_path)

    @organisation_logo = File.open(organisation_logo_path)
    @other_asset = File.open(other_asset_path)

    @subject = MigrateAssetsToAssetManager::AssetFilePaths.new('system/uploads/organisation/logo')
  end

  test 'delegates each to file_paths' do
    assert @subject.respond_to?(:each)
  end

  test 'delegates size to file_paths' do
    assert @subject.respond_to?(:size)
  end

  test '#files includes only organisation logos' do
    assert_equal 1, @subject.file_paths.size
  end

  test '#files does not includes directories' do
    @subject.file_paths.each do |file_path|
      refute File.directory?(file_path)
    end
  end

  test '#files includes all files when initialised with a top level target directory' do
    subject = MigrateAssetsToAssetManager::AssetFilePaths.new('system/uploads')
    assert_equal 2, subject.file_paths.size
  end
end

class AssetFileTest < ActiveSupport::TestCase
  setup do
    @path = Rails.root.join('test/fixtures/logo.png')
    file = MigrateAssetsToAssetManager::AssetFile.open(@path)
    @parts = file.legacy_etag.split('-')
  end

  test 'returns string made up of 2 parts separated by a hyphen' do
    assert_equal 2, @parts.length
  end

  test "has 1st part as file mtime (unix time in seconds written in lowercase hex)" do
    last_modified_hex = @parts.first
    last_modified = last_modified_hex.to_i(16)

    assert_equal File.stat(@path).mtime.to_i, last_modified
  end

  test "has 2nd part as file size (number of bytes written in lowercase hex)" do
    size_hex = @parts.last
    size = size_hex.to_i(16)

    assert_equal File.stat(@path).size, size
  end
end
