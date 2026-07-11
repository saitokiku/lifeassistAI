#!/usr/bin/env ruby
# Adds the LifeAssistWidgets extension target to Runner.xcodeproj.
#
# The widget target is scripted rather than hand-written into the pbxproj
# because extension targets carry dozens of interlocking settings — a
# generator that Xcode's own library (xcodeproj gem) writes is verifiable;
# a hand-merged diff is not. Idempotent: re-running on a project that
# already has the target is a no-op.
#
#   gem install xcodeproj
#   ruby scripts/ios/add_widget_extension.rb
#
# After running on your Mac, add the App Group
# (group.com.saitokiku.lifeassist) to BOTH targets in Signing &
# Capabilities so the widgets can read today.json. CI's opt-in
# widget-experiment job runs this script and builds, without signing.

require 'xcodeproj'

PROJECT = File.expand_path('../../ios/Runner.xcodeproj', __dir__)
WIDGET_DIR = File.expand_path('../../ios/LifeAssistWidgets', __dir__)
TARGET_NAME = 'LifeAssistWidgets'
BUNDLE_ID = 'com.saitokiku.lifeassist.widgets'
DEPLOYMENT_TARGET = '17.0'

project = Xcodeproj::Project.open(PROJECT)

if project.targets.any? { |t| t.name == TARGET_NAME }
  puts "#{TARGET_NAME} target already present — nothing to do."
  exit 0
end

runner = project.targets.find { |t| t.name == 'Runner' } or
  abort 'Runner target not found'

widget = project.new_target(
  :app_extension, TARGET_NAME, :ios, DEPLOYMENT_TARGET
)

# Sources + Info.plist live in ios/LifeAssistWidgets (already in git).
group = project.main_group.new_group(TARGET_NAME, 'LifeAssistWidgets')
swift = group.new_file('LifeAssistWidgets.swift')
widget.add_file_references([swift])

# The Live Activity attributes are shared with Runner: same file,
# compiled into both targets (ActivityKit matches by type name+shape).
shared = project.files.find { |f| f.path == 'FocusTimerAttributes.swift' }
shared ||= project.main_group.new_group('Shared', 'Shared')
               .new_file('FocusTimerAttributes.swift')
widget.add_file_references([shared])

widget.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_NAME'] = '$(TARGET_NAME)' # without it the product is '.appex'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['LD_RUNPATH_SEARCH_PATHS[sdk=iphoneos*]'] =
    '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  s['INFOPLIST_FILE'] = 'LifeAssistWidgets/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  s['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
end

# Embed in Runner (PlugIns) and build first.
runner.add_dependency(widget)
embed = runner.copy_files_build_phases.find do |p|
  p.name == 'Embed Foundation Extensions'
end
embed ||= runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13' # PlugIns
build_file = embed.add_file_reference(widget.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

project.save
puts "Added #{TARGET_NAME} (#{BUNDLE_ID}); embedded in Runner."
puts 'Remaining Mac-side step: add the App Group ' \
     'group.com.saitokiku.lifeassist to Runner AND LifeAssistWidgets.'
