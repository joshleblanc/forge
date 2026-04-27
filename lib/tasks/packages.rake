# frozen_string_literal: true

namespace :packages do
  desc "Build and attach ZIP archives for every PackageVersion from packages/<name>/"
  task repackage: :environment do
    total = 0
    ok = 0
    failed = []

    PackageVersion.includes(:package).find_each do |version|
      total += 1
      begin
        PackagePackager.new(version.package, version).build_and_attach
        ok += 1
        src = PackagePackager::PACKAGES_ROOT.join(version.package.name)
        marker = File.directory?(src) ? "+" : "·"
        puts "  #{marker} #{version.package.name}@#{version.version}"
      rescue => e
        failed << "#{version.package.name}@#{version.version}: #{e.message}"
      end
    end

    puts ""
    puts "Repackaged #{ok} / #{total} versions"
    unless failed.empty?
      puts "Failures:"
      failed.each { |line| puts "  ! #{line}" }
    end
  end

  desc "Repackage a single package: rake 'packages:repackage_one[package_name]'"
  task :repackage_one, [:name] => :environment do |_t, args|
    name = args[:name] or abort "Usage: rake 'packages:repackage_one[package_name]'"
    pkg = Package.find_by!(name: name)
    pkg.versions.each do |version|
      PackagePackager.new(pkg, version).build_and_attach
      puts "+ #{pkg.name}@#{version.version}"
    end
  end
end
