require "openssl"
require "base64"
require "json"

module CryBot::Crypto
  class Encryptor
    ALGORITHM = "aes-256-cbc"
    
    getter key : Bytes
    
    def initialize(password : String = "crybot_default_key_2024")
      # Derive key from password using PBKDF2
      salt = "crybot_salt_hexlord"
      @key = OpenSSL::PKCS5.pbkdf2_hmac(password, salt.to_slice, 10000, 32, OpenSSL::Algorithm::SHA256)
    end
    
    def encrypt(data : String) : String
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt
      cipher.key = @key
      
      # Generate random IV for each encryption
      iv = Random::Secure.random_bytes(cipher.iv_len)
      cipher.iv = iv
      
      # Encrypt the data
      encrypted = cipher.update(data.to_slice)
      encrypted += cipher.final
      
      # Combine IV + encrypted data and encode as base64
      result = iv + encrypted
      Base64.encode(result)
    end
    
    def decrypt(encrypted_data : String) : String
      begin
        # Decode from base64
        data = Base64.decode(encrypted_data)
        
        cipher = OpenSSL::Cipher.new(ALGORITHM)
        cipher.decrypt
        cipher.key = @key
        
        # Extract IV (first 16 bytes for AES)
        iv_size = 16
        iv = data[0, iv_size]
        encrypted_content = data[iv_size..-1]
        
        cipher.iv = iv
        
        # Decrypt
        decrypted = cipher.update(encrypted_content)
        decrypted += cipher.final
        
        String.new(decrypted)
      rescue ex
        raise "Decryption failed: #{ex.message}"
      end
    end
    
    def encrypt_log_entry(entry : Hash(String, String | Time)) : String
      json_data = entry.to_json
      encrypt(json_data)
    end
    
    def decrypt_log_entry(encrypted_entry : String) : Hash(String, String | Time)
      json_data = decrypt(encrypted_entry)
      Hash(String, String | Time).from_json(json_data)
    end
    
    # Generate a secure random key for production use
    def self.generate_secure_key : String
      Random::Secure.random_bytes(32).hexstring
    end
    
    # Hash function for integrity checking
    def hash_data(data : String) : String
      OpenSSL::Digest.new("SHA256").update(data).final.hexstring
    end
  end
end