require 'spec_helper'

describe Marker do
  it "has an id, position and icon" do
    id = 4242
    position = Domain::LatLon.new(10, 20) 
    marker = Marker.new(id, position, '/ol/img/marker.png')
    marker.id.should eq(id)
    marker.position.should eq(position)
    marker.icon.should eq('/ol/img/marker.png');
  end

  it "can be compared to other markers" do
    m1 = Marker.new(1, Domain::LatLon.new(10, 20), '/ol/img/marker.png')
    m2 = Marker.new(1, Domain::LatLon.new(10, 20), '/ol/img/marker.png')
    m3 = Marker.new(2, Domain::LatLon.new(10, 20), '/ol/img/marker.png')
    m4 = Marker.new(2, Domain::LatLon.new(20, 20), '/ol/img/marker.png')
    m5 = Marker.new(2, Domain::LatLon.new(20, 20), '/ol/img/marker2.png')
    
    m1.should eq(m2)
    m2.should_not eq(m3)
    m3.should_not eq(m4)
    m4.should_not eq(m5)
  end

  describe "from_vessel" do
    it "can create a marker from a Domain::Vessel" do
      vessel = Domain::Vessel.new(4321, Domain::Vessel::CLASS_A)
      vessel.position = Domain::LatLon.new(30, 40)
      marker = Marker.from_vessel(vessel)
      marker.id.should eq(vessel.mmsi)
      marker.position.should eq(vessel.position)
      marker.icon.should eq('/markers/v.png')
    end
  end
  
  describe "icon_from_vessel" do
    it "chooses the correct icon based on heading" do
      vessel = Domain::Vessel.new(4321, Domain::Vessel::CLASS_A)
      vessel.position = Domain::LatLon.new(30, 40)
      marker = Marker.from_vessel(vessel)
      
      {10 => 'n', 80 => 'e', 138 => 's'}.each do |heading,icon|    
        vessel.heading = heading
        marker = Marker.from_vessel(vessel)
        marker.icon.should eq("/markers/v_#{icon}.png")
      end
    end
  end
end