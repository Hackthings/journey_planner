# Unofficial TFL Journey Planner Gem

[![Gem Version](https://badge.fury.io/rb/journey_planner.svg)](http://badge.fury.io/rb/journey_planner) [![Build Status](https://travis-ci.org/jpatel531/journey_planner.svg?branch=master)](https://travis-ci.org/jpatel531/journey_planner) [![Test Coverage](https://codeclimate.com/github/jpatel531/journey_planner/badges/coverage.svg)](https://codeclimate.com/github/jpatel531/journey_planner)

A Ruby-wrapper for the TFL Journey Planner API.

![Map](http://cdn.londonandpartners.com/images/explorer-map/tubemap-2012-12.png)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'journey_planner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install journey_planner

## Usage

```
irb
```
```ruby
require 'journey_planner'

client = TFLJourneyPlanner::Client.new(app_id: your_app_id, app_key: your_app_key)

journeys = client.get_journeys from: "old street underground station", to: "oxford circus underground station"

# => returns an array of Journey objects, each representing one of the possible journeys

```

### Example Methods

####Instructions

The `instructions` method on a journey instance returns a hash of instructions, with the keys as departure and arrival times, and the values as arrays of verbal instructions.

```ruby
journeys.first.instructions
# {"Sep 5 2014 16:21 - Sep 5 2014 16:27"=>["Northern line to Euston / Northern line towards Edgware, Mill Hill East, or High Barnet"], 
# "Sep 5 2014 16:32 - Sep 5 2014 16:35"=>["Victoria line to Oxford Circus / Victoria line towards Brixton"]} 
```

####Disruptions

The `find_disruptions` method returns an array of potential disruptions to a particular journey.

```ruby
journeys = client.get_journeys from: "fulham broadway underground station", to: 'edgware road underground station circle line'
journey = journeys.first
journeys.first.find_disruptions
#=> ["DISTRICT LINE TO KENSINGTON (OLYMPIA): The all day District Line service to Kensington (Olympia) has been withdrawn on Monday to Friday except for a very limited number of early morning and evening trains and during some events. Journey Planner will show when this service is operating.", "District Line: Minor delays between Edgware Road and Wimbledon only, due to an earlier signal failure at East Putney. GOOD SERVICE on the rest of the line.", "FULHAM BROADWAY, WIMBLEDON, SOUTHFIELDS, EARLS COURT AND WESTMINSTER STATIONS: A ramp is provided at these stations providing step-free access onto District line trains (as well as Circle line trains at Westminster). Please ask staff in the ticket hall for assistance."] 
```

This method also comes with the filter options, `filter: :realtime`, `filter: :information`. The former represents live updates regarding delays and closures, where the latter provides more general information. The method is called with the argument `filter: :all` by default.

```ruby
journey.find_disruptions filter: :realtime
#=> ["District Line: Minor delays between Edgware Road and Wimbledon only, due to an earlier signal failure at East Putney. GOOD SERVICE on the rest of the line."]
```

####Journey Methods

```ruby
journey.start_date_time #=> returns the time at which a journey begins, e.g. "2014-09-07T17:52:00"
journey.arrival_date_time #=> returns the time of arrival, e.g. "2014-09-07T18:10:00"

journey.duration #=> returns the duration of a journey in minutes, e.g. 18

journey.legs #=> returns an array of legs, into which journeys are divided.
```

####Leg Methods

As journeys are divided into legs, most of the more substiantial data is contained within these objects. The following is an overview of what I consider the more interesting methods:

```ruby
leg = journey.legs.first

leg.duration #=> returns the duration of a particular leg in minutes, e.g. 5

leg.departure_time #=> the time that leg begins
leg.arrival_time #=> the time that leg is completed

leg.distance #=> returns the distance of that leg in metres, e.g. 906.0

leg.disruptions #=> returns an array of disruptions to the leg, and potential obstacles for those who need assistance. e.g. leg.disruptions.first.description => "OXFORD CIRCUS STATION: A ramp is provided at this station providing step-free interchange between northbound Bakerloo and northbound Victoria line trains, and between southbound Bakerloo and southbound Victoria line trains. Please ask staff in the ticket hall for assistance."

leg.planned_works #=> returns an array of planned works for this section of the journey

leg.path.line_string #=> returns a JSON array of coordinates travelled through, e.g. "[[51.45151025215, -0.41971520833],[51.45144462064, -0.41951598516],[51.45227139887, -0.41881099496]]" 

leg.instruction #=> returns an object representing instructions for the leg itself.

```

#####Leg Instructions

```ruby

instruction = leg.instruction

instruction.summary #=> returns a plain instruction of what to do, e.g. "Victoria line to Oxford Circus"

instruction.detailed #=> gives more information about which train or bus to take (if the instructions pertain to walking, summary and detailed versions are identical), e.g. "Victoria line towards Walthamstow Central, or Seven Sisters"

instruction.steps #=> if the instructions describe public transportations, this returns an empty array. If they are walking instructions, this returns an array of steps.

steps = instruction.steps
step = steps.first

step.description #=> returns textual instruction, e.g. "Continue along Epworth Street for 17 metres (0 minutes, 15 seconds)."

step.turn_direction #=> e.g. "STRAIGHT"

step.distance #=> e.g. 17

step.latitude #=> e.g. -0.08704303829
step.longitude #=> e.g. 51.523251804

step.sky_direction #=> 27
```

### Integrating with Google Maps

Setting up a simple Sinatra app:

```ruby

require 'sinatra'
require 'sinatra/json'
require 'journey_planner'

get '/' do 
	erb :index
end

get '/maps' do 
	client = TFLJourneyPlanner::Client.new(app_id: ENV["TFL_ID"], app_key: ENV["TFL_KEY"])
	journeys = client.get_journeys from: "old street underground station", to: "oxford circus underground station"
	json journeys.first.map_path
end

```

Your HTML and Javascript (assuming JQuery, the Google Maps API, and GMapsJS have already been linked)

```html
<div id="map" style="height: 500px; width: 500px"></div>
```

```javascript
	$(document).ready(function(){

		$.get('/maps', function(coordinates){

			var map = new GMaps({
	  			div: '#map',
	  			lat: coordinates[0][0],
	  			lng: coordinates[0][1]

			});

			map.drawPolyline({
			  path: coordinates,
			  strokeColor: '#131540',
			  strokeOpacity: 0.6,
			  strokeWeight: 6
			});
		});

	});
```

On launching your app, you should find that GMaps has created a polyline from the TFL Journey Planner path coordinates.

![Image1](https://raw.githubusercontent.com/jpatel531/journey_planner_gem/master/screenshots/jp_gmaps_ex.jpg)

###Search Options

```ruby
client.get_journeys

from: #=> 	Origin of the journey (if in coordinate format then must be "longitude,latitude")

to: #=> Destination of the journey (if in coordinate format then must be "longitude,latitude")

via: #=> Travel through (if in coordinate format then must be "longitude,latidude")

national_search: #=> Does the journey cover stops outside London? eg. "nationalSearch=true". Set to false by default

date: #=> The date must be in yyyyMMdd format

time: #=> The time must be in HHmm format

time_is: #=> Does the time given relate to arrival or leaving time? Possible options: "departing" | "arriving". Set to Departing by default

journey_preference: #=> The journey preference eg possible options: "leastinterchange" | "leasttime" | "leastwalking"

mode: #=> The mode must be a comma separated list of modes. eg possible options: "public-bus,overground,train,tube,coach,dlr,cablecar,tram,river,walking,cycle"

accessibility_preference: #=> The accessibility preference must be a comma separated list eg. "noSolidStairs,noEscalators,noElevators,stepFreeToVehicle,stepFreeToPlatform"

from_name: #=> From name is the location name associated with a from coordinate

to_name: #=> To name is the label location associated with a to coordinate

via_name: #=> Via name is the location name associated with a via coordinate

max_transfer_minutes: #=> The max walking time in minutes for transfer eg. "120"

min_transfer_minutes: #=> The max walking time in minutes for journeys eg. "120"

walking_speed: #=> The walking speed. eg possible options: "slow" | "average" | "fast"

cycle_preference: #=> The cycle preference. eg possible options: "allTheWay" | "leaveAtStation" | "takeOnTransport" | "cycleHire"

adjustment: #=> Time adjustment command. eg possible options: "TripFirst" | "TripLast"

bike_proficiency: #=> A comma separated list of cycling proficiency levels. eg possible options: "easy,moderate,fast"

alternative_cycle: #=> Set to True to generate an additional journey consisting of cycling only, if possible. Default value is false. eg. alternative_cycle: true

alternative_walking: #=> Set to true to generate an additional journey consisting of walking only, if possible. Default value is false. eg. alternative_walking: true

apply_html_markup: #=> Flag to determine whether certain text (e.g. walking instructions) should be output with HTML tags or not.

```

#### Disambiguation

When entering to- and from- locations, specificity is the best option. For instance, searching for "Fulham Broadway Underground Station" or "Feltham Rail Station" will work, whereas "Fulham Broadway", "Feltham", "Fulham Broadway Station" or "Feltham Station" will not. However, TFL does provide some disambiguation options in their API for less obvious entries, which the gem prints to the console when an ambiguous search has been entered.

```ruby 
client.get_journeys from: "fulham broadway underground station", to: "edgware road underground station"

#=> Did you mean? 
#=> Edgware Road, Edgware Road (Circle Line) Underground Station
#=> false
```

##Objectives

* To learn about how to create a gem
* To learn about making HTTP requests with HTTParty
* To learn how to stub HTTP requests in your test suite with VCR and WebMock
* To explore the TFL Journey Planner API
* To learn how to use Travis CI


##Technologies

* Ruby
* RSpec
* VCR
* WebMock
* HTTParty
* Recursive OpenStruct
* TFL API
* Travis CI

##Usage Examples

###Last Train

[Last Train](http://github.com/jpatel531/last-train) is a simple app that allows you to search for late night trains and buses, and sends you an SMS with directions, either now or an hour before departure. This app combines the journey_planner gem with GMaps to show paths, and with Twilio to communicate instructions.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/journey_planner_gem/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
