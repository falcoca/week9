# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"  
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"                                                                      #
require "twilio-ruby"                                                                 #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

get "/" do
    puts "params: #{params}"

    pp events_table.all.to_a
    @events = events_table.all.to_a
    view "events"
end

get "/events/:id" do
    puts "params: #{params}"

    @event = events_table.where(id: params[:id]).to_a[0]
    pp @event
    @rsvps = rsvps_table.where(event_id: @event[:id]).to_a
    @going_count = rsvps_table.where(event_id: @event[:id], going: true).count
    view "event"
end

get "/events/:id/rsvps/new" do
    puts "params: #{params}"

    @event = events_table.where(id: params[:id]).to_a[0]
    view "new_rsvp"
end

get "/events/:id/rsvps/create" do
    puts "params: #{params}"

    # Step 1: first find the event that rsvp'ing for
    @event = events_table.where(id: params[:id]).to_a[0]
    # Step 2: insert a row in RSVPs table with RSVP form data
    rsvps_table.insert(
        event_id: @event[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        going: params["going"]    
    )
    view "create_rsvp"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts "params: #{params}"

# Step 2: insert a row in RSVPs table with RSVP form data
    users_table.insert(
        name: params["name"],
        email: params["email"],
        password: params["password"],
    )
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    puts "params: #{params}"
 
    #Step 1: is there a user with the params["email"] 
    @user = users_table.where(email: params["email"]).to_a[0]
    if @user
        #step 2: if there is, does the password match?   
        if @user[:password] == params["password"]
            # know a user is logged in
            session["user_id"] = @user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else view "create_login_failed"
    end
end

get "/logout" do
    view "logout"
end
