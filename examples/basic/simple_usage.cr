#!/usr/bin/env crystal

# Basic CryBot Usage Example
# This demonstrates the simplest way to interact with CryBot

require "../../src/crybot"

puts "🧊🤖 CryBot Basic Example".colorize(:cyan).bold
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━".colorize(:blue)

# Initialize CryBot with basic configuration
config = CryBot::Utils::Config.new
config.set("voice_engine", JSON::Any.new("mock"))
config.set("tts_engine", JSON::Any.new("mock"))

# Create CryBot instance
app = CryBot::App.new

puts "✅ CryBot initialized successfully!".colorize(:green)
puts "💡 Try these commands:".colorize(:yellow)
puts "   • help"
puts "   • show cpu usage"
puts "   • open browser"
puts "   • current directory"
puts "   • exit"

# Simulate some commands in mock mode
commands = ["help", "show cpu usage", "current directory"]

commands.each do |command|
  puts "\n🎤 Simulating command: #{command}".colorize(:cyan)
  
  # Process command directly
  processor = CryBot::Commands::Processor.new({} of String => String)
  result = processor.execute(command)
  
  if result.success
    puts "✅ #{result.response}".colorize(:green)
  else
    puts "❌ #{result.response}".colorize(:red)
  end
end

puts "\n🎉 Basic example complete!".colorize(:green).bold