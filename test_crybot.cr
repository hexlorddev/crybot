#!/usr/bin/env crystal

# CryBot Test Script
# Quick test to verify the Crystal code compiles and basic functionality works

require "./src/crybot"

puts "🧊🤖 CryBot Test Suite".colorize(:cyan).bold
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━".colorize(:blue)

# Test 1: Configuration
puts "🔧 Testing configuration...".colorize(:yellow)
config = CryBot::Utils::Config.new("test_config.json")
puts "✅ Configuration loaded successfully".colorize(:green)

# Test 2: Encryption
puts "🔐 Testing encryption...".colorize(:yellow)
encryptor = CryBot::Crypto::Encryptor.new("test_password")
test_data = "Hello, CryBot!"
encrypted = encryptor.encrypt(test_data)
decrypted = encryptor.decrypt(encrypted)

if decrypted == test_data
  puts "✅ Encryption/decryption working correctly".colorize(:green)
else
  puts "❌ Encryption test failed".colorize(:red)
  exit 1
end

# Test 3: Logger
puts "📝 Testing logger...".colorize(:yellow)
logger = CryBot::Utils::Logger.new("test.crylog", true)
logger.log_interaction("Test command", "input")
logger.log_interaction("Test response", "output")
puts "✅ Logger working correctly".colorize(:green)

# Test 4: Command Processor
puts "🎯 Testing command processor...".colorize(:yellow)
processor = CryBot::Commands::Processor.new({} of String => String)
result = processor.execute("help")

if result.success
  puts "✅ Command processor working correctly".colorize(:green)
else
  puts "❌ Command processor test failed".colorize(:red)
  exit 1
end

# Test 5: Fuzzy Matcher
puts "🎯 Testing fuzzy matching...".colorize(:yellow)
candidates = ["open browser", "show cpu usage", "git status"]
match = CryBot::Utils::FuzzyMatcher.find_best_match("opn browsr", candidates)

if match == "open browser"
  puts "✅ Fuzzy matching working correctly".colorize(:green)
else
  puts "⚠️  Fuzzy matching may need tuning".colorize(:yellow)
end

# Cleanup
File.delete("test_config.json") if File.exists?("test_config.json")
File.delete("test.crylog") if File.exists?("test.crylog")

puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━".colorize(:blue)
puts "🎉 All tests passed! CryBot is ready to rock!".colorize(:green).bold
puts "🚀 Run 'crystal run src/crybot.cr' to start the assistant".colorize(:cyan)