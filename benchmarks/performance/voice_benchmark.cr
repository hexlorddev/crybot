#!/usr/bin/env crystal

# CryBot Performance Benchmark Suite
# Tests voice recognition, command processing, and TTS performance

require "benchmark"
require "../../src/crybot"

class CryBotBenchmark
  def initialize
    @config = CryBot::Utils::Config.new("benchmark_config.json")
    @config.set("voice_engine", JSON::Any.new("mock"))
    @config.set("tts_engine", JSON::Any.new("mock"))
    @config.set("encryption_enabled", JSON::Any.new(false))
    
    @processor = CryBot::Commands::Processor.new({} of String => String)
    @logger = CryBot::Utils::Logger.new("benchmark.log", false)
    @encryptor = CryBot::Crypto::Encryptor.new("benchmark_key")
  end
  
  def run_all_benchmarks
    puts "🧊🤖 CryBot Performance Benchmark Suite".colorize(:cyan).bold
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━".colorize(:blue)
    
    benchmark_command_processing
    benchmark_encryption
    benchmark_fuzzy_matching
    benchmark_memory_usage
    benchmark_concurrent_commands
    
    puts "\n🎉 All benchmarks completed!".colorize(:green).bold
  end
  
  private def benchmark_command_processing
    puts "\n⚡ Command Processing Performance".colorize(:yellow).bold
    
    commands = [
      "help", "show cpu usage", "open browser", "git status",
      "current directory", "list files", "show memory"
    ]
    
    Benchmark.ips do |x|
      x.report("simple_commands") do
        command = commands.sample
        @processor.execute(command)
      end
      
      x.report("help_command") do
        @processor.execute("help")
      end
      
      x.report("system_commands") do
        @processor.execute("show cpu usage")
      end
    end
  end
  
  private def benchmark_encryption
    puts "\n🔐 Encryption Performance".colorize(:yellow).bold
    
    test_data = "This is a test voice command with some sensitive information."
    large_data = test_data * 100
    
    Benchmark.ips do |x|
      x.report("encrypt_small") do
        @encryptor.encrypt(test_data)
      end
      
      x.report("encrypt_large") do
        @encryptor.encrypt(large_data)
      end
      
      encrypted = @encryptor.encrypt(test_data)
      x.report("decrypt_small") do
        @encryptor.decrypt(encrypted)
      end
      
      large_encrypted = @encryptor.encrypt(large_data)
      x.report("decrypt_large") do
        @encryptor.decrypt(large_encrypted)
      end
    end
  end
  
  private def benchmark_fuzzy_matching
    puts "\n🎯 Fuzzy Matching Performance".colorize(:yellow).bold
    
    candidates = [
      "open browser", "show cpu usage", "git status", "current directory",
      "list files", "show memory", "run script", "help command"
    ]
    
    test_inputs = [
      "opn browsr", "cpu", "git stat", "where am i",
      "files", "memory", "script", "help"
    ]
    
    Benchmark.ips do |x|
      x.report("fuzzy_match") do
        input = test_inputs.sample
        CryBot::Utils::FuzzyMatcher.find_best_match(input, candidates)
      end
      
      x.report("exact_match") do
        candidate = candidates.sample
        CryBot::Utils::FuzzyMatcher.find_best_match(candidate, candidates)
      end
    end
  end
  
  private def benchmark_memory_usage
    puts "\n💾 Memory Usage Analysis".colorize(:yellow).bold
    
    initial_memory = get_memory_usage
    puts "Initial memory: #{initial_memory} KB".colorize(:white)
    
    # Create multiple instances
    instances = [] of CryBot::Commands::Processor
    100.times do
      instances << CryBot::Commands::Processor.new({} of String => String)
    end
    
    post_creation_memory = get_memory_usage
    puts "After 100 instances: #{post_creation_memory} KB".colorize(:white)
    puts "Memory per instance: #{(post_creation_memory - initial_memory) / 100} KB".colorize(:green)
    
    # Process commands
    instances.each_with_index do |processor, i|
      processor.execute("help") if i % 10 == 0
    end
    
    post_processing_memory = get_memory_usage
    puts "After processing: #{post_processing_memory} KB".colorize(:white)
    
    # Cleanup
    instances.clear
    GC.collect
    
    final_memory = get_memory_usage
    puts "After cleanup: #{final_memory} KB".colorize(:cyan)
  end
  
  private def benchmark_concurrent_commands
    puts "\n🔄 Concurrent Command Processing".colorize(:yellow).bold
    
    commands = ["help", "show cpu usage", "current directory", "list files"]
    
    Benchmark.ips do |x|
      x.report("sequential") do
        commands.each { |cmd| @processor.execute(cmd) }
      end
      
      x.report("concurrent") do
        channels = commands.map do |cmd|
          channel = Channel(CryBot::Commands::CommandResult).new
          spawn do
            result = @processor.execute(cmd)
            channel.send(result)
          end
          channel
        end
        
        channels.each(&.receive)
      end
    end
  end
  
  private def get_memory_usage : Int32
    # Simple memory usage estimation
    # In a real implementation, this would use system calls
    `ps -o rss= -p #{Process.pid}`.strip.to_i
  rescue
    0
  end
end

# Run benchmarks if this file is executed directly
if PROGRAM_NAME.includes?("performance.cr")
  benchmark = CryBotBenchmark.new
  benchmark.run_all_benchmarks
end