require "json"

module CryBot::Utils
  class Config
    DEFAULT_CONFIG = {
      "log_file" => "crybot.crylog",
      "encryption_enabled" => true,
      "voice_engine" => "auto",
      "tts_engine" => "auto",
      "wake_words" => ["hey crybot", "crybot"],
      "max_command_length" => 10,
      "response_timeout" => 30,
      "log_retention_days" => 30,
      "plugin_directory" => "plugins",
      "volume" => 80,
      "speech_rate" => 160
    }
    
    getter config : Hash(String, JSON::Any)
    
    def initialize(config_file : String = "crybot_config.json")
      @config_file = config_file
      @config = load_config
    end
    
    def log_file : String
      @config["log_file"].as_s
    end
    
    def encryption_enabled : Bool
      @config["encryption_enabled"].as_bool
    end
    
    def voice_config : Hash(String, String)
      {
        "engine" => @config["voice_engine"].as_s,
        "wake_words" => @config["wake_words"].as_a.join(","),
        "max_length" => @config["max_command_length"].as_i.to_s,
        "timeout" => @config["response_timeout"].as_i.to_s
      }
    end
    
    def tts_config : Hash(String, String)
      {
        "engine" => @config["tts_engine"].as_s,
        "volume" => @config["volume"].as_i.to_s,
        "rate" => @config["speech_rate"].as_i.to_s
      }
    end
    
    def commands_config : Hash(String, String)
      {
        "plugin_directory" => @config["plugin_directory"].as_s,
        "timeout" => @config["response_timeout"].as_i.to_s
      }
    end
    
    def set(key : String, value : JSON::Any)
      @config[key] = value
      save_config
    end
    
    def get(key : String) : JSON::Any?
      @config[key]?
    end
    
    def save_config
      begin
        File.write(@config_file, @config.to_pretty_json)
        puts "💾 Configuration saved to #{@config_file}".colorize(:green)
      rescue ex
        puts "⚠️  Failed to save config: #{ex.message}".colorize(:red)
      end
    end
    
    def reset_to_defaults
      @config = DEFAULT_CONFIG.transform_values { |v| JSON::Any.new(v) }
      save_config
      puts "🔄 Configuration reset to defaults".colorize(:yellow)
    end
    
    def show_config
      puts "🔧 CryBot Configuration:".colorize(:cyan).bold
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━".colorize(:blue)
      
      @config.each do |key, value|
        case value
        when JSON::Any
          display_value = case value.raw
          when Bool
            value.as_bool ? "✅ enabled" : "❌ disabled"
          when Array
            value.as_a.map(&.as_s).join(", ")
          else
            value.to_s
          end
          
          puts "#{key.ljust(20)} : #{display_value}".colorize(:white)
        end
      end
      puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━".colorize(:blue)
    end
    
    private def load_config : Hash(String, JSON::Any)
      if File.exists?(@config_file)
        begin
          content = File.read(@config_file)
          loaded_config = Hash(String, JSON::Any).from_json(content)
          
          # Merge with defaults to ensure all keys exist
          merged_config = DEFAULT_CONFIG.transform_values { |v| JSON::Any.new(v) }
          loaded_config.each { |k, v| merged_config[k] = v }
          
          puts "📖 Loaded configuration from #{@config_file}".colorize(:green)
          return merged_config
        rescue ex
          puts "⚠️  Failed to load config, using defaults: #{ex.message}".colorize(:yellow)
        end
      else
        puts "📄 Creating default configuration file".colorize(:blue)
        default_config = DEFAULT_CONFIG.transform_values { |v| JSON::Any.new(v) }
        save_config_to_file(default_config)
        return default_config
      end
      
      DEFAULT_CONFIG.transform_values { |v| JSON::Any.new(v) }
    end
    
    private def save_config_to_file(config : Hash(String, JSON::Any))
      begin
        File.write(@config_file, config.to_pretty_json)
      rescue ex
        puts "⚠️  Failed to create config file: #{ex.message}".colorize(:red)
      end
    end
  end
end