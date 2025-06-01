require "process"

module CryBot::Voice
  class TTS
    getter config : Hash(String, String)
    
    def initialize(@config : Hash(String, String))
    end
    
    def initialize_engine
      # Check for available TTS engines
      if system_has_command?("espeak")
        @engine = :espeak
        puts "🗣  Using espeak for text-to-speech".colorize(:green)
      elsif system_has_command?("say") # macOS
        @engine = :say
        puts "🗣  Using say for text-to-speech".colorize(:green)
      elsif system_has_command?("pico2wave")
        @engine = :pico2wave
        puts "🗣  Using pico2wave for text-to-speech".colorize(:green)
      else
        @engine = :mock
        puts "⚠️  No TTS engine found, using mock mode".colorize(:yellow)
        puts "💡 Install espeak: sudo apt install espeak".colorize(:blue)
        puts "💡 Or pico2wave: sudo apt install libttspico-utils".colorize(:blue)
      end
    end
    
    def speak(text : String)
      return if text.empty?
      
      case @engine
      when :espeak
        speak_espeak(text)
      when :say
        speak_say(text)
      when :pico2wave
        speak_pico2wave(text)
      when :mock
        speak_mock(text)
      end
    end
    
    def play_activation_sound
      case @engine
      when :espeak
        Process.run("espeak", ["-s", "200", "-p", "80", "beep"], output: Process::Redirect::Close, error: Process::Redirect::Close)
      when :say
        Process.run("say", ["beep"], output: Process::Redirect::Close, error: Process::Redirect::Close)
      when :pico2wave
        # Simple tone using aplay if available
        if system_has_command?("aplay")
          Process.run("sh", ["-c", "echo | aplay -r 22050 -c 1 -f S16_LE -d 0.1"], 
                     output: Process::Redirect::Close, error: Process::Redirect::Close)
        end
      when :mock
        puts "🔔 *beep*".colorize(:yellow)
      end
    end
    
    private def speak_espeak(text : String)
      # espeak with cyberpunk-ish voice settings
      spawn do
        Process.run("espeak", [
          "-s", "160",    # Speed
          "-p", "40",     # Pitch (lower for robotic feel)
          "-a", "100",    # Amplitude
          "-g", "10",     # Gap between words
          text
        ], output: Process::Redirect::Close, error: Process::Redirect::Close)
      end
    end
    
    private def speak_say(text : String)
      spawn do
        Process.run("say", ["-r", "180", "-v", "Alex", text], 
                   output: Process::Redirect::Close, error: Process::Redirect::Close)
      end
    end
    
    private def speak_pico2wave(text : String)
      spawn do
        # Generate WAV file and play it
        Process.run("pico2wave", ["-w", "/tmp/crybot_tts.wav", text], 
                   output: Process::Redirect::Close, error: Process::Redirect::Close)
        
        if File.exists?("/tmp/crybot_tts.wav")
          if system_has_command?("aplay")
            Process.run("aplay", ["/tmp/crybot_tts.wav"], 
                       output: Process::Redirect::Close, error: Process::Redirect::Close)
          elsif system_has_command?("paplay")
            Process.run("paplay", ["/tmp/crybot_tts.wav"], 
                       output: Process::Redirect::Close, error: Process::Redirect::Close)
          end
          File.delete("/tmp/crybot_tts.wav")
        end
      end
    end
    
    private def speak_mock(text : String)
      puts "🗣  TTS: #{text}".colorize(:blue)
    end
    
    private def system_has_command?(command : String) : Bool
      !`which #{command} 2>/dev/null`.empty?
    end
  end
end