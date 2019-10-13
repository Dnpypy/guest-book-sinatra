
# rus encoding
if (Gem.win_platform?)
  Encoding.default_external = Encoding.find(Encoding.locale_charmap)
  Encoding.default_internal = __ENCODING__

  [STDIN, STDOUT].each do |io|
    io.set_encoding(Encoding.default_external, Encoding.default_internal)
  end
end

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Sorry, you need to be logged in to visit ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
  erb 'Can you handle a <a href="/secure/place">secret</a>?'
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end


get "/about" do
  erb "OK"
end

get "/something" do
  erb "OK"
end

get "/contacts" do
  erb :contacts
end

post "/contacts" do

    @login   = params[:login]
    @mail    = params[:mail]
    @message = params[:message]

    @username_limit = 25;
    @email_limit    = 35;
    @message_limit  = 200;

    if  ((@login.length   > 0) && (@login.length   <= @username_limit)) &&
        ((@mail.length    > 0) && (@mail.length    <= @email_limit))    &&
        ((@message.length > 0) && (@message.length <= @message_limit))  

        File.open("./public/users.txt", "a") do |file|
            file.puts @login
            file.puts @mail
            file.puts @message
        end

        @alert_success = "Заявка оставлена!"
    
    else 
        
        @alert_message =  "Ошибка!!!<br>Не все данные введенны, либо в одном из полей формы слишком символов."
    
    end

    erb :contacts
end

# end

 # # проверка на пустую строку
  # if @login == "" # ||   
  #   @alert_message = "<p class='alert alert-danger' role='alert'>Пустая строка!!!</p>"
  #   # @check_mail = 
  #   erb :admin
  # elsif @pass == ""
  #   @alert_message_2 = "<p class='alert alert-danger' role='alert'>Пустая строка!!!</p>"
  #   erb :admin
  
  # # проверка на превышение лимита букв
  # elsif @login.length >= @username_limit 
  #   @alert_message_3 = "<p class='alert alert-danger' role='alert'>Превышен лимит букв!!!</p>"
  #   erb :admin
  # elsif @pass.length >= @pass_limit
  #   @alert_message_4 = "<p class='alert alert-danger' role='alert'>Превышен лимит букв!!!</p>"
  #   erb :admin
  # else 
  #   @inner = "<p class='alert alert-success' role='alert'>Вы вошли!!!</p>"
  # end


  # redirect to "/contacts"
# end

get "/admin" do
  erb :admin
end

post "/admin" do
  erb :admin_panel
end



