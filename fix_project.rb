#\!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'GarageOpenerDemo.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the target
target = project.targets.find { |t| t.name == 'GarageOpenerDemo' }

# Remove base configuration references
target.build_configurations.each do |config|
  config.base_configuration_reference = nil
end

# Remove CocoaPods build phases
target.build_phases.each do |phase|
  if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
    if phase.name && (phase.name.include?('Pods') || phase.name.include?('[CP]'))
      target.build_phases.delete(phase)
    end
  end
  
  # Also check for framework dependencies in the link phase
  if phase.is_a?(Xcodeproj::Project::Object::PBXFrameworksBuildPhase)
    phase.files.each do |build_file|
      if build_file.file_ref && build_file.file_ref.path && (
         build_file.file_ref.path.include?('Pods_') || 
         build_file.file_ref.path.include?('AnyCodable') || 
         build_file.file_ref.path.include?('CBORCoding') || 
         build_file.file_ref.path.include?('Datadog') || 
         build_file.file_ref.path.include?('Mixpanel'))
        phase.files.delete(build_file)
      end
    end
  end
end

# Save the changes
project.save

puts "Successfully removed all CocoaPods references from project\!"
