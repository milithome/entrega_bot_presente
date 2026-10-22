require "#{File.dirname(__FILE__)}/../lib/routing"
require "#{File.dirname(__FILE__)}/../lib/version"
require "#{File.dirname(__FILE__)}/tv/series"

class Routes
  include Routing

  on_message '/start' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{message.from.first_name}")
  end

  on_message_pattern %r{/say_hi (?<name>.*)} do |bot, message, args|
    bot.api.send_message(chat_id: message.chat.id, text: "Hola, #{args['name']}")
  end

  on_message '/stop' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "Chau, #{message.from.username}")
  end

  on_message '/time' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: "La hora es, #{Time.now}")
  end

  on_message '/tv' do |bot, message|
    kb = [Tv::Series.all.map do |tv_serie|
      Telegram::Bot::Types::InlineKeyboardButton.new(text: tv_serie.name, callback_data: tv_serie.id.to_s)
    end]
    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)

    bot.api.send_message(chat_id: message.chat.id, text: 'Quien se queda con el trono?', reply_markup: markup)
  end

  on_message '/busqueda_centro' do |bot, message|
    kb = [[
      Telegram::Bot::Types::KeyboardButton.new(text: 'Compartime tu ubicacion', request_location: true)
    ]]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    bot.api.send_message(chat_id: message.chat.id, text: 'Busqueda por ubicacion', reply_markup: markup)
  end

  on_message_pattern %r{/pokemon (?<pokemon_name>.*)} do |bot, message, args|
    pokemon_name = args['pokemon_name'].strip.downcase
    pokemon_response = Faraday.get("https://pokeapi.co/api/v2/pokemon/#{pokemon_name}")

    if pokemon_response.status == 200
      pokemon_json = JSON.parse(pokemon_response.body)
      pokemon_text = "Pokemon: #{pokemon_json['name']} - Types: #{pokemon_json['types'].map { |type| type['type']['name'] }.join(', ')}"
    else
      pokemon_text = "No encontré ningún Pokémon llamado '#{pokemon_name}'"
    end

    puts "Pokemon text: #{pokemon_text}"
    bot.api.send_message(chat_id: message.chat.id, text: pokemon_text)
  end

  on_message_pattern %r{/pokemon_foto (?<pokemon_name>.*)} do |bot, message, args|
    pokemon_name = args['pokemon_name'].strip.downcase
    pokemon_response = Faraday.get("https://pokeapi.co/api/v2/pokemon/#{pokemon_name}")

    if pokemon_response.status == 200
      pokemon_json = JSON.parse(pokemon_response.body)
      caption = pokemon_json['name'].capitalize.to_s

      bot.api.send_photo(
        chat_id: message.chat.id,
        photo: pokemon_json['sprites']['front_default'],
        caption:
      )
    else
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "No encontré ningún Pokémon llamado '#{pokemon_name}'"
      )
    end
  end

  on_location_response do |bot, message|
    response = "Ubicacion es Lat:#{message.location.latitude} - Long:#{message.location.longitude}"
    puts response
    bot.api.send_message(chat_id: message.chat.id, text: response)
  end

  on_response_to 'Quien se queda con el trono?' do |bot, message|
    response = Tv::Series.handle_response message.data
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
  end

  on_message '/version' do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: Version.current)
  end

  default do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: 'Uh? No te entiendo! Me repetis la pregunta?')
  end
end
