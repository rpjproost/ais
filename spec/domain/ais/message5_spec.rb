require 'spec_helper'

module Domain::AIS
  describe Message5 do
    it "has mmsi and type properties" do
      m = Message5.new(244314000)
      m.type.should eq(5)
    end
    
    it "has vessel_type property" do
      vt = Domain::VesselType.from_str('Passenger')
        
      m = Message5.new(244314000)
      m.vessel_type.should eq(nil)
      m.vessel_type = vt 
      m.vessel_type.should eq(vt)
    end    
    
    describe "payload" do
      it "returns the payload as bit string" do
        expected = "50004lP00000000000000000000000000000000t000000000000000000000000000000"
        m = Message5.new(1234)
        m.vessel_type = Domain::VesselType.from_str('Passenger')
        Domain::AIS::SixBitEncoding.encode(m.payload).should eq(expected)
      end
    end
  end
end