require "json"
require "process"

module CryBot::Voice
  class Recognizer
    WAKE_WORDS = ["hey crybot", "crybot", "crystal bot"]
    
    getter config : Hash(String, String)
    
    def initialize(@config : Hash(String, String))
    end
    
    def initialize_engine
      # Check for available voice recognition engines
      if system_has_command?("whisper")
        @engine = :whisper
        puts "🎤 Using Whisper for voice recognition".colorize(:green)
      elsif system_has_command?("vosk-transcriber")
        @engine = :vosk
        puts "🎤 Using Vosk for voice recognition".colorize(:green)
      else
        @engine = :mock
        puts "⚠️  No voice engine found, using mock mode".colorize(:yellow)
        puts "💡 Install Whisper: pip install openai-whisper".colorize(:blue)
        puts "💡 Or install Vosk: pip install vosk".colorize(:blue)
      end
    end
    
    def listen_for_wake_word : Bool
      case @engine
      when :whisper
        listen_whisper_wake_word
      when :vosk
        listen_vosk_wake_word  
      when :mock
        listen_mock_wake_word
      else
        false
      end
    end
    
    def get_command : String?
      case @engine
      when :whisper
        get_whisper_command
      when :vosk
        get_vosk_command
      when :mock
        get_mock_command
      else
        nil
      end
    end
    
    private def listen_whisper_wake_word : Bool
      # Record a short audio clip and check for wake word
      begin
        # Use arecord to capture audio
        process = Process.new("timeout", ["3", "arecord", "-f", "cd", "-t", "wav", "/tmp/crybot_wake.wav"], 
                              output: Process::Redirect::Close, error: Process::Redirect::Close)
        process.wait
        
        # Transcribe with whisper
        result = `whisper /tmp/crybot_wake.wav --language en --task transcribe --output_format txt --output_dir /tmp 2>/dev/null`
        
        if File.exists?("/tmp/crybot_wake.txt")
          text = File.read("/tmp/crybot_wake.txt").downcase.strip
          File.delete("/tmp/crybot_wake.txt")
          File.delete("/tmp/crybot_wake.wav") if File.exists?("/tmp/crybot_wake.wav")
          
          return WAKE_WORDS.any? { |wake_word| text.includes?(wake_word) }
        end
      rescue
      end
      false
    end
    
    private def get_whisper_command : String?
      begin
        puts "🎤 Recording command (5 seconds)...".colorize(:yellow)
        
        # Record command
        process = Process.new("timeout", ["5", "arecord", "-f", "cd", "-t", "wav", "/tmp/crybot_command.wav"], 
                              output: Process::Redirect::Close, error: Process::Redirect::Close)
        process.wait
        
        # Transcribe
        result = `whisper /tmp/crybot_command.wav --language en --task transcribe --output_format txt --output_dir /tmp 2>/dev/null`
        
        if File.exists?("/tmp/crybot_command.txt")
          text = File.read("/tmp/crybot_command.txt").strip
          File.delete("/tmp/crybot_command.txt")
          File.delete("/tmp/crybot_command.wav") if File.exists?("/tmp/crybot_command.wav")
          
          return text
        end
      rescue
      end
      nil
    end
    
    private def listen_vosk_wake_word : Bool
      # Implementation for Vosk would go here
      # For now, falling back to mock
      listen_mock_wake_word
    end
    
    private def get_vosk_command : String?
      # Implementation for Vosk would go here
      get_mock_command
    end
    
    private def listen_mock_wake_word : Bool
      print "🎤 Press ENTER to simulate wake word detection: ".colorize(:cyan)
      gets
      true
    end
    
    private def get_mock_command : String?
      print "🎤 Enter command: ".colorize(:cyan)
      command = gets
      command ? command.strip : nil
    end
    
    private def system_has_command?(command : String) : Bool
      !`which #{command} 2>/dev/null`.empty?
    end
  end
end