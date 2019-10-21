
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
require "pry"

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
    @user_ids = [1]
    erb :login_form, layout: :message
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
    @user_ids = [1]
    erb "OK", layout: :message
end

get "/something" do
    erb "OK"
end

get "/contacts" do
    # переменной присваиваем метод результат метода read_posts_from_file
    @message_board = read_posts_from_file
    erb :contacts
end

post "/contacts" do

    @login   = params[:login]
    @mail    = params[:mail]
    @message = params[:message]

    @username_limit = 25;
    @email_limit    = 35;
    @message_limit  = 300;

    # 1. Сначала проходим на пустоту форму, 
    # 2. Далее проверям почту регуляркой, 
    # 3. Далее на избыток символов
    
    
    # хэш с ошибками, сюда можно добавить любой ключ с ошибкой
    error_hash =     {    
                     :login   => "Введите имя", 
                      :mail   => "Введите почту @", 
                     :message => "Введите сообщение"
                    }
    
    error_hash.each do |key, value|
            
        # проверям все параметры на пустые строки
        if params[key] == ""
            
            @error = error_hash[key]
            erb :contacts
        end
    end


    # проверяем поля на избыток символов если много то ошибка
    if  ((@login.length   > 0) && (@login.length   <= @username_limit)) &&
        ((@mail.length    > 0) && (@mail.length    <= @email_limit))    &&
        ((@message.length > 0) && (@message.length <= @message_limit))  

        # if params[key].length > 0 && params[key].length <= 

        # регулярное выражение
        email_regexp = /^[a-z\d_+.\-]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+$/i

        # проверяем email по регулярке
        if @mail.match(email_regexp)

           # если все ок, то записываем в файл
           File.open("./public/users.txt", "a") do |file|
            file.print   "user: #{@login} "
            file.print   "mail: #{@mail} "
            file.puts    "time: #{Time.now} "
            file.puts "message: #{@message}"
           end

            # Т.е после каждой абзаца когда мы закоончили метод gsub,
            # меняет все \r\n на тэг отступ "<br />"
            @message.gsub!("\r\n", "<br />")

           # Записываем логин и сообщение в метод post_to_file
           post_to_file @login, @message
           @alert_success = "<div class='alert alert-success'>Сообщение записано!</div>"
           
           # для обновления страницы и обновления постов
           redirect "/contacts"
        
        else
          
            @mail_fail = "<div class='alert alert-danger'>Это не email!!</div>"
            erb :contacts

        end  # <<< if @mail.match

    else 
        
        @alert_message =  "<div class='alert alert-danger'>Ошибка!!!<br>В одном из полей формы слишком много символов.</div>"
        erb :contacts

    end # <<< if many character

       
end # <<< "/contacts" do

# в методе post_to_file мы записываем в файл время, автора и контент, что пишем в абзаце.
def post_to_file author, content
  File.open('./public/posts.txt', 'a') do |file|
    temp_time = Time.new
    file.print "#{temp_time.day}.#{temp_time.month}.#{temp_time.year} #{temp_time.hour}:#{temp_time.min};"
    file.print "#{author};"
    file.puts "#{content}\n"
  end
end


# loop do <<< try loop close

# Что делает метод, проверяет наличие файла, читает его и записывает в вывод html
def read_posts_from_file
  
  @board = ""    # создаем строку @board
  @iterator = 0  # создаем строку @iterator

  # Оператор unless проверяет отрицание, пока 'posts.txt' не пустой?(отрицание)
  unless File.readlines('./public/posts.txt').empty?    # метод .readlines весь файл читаем
    File.readlines('./public/posts.txt').each do |line| # каждую строку (line проходим)
      line.split(';').each do |element| # .split Делит строку str на подстроки по разделителю ;
        #  ';' - разделитель в файле
        case @iterator
          when 0  # когда 0
            @board << "Date: "
          when 1
            @board << "Author: "
          when 2
            @board << "Content: "
          when 3
            @board << "<hr> Date: "
        end
        
        # в конце записывается счетчик element
        @board << "#{element}<br />"  
        
        if @iterator <= 2 
          @iterator += 1
        else
          @iterator = 1
        end

      end
    end
  end
  @board # в конце передает что было записано
end
# end  <<< try loop close

get "/admin" do
  erb :admin
end

post "/admin" do

    @login = params[:login]    
    @pass  = params[:pass]   

    # binding.pry
    @login_limit   = 25
    @pass_limit    = 35


    if  ((@login.length   > 0) && (@login.length   <= @login_limit)) &&
        ((@pass.length    > 0) && (@pass.length    <= @pass_limit))  && 
    
        @check_numbers = "success check_numbers"  
    
    else 
    
        @alert_admin = "Неправильный логин или пароль!!!"
    
    end

    if @login == "1" && @pass == "1"
            
            File.open("./public/users.txt", "r") do |line|
                @logfile = line.readlines
            end

            @user_ids = [1,2]

            erb :admin_panel, layout: :message
    else
          
        erb :admin
        
    end

end


get "/admin_panel" do
    erb :admin_panel
end




