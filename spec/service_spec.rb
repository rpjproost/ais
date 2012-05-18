require 'spec_helper'
require 'ffi-rzmq'
include Domain
include Service

describe Service::ServiceManager do
  it "starts and stops all services in its bindings" do
    class ServiceMock
      @@started = []
      @@stopped = []
      
      def start(endpoint)
        @@started << endpoint
        @endpoint = endpoint    
      end
      
      def stop()
        @@stopped << @endpoint
      end
      
      def self.started
        @@started
      end
      
      def self.stopped
        @@stopped
      end
    end
    
    sm = ServiceManager.new
    sm.bindings = [{:endpoint => 'tcp://*:21000', :service => ServiceMock},
                   {:endpoint => 'tcp://*:21001', :service => ServiceMock}]
    sm.start
    ServiceMock.started.should include('tcp://*:21000', 'tcp://*:21000')
    sm.stop
    ServiceMock.stopped.should include('tcp://*:21000', 'tcp://*:21000')
  end
end

describe Service::BaseService do
  it "can be started and stopped" do
    service = Service::BaseService.new
    service.start 'tcp://*:21000'
    service.stop
  end
  
  it "accepts requests on a socket" do
    class EchoServiceMock < Service::BaseService
      def processRequest(data)
        data
      end
    end
    service = EchoServiceMock.new
    service.start 'tcp://*:21000'
     
    ctx = ZMQ::Context.new
    sock = ctx.socket ZMQ::REQ
    rc = sock.connect 'tcp://localhost:21000'
    ZMQ::Util.resultcode_ok?(rc).should be_true
    begin
      sock.send_string(Marshal.dump("Test"))
      response = ''
      sock.recv_string(response)
      response.should eq(Marshal.dump("Test"))
    ensure
      sock.close
      service.stop
    end
  end  
end

describe Service::TransmitterService do
  it "accepts requests" do
    vessel = Vessel.new(1234, Vessel::CLASS_A)
    vessel.position = LatLon.new(3.0, 4.0) 

    service = TransmitterService.new
    service.processRequest(Marshal.dump(vessel))
  end
end

describe Service::VesselService do
  it "returns a list of vessels" do
    vessel1 = Vessel.new(1234, Vessel::CLASS_A)
    vessel1.position = LatLon.new(3.0, 4.0) 
    vessel2 = Vessel.new(5678, Vessel::CLASS_A)
    vessel2.position = LatLon.new(5.0, 6.0)

    service = VesselService.new
    service.receiveVessel(vessel1)
    service.receiveVessel(vessel2)
    vessels = service.processRequest('')
    vessels.should eq(Marshal.dump([vessel1, vessel2]))
  end
end

describe Service::ServiceRegistry do
  describe "bind" do
    it "returns a service binding" do
      socket = double("Socket")
      socket.stub(:connect) { 0 }
      socket.stub(:close) { 0 }

      context = double("Context")
      context.stub(:socket) { socket }

      registry = ServiceRegistry.new context
      proxies = {'ais/transmitter' => TransmitterProxy, 'ais/vessels' => VesselServiceProxy}
      proxies.each do |name, klass|
        registry.bind(name) do |service|
          service.should be_a_kind_of(klass) 
        end
      end      
    end

    it "raises an exception when the socket fails" do
      socket = double("Socket")
      socket.stub(:connect) { -1 }

      context = double("Context")
      context.stub(:socket) { socket }

      registry = ServiceRegistry.new context

      socket.stub(:connect) { -1 }
      registry = ServiceRegistry.new context
      expect { registry.bind 'ais/transmitter' }.to raise_error
    end

    it "closes all sockets when stopped" do
      socket = double("Socket")
      socket.stub(:connect) { 0 }
      socket.should_receive(:close)

      context = double("Context")
      context.stub(:socket) { socket }

      registry = ServiceRegistry.new context
      registry.bind('ais/transmitter') {|service| }
    end
  end
end

describe Service::TransmitterProxy do
  it "sends position reports to the Transmitter service" do
    vessel = "Vessel"
    socket = double('Socket')
    socket.should_receive(:send_string).with(Marshal.dump(vessel))

    t = TransmitterProxy.new socket
    t.send_position_report_for vessel
  end
end

describe Service::VesselServiceProxy do
  it "requests vessel information from the Vessel service" do
    vessel1 = Vessel.new(1234, Vessel::CLASS_A)
    vessel1.position = LatLon.new(3.0, 4.0) 
    vessel2 = Vessel.new(5678, Vessel::CLASS_A)
    vessel2.position = LatLon.new(5.0, 6.0)
    vessels = [vessel1, vessel2] 
    
    socket = (Class.new do
      def initialize(vessels)
        @vessels = vessels
      end
      
      def send_string(string)
      end
      
      def recv_string(string)
        string.replace(Marshal.dump(@vessels))
      end
    end).new(vessels)
    
    t = VesselServiceProxy.new socket
    t.vessels.should eq(vessels)
  end  
end
