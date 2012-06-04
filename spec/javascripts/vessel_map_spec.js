describe("Marker", function() {
	it("has id, position and icon properties", function() {
		var latlon = new LatLon(52, 4);
		var marker = new Marker(42, latlon, '/ol/img/marker.png');
		expect(marker.id).toBe(42);
		expect(marker.position).toBe(latlon);
		expect(marker.icon).toBe('/ol/img/marker.png');
	});
	
	it("can be assigned a line", function() {
	  var latlon = new LatLon(52, 4);
	  var marker = new Marker(42, latlon, '/ol/img/marker.png');
	  marker.addLine(90, 30);
	  expect(marker.line.direction).toBe(90);
	  expect(marker.line.length).toBe(30);
	  expect(marker.line.position).toBe(latlon);
	})
});

describe("Map", function() {
  var latlon;
	var map;
	var marker;
	var loader;
	
	beforeEach(function() {
    marker = new Marker(42, new LatLon(52, 4), '/ol/img/marker.png');
		latlon = new LatLon(52, 4);
		
		loader = {
		  'loadMarkers': function(cb) {
		    cb({
		      'markers': [
		        {'id': 1, 'position': new LatLon(52.1, 3.9), 'icon': '/ol/img/marker.png'}, 
		        {'id': 2, 'position': new LatLon(52.2, 3.8), 'icon': '/ol/img/marker.png'}
		        ]
		    });
		  },
		  'loadInfo': function(cb) {
		    cb('Some info');
		  }
		}		

    map = new Map('map', latlon, loader);
	});
	
	it("checks whether it is centered at a given point", function() {
		expect(map.isCenteredAt(new LatLon(52, 4))).toBeTruthy();
	});
	
	it("can zoom into an area", function() {
		var latlon1 = new LatLon(52, 4);
		var latlon2 = new LatLon(52.1, 4.1);
		map.zoomToArea(latlon1, latlon2);
	});
	
	it("allows adding markers", function() {
		map.addMarker(marker);
		expect(map.markerLayer.markers.length).toBe(1);
		expect(map.markerLayer.markers[0].icon.url).toBe('/ol/img/marker.png');
	});

  it("checks whether a marker is at a given location", function() {
    map.addMarker(marker);
    expect(map.hasMarkerAt(new LatLon(52, 4))).toBeTruthy();
  });
  
  it("checks whether a marker with a specific icon type is at a given location", function() {
    map.addMarker(marker);
    expect(map.hasMarkerAt(new LatLon(52, 4), 'n')).toBeFalsy();
    marker = new Marker(43, new LatLon(51, 3), '/ol/img/marker_n.png');
    map.addMarker(marker);
    expect(map.hasMarkerAt(new LatLon(51, 3), 'n')).toBeTruthy();
  });
  
	it("loads markers", function() {
    var latlon1 = new LatLon(52, 4);
    var latlon2 = new LatLon(52.1, 4.1);
    map.zoomToArea(latlon1, latlon2);

		spyOn(loader, 'loadMarkers').andCallThrough(); 
		map.loadMarkers();
		expect(loader.loadMarkers).toHaveBeenCalled();
		expect(map.markerLayer.markers.length).toBe(2);
	});
	
	it("can trigger the click event of a marker", function() {
	  var handler = jasmine.createSpy('handler');

    map.addMarker(marker);
    var osmMarker = map.markerLayer.markers[0];
    osmMarker.events.register('click', osmMarker, handler);
    
	  map.clickMarker(latlon);
	  expect(handler).toHaveBeenCalled();
	});
});