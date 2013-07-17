module Aggcat
  class Batch < Aggcat::Base

    BASE_URL = 'https://financialdatafeed.platform.intuit.com/v1'

    def initialize(options={})
      raise ArgumentError.new('batch_id is required for scoping batch requests') if options[:batch_id].nil? || options[:batch_id].to_s.empty?
      options[:open_timeout] ||= OPEN_TIMEOUT
      options[:read_timeout] ||= READ_TIMEOUT
      options[:verbose] ||= false
      Aggcat::Configurable::KEYS.each do |key|
        instance_variable_set(:"@#{key}", !options[key].nil? ? options[key] : Aggcat.instance_variable_get(:"@#{key}"))
      end
    end
    
    def list_files
      get("/export/files")
    end
    
    def get_file(filename, range = nil)
      validate(filename: filename)
      get("/export/files/#{filename}")
    end
    
    # This is a "soft" delete so the file will remain for housekeeping but will not display in the listFiles API call.
    def delete_file(filename)
      validate(filename: filename)
      delete("/export/files/#{filename}")
    end
    
    protected

    def get(path, headers = {})
      request(:get, path, headers)
    end

    def post(path, body, headers = {})
      request(:post, path, body, headers.merge({'Content-Type' => 'application/xml'}))
    end

    def put(path, body, headers = {})
      request(:put, path, body, headers.merge({'Content-Type' => 'application/xml'}))
    end

    def delete(path, headers = {})
      request(:delete, path, headers)
    end

    private

    def request(http_method, path, *options)
      tries = 0
      begin
        response = oauth_client.send(http_method, BASE_URL + path, *options)
        result = {:status_code => response.code}
        if response.content_type.include?('application/octet-stream')
          sio = StringIO.new(response.body)
          gz = Zlib::GzipReader.new(sio)
          result[:result] = gz.read
        else
          result[:result] = parse_xml(response.body)
        end
        if response['challengeSessionId']
          result[:challenge_session_id] = response['challengeSessionId']
          result[:challenge_node_id] = response['challengeNodeId']
        end
        return result
      rescue => e
        raise e if tries >= 1
        puts "failed to make API call - #{e.message}, retrying"
        oauth_token(true)
        tries += 1
      end while tries == 1
    end

    def validate(args)
      args.each do |name, value|
        if value.nil? || value.to_s.empty?
          raise ArgumentError.new("#{name} is required")
        end
      end
    end
    
    
  end
end