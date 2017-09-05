module ApplicationLogging
  #
  # Модуль для расширения форматера, который пере/определяет метод call,
  # отвечающий за форматирование итогового сообщения в нужной нам форме.
  #
  # Метод подразумевает, что скорее всего будет доступен метод `current_tags`.
  #
  # Это сделано в виде модуля, а не класса, т.к. при таком подходе мы можем
  # взять любой логер с его форматером и либо расширить их при помощи
  # `ActiveSupport::TaggedLogging` и `ActiveSupport::TaggedLogging::Formatter`,
  # либо не делать этого, либо использовать родной функционал, как например у
  # LogstashLogger, которой тоже умеет тегировать.
  #
  # Пример:
  #
  #   ```
  #   # Создаем форматер, который умеет тегировать
  #   logger = SomeLogger.new(
  #     formatter: Class.new.new
  #       .extend(ActiveSupport::TaggedLogging::Formatter)
  #       .extend(ApplicationLogging::Formatting)
  #   ).extend(ActiveSupport::TaggedLogging)
  #
  #   # Берем форматер, который уже умеет тегировать
  #   logger = LogStashLogger.new(
  #     uri:        ENV['LOGSTASH_URI'],
  #     formatter:  LogStashLogger::Formatter::Base.new.extend(ApplicationLogging::Formatting)
  #   )
  #   ```
  #
  module Formatting #< ::Logger::Formatter

    # This method is invoked when a log event occurs
    #
    # {
    #   "level": "info",
    #   "ts": 1496861200.8043,
    #   "caller": "controller/api/v1/document.rb:101",
    #   "msg": "New document created",
    #   "app": "Documentator",
    #   "env": "production",
    #   "payload": {
    #     "entity_id": "123e4567-e89b-12d3-a456-426655440000",
    #     "email": "example@gmail.com",
    #     "first_name": "User",
    #     "last_name": "Useroff"
    #   }
    # }
    def call(severity, timestamp, progname, msg)
      event = {
        level:    severity,
        ts:       timestamp.to_f,
        app:      progname || progname_memo,
        env:      Rails.env,
        tags:     [],
      }

      # Теги могут быть удобны, чтобы собрать инфу во время запроса (config.log_tags).
      # Если там объект - мы вытаскиваем его на верхний уровень.
      current_tags.each do |item|
        item.is_a?(Hash) ? event.merge!(item) : event[:tags] << item
      end

      case msg
      when String # e.g: 'New document created'
        event[:msg] = msg
      when Hash   # e.g: { key: 'data', ... }
        event = msg.merge(event)
      when Array  # [msg_string, payload_hash, caller_data]
                  # or
                  # [data_hash, payload_hash, caller_data]
        msg[0].is_a?(Hash) ? event = msg[0].merge(event) : event[:msg] = msg[0]
        event[:payload] = msg[1] if msg[1]
        event[:caller] = msg[2] if msg[2]
      end

      event = @customize_event.call(event) if @customize_event

      event.to_json + "\n\n"
    end

    #
    # Workaround, чтобы исправить эктивсуппортовскую/рельсовую
    # недоработку.
    # При "броадкасте" в STDOUT (в окружении development) рельсы при
    # копировании форматера забывают скопировать `progname` -
    # https://github.com/rails/rails/blob/v5.1.2/railties/lib/rails/commands/server/server_command.rb#L82
    #
    # Поэтому при необходимости мы будем сохранять его в этой переменной.
    #
    def progname_memo; @progname_memo; end
    def progname_memo=(progname); @progname_memo = progname; end

    #
    # Финишер-хук вызываемый форматером после формирования сообщения.
    # Это должен быть объект отвечающий на `call(event)`.
    #
    def customize_event; @customize_event; end
    def customize_event=(callable); @customize_event = callable; end

  end
end
