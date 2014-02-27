# require "spec_helper"

# # module Api
# #   module V1

# describe 'UsersController', :version => :v1 do


#   describe "GET" do

#     let!(:application) { FactoryGirl.create :doorkeeper_application }
#     let!(:user)        { FactoryGirl.create :user }
#     let!(:token)       { FactoryGirl.create :doorkeeper_access_token, 
#                                               application: application, 
#                                               resource_owner_id: user.id }

#     it "should GET a User " do
#       # debugger
#       # Rails.logger.debug 'hi'
#       # api_request :get, 'api/users/1'  # can access self.class.metadata[:version] in here

#       # debugger
#       # let a FactoryGirl Doorkeeper::Application
#       # api_get '/api/users/1', token
#       debugger
#       api_get '/api/users/1', token

#       expect(response.code).to eq('200')
#       # debugger
#       # debugger

#       # api_request :get, 
#     end

#   end

# end

#   # let(:exchanger) { FactoryGirl.create(:exchanger_with_api_keys)}

#   # it "should be creatable by an exchanger with an api key" do
#   #   api_request :post, 'api/v1/identities', exchanger.api_keys.first
#   #   last_response.status.should eql(200)

#   #   expected_response = {
#   #     :identity => Identity.last.value
#   #   }.to_json

#   #   last_response.body.should eql(expected_response)
#   # end

#   # it "should not be creatable by an exchanger with a bad api key" do
#   #   api_request :post, 'api/v1/identities', 'bad_api_key'
#   #   last_response.status.should eql(401)
#   # end
  
#   # it "should not be creatable without api key access" do
#   #   post 'api/v1/identities'
#   #   last_response.status.should eql(401)
#   # end


#   # let(:user) {  create_user! }
#   # let(:token) { user.authentication_token }
  
#   # before do
#   #   @project = Factory(:project)
#   #   user.permissions.create!(:action => "view", :thing => @project)
#   # end

#   # context "projects viewable by this user" do
#   #   before do
#   #     Factory(:project, :name => "Access denied.")
#   #   end

#   #   let(:url) { "/api/v1/projects" }
#   #   it "JSON" do
#   #     get "#{url}.json", :token => token

#   #     projects_json = Project.for(user).all.to_json
#   #     last_response.body.should eql(projects_json)
#   #     last_response.status.should eql(200)

#   #     projects = JSON.parse(last_response.body)

#   #     projects.any? do |p|
#   #       p["project"]["name"] == "Ticketee"
#   #     end.should be_true
      
#   #     projects.any? do |p|
#   #       p["project"]["name"] == "Access Denied"
#   #     end.should be_false
#   #   end
    
#   #   it "XML" do
#   #     get "#{url}.xml", :token => token
#   #     last_response.body.should eql(Project.readable_by(user).to_xml)
#   #     projects = Nokogiri::XML(last_response.body)
#   #     projects.css("project name").text.should eql("Ticketee")
#   #   end
#   # end
  
#   # context "creating a project" do
#   #   before do
#   #     user.admin = true
#   #     user.save
#   #   end

#   #   let(:url) { "/api/v1/projects" }

#   #   it "sucessful JSON" do
#   #     post "#{url}.json", :token => token,
#   #                         :project => {
#   #                           :name => "Inspector"
#   #                         }

#   #     project = Project.find_by_name("Inspector")
#   #     route = "/api/v1/projects/#{project.id}"

#   #     last_response.status.should eql(201)
#   #     last_response.headers["Location"].should eql(route)
      
#   #     last_response.body.should eql(project.to_json)
#   #   end
    
#   #   it "unsuccessful JSON" do
#   #     post "#{url}.json", :token => token,
#   #                         :project => {}
#   #     last_response.status.should eql(422)
#   #     errors = {"name" => ["can't be blank"]}.to_json
#   #     last_response.body.should eql(errors)
#   #   end
#   # end
  
#   # context "show" do
#   #   let(:url) { "/api/v1/projects/#{@project.id}"}

#   #   before do
#   #     Factory(:ticket, :project => @project)
#   #   end

#   #   it "JSON" do
#   #     get "#{url}.json", :token => token
#   #     project = @project.to_json(:methods => "last_ticket")
#   #     last_response.body.should eql(project)
#   #     last_response.status.should eql(200)

#   #     project_response = JSON.parse(last_response.body)["project"]

#   #     ticket_title = project_response["last_ticket"]["ticket"]["title"]
#   #     ticket_title.should_not be_blank
#   #   end
#   # end
  
#   # context "updating a project" do
#   #   before do
#   #     user.admin = true
#   #     user.save
#   #   end

#   #   let(:url) { "/api/v1/projects/#{@project.id}" }
#   #   it "successful JSON" do
#   #     @project.name.should eql("Ticketee")
#   #     put "#{url}.json", :token => token,
#   #                         :project => { 
#   #                           :name => "Not Ticketee"
#   #                         }
#   #     last_response.status.should eql(200)

#   #     @project.reload
#   #     @project.name.should eql("Not Ticketee")
#   #     last_response.body.should eql("{}")
#   #   end
    
#   #   it "unsuccessful JSON" do
#   #     @project.name.should eql("Ticketee")
#   #     put "#{url}.json", :token => token,
#   #                         :project => { 
#   #                           :name => ""
#   #                         }
#   #     last_response.status.should eql(422)

#   #     @project.reload
#   #     @project.name.should eql("Ticketee")
#   #     errors = { :name => ["can't be blank"]}
#   #     last_response.body.should eql(errors.to_json)
#   #   end
#   # end
  
#   # context "deleting a project" do
#   #   before do
#   #     user.admin = true
#   #     user.save
#   #   end

#   #   let(:url) { "/api/v1/projects/#{@project.id}" }
#   #   it "JSON" do
#   #     delete "#{url}.json", :token => token
#   #     last_response.status.should eql(200)
#   #   end
#   # end
# # end

# # end
# # end