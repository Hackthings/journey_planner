require_relative 'spec_helper'

describe TFLJourneyPlanner::Results, vcr: true do

	let(:client) {client = TFLJourneyPlanner::Client.new(app_id: ENV["TFL_ID"], app_key: ENV["TFL_KEY"])}
	let(:journeys) {journeys =  client.get_journeys(from: "tw14 9nt", to: "tw14 8ex")}
	

	it "must work" do 
		VCR.use_cassette "hello", record: :new_episodes do 
			expect(journeys[0].start_date_time).to be_a String
		end
	end


	it 'must process journeys into objects' do 
		VCR.use_cassette "hello", record: :none do 
			expect(journeys).to be_a Array
			expect(journeys[0]).to be_a TFLJourneyPlanner::Journey
		end
	end

	# it 'must calculate an average duration of the journeys found' do 
	# 	VCR.use_cassette "hello", record: :none do
	# 		expect(journeys)

	# 	end

	# end

end