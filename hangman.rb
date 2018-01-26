require 'sinatra'
require 'sinatra/reloader' if development?

enable :sessions

def find_word
  dictionary = File.open("5desk.txt", "r")
  contents = dictionary.read
  dictionary.close
  word = ""

  while word.length < 4 || word.length > 12 do
    #start and end to find whole word
    random_index = rand(contents.length-2)+2
    start_index = nil
    end_index = nil
    word = ""
    while start_index == nil || end_index == nil do
      if start_index == nil
        if contents[random_index] != "\n"
          random_index -= 1
        else
          start_index = random_index + 1
        end
      else
        if contents[random_index] != "\r"
          random_index += 1
        else
          end_index = random_index - 1
        end
      end
    end
    word = contents[start_index..end_index]
  end

  word = word.upcase
  puts word

  session[:letters_guessed] = ""
  word.length.times do
    session[:letters_guessed]  += "_ "
  end
  word
end

get '/reset' do
  redirect to("/")
end

get '/' do
  session[:word] = find_word
  session[:player_guesses] = []
  session[:incorrect_letters] = []
  session[:incorrect_guesses_left] = 6
  session[:winner] = false
  redirect to('/play')
end

get '/play' do
  letter = params["letter"].upcase if /[a-zA-z]/.match(params["letter"])
  if letter && (!session[:player_guesses].include? letter)
    correct_guesses = 0
    session[:player_guesses].push(letter)
    unless session[:word].include? letter
      session[:incorrect_guesses_left] -= 1
      session[:incorrect_letters].push(letter)
    end

    session[:letters_guessed] = ""
    session[:word].split("").each do |l|
      if session[:player_guesses].include? l
        correct_guesses += 1
        session[:letters_guessed] += l + " "
      else
        session[:letters_guessed] += "_ "
      end
    end
  end

  all_letters_guessed = ""
  session[:incorrect_letters].each do |l|
    all_letters_guessed += l
    all_letters_guessed += ", " unless session[:player_guesses][-1] == l
  end

  image = 7 - session[:incorrect_guesses_left]
  if session[:incorrect_guesses_left] < 0
    all_letters_guessed = "You lose!"
    image = 7
    session[:winner] = false
  elsif correct_guesses == session[:word].length
    all_letters_guessed = "You win!"
    session[:winner] = true
  end
  erb :index, :locals => {:letters_guessed => session[:letters_guessed], :all_letters_guessed => all_letters_guessed, :incorrect_guesses_left => image, :winner => session[:winner]}
end
