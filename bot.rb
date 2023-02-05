require 'telegram/bot'
require 'pry'

TG_TOKEN = '..'

Telegram::Bot::Client.run(TG_TOKEN) do |bot|
  bot.listen do |message|
    case message.text
    when '/chatid'
      bot.api.send_message(chat_id: message.chat.id, text: "Hey, my chat id is #{message.chat.id}")
    end
  end
end
