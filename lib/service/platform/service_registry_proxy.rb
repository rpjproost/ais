require 'ffi-rzmq'
require_relative 'base_service'
require_relative '../vessel_service_proxy'
require_relative '../transmitter_proxy'

module Service
  module Platform
    class ServiceRegistryProxy
      attr_writer :context
      
      PROXIES = { 
        'ais/transmitter' => Service::TransmitterProxy,
        'ais/vessels'     => Service::VesselServiceProxy,
        'ais/message'     => nil
      }
    
      def initialize(endpoint)
        @endpoint = endpoint
        @context = ZMQ::Context.new
      end
    
      def request(req)
        socket = @context.socket(ZMQ::REQ)
        rc = socket.connect(@endpoint)
        if ZMQ::Util.resultcode_ok?(rc)
          begin
            socket.send_string(req)
            socket.recv_string(res = '')
            response = nil if res == ''
          ensure
            socket.close
          end
        else
          raise RuntimeError, "Couldn't connect to #{ep}"
        end
        
        res
      end
 
      def register(name, endpoint)
        request("REGISTER #{name} #{endpoint}")
      end
      
      def lookup(name)
        request("LOOKUP #{name}")
      end
    
      def bind(name)
        endpoint = lookup(name)
        socket = @context.socket(ZMQ::REQ)
        rc = socket.connect(endpoint)
        if ZMQ::Util.resultcode_ok?(rc)
          proxy = PROXIES[name].new(socket) 
          begin
            yield proxy
          ensure
            socket.close
          end
        else
          raise RuntimeError, "Couldn't connect to #{ep}"
        end
      end
    end
  end
end