module ApplicationLogging
  module Logging

    # 
    # Переопределяем методы, чтобы сделать требуемую в задаче сигнатуру:
    #   `.severity(msg, data)`
    #   `.severity(msg)`
    #   `.severity(progname) { msg_and_data }`
    #   `.severity { msg_and_data }`
    # вместо стандартной:
    #   `.severity(msg)`
    #   `.severity(progname) { msg }`
    #   `.severity { msg }`
    # (хотя по логике msg это и есть data, странно их отделять)
    # 
    # Пример:
    #   ```
    #   Rails.logger.info('New document created', { 
    #     entity_id: '...', email: '...', ...
    #   })
    #   
    #   Rails.logger.info do 
    #     ['New document created', { entity_id: '...', email: '...', ... }, caller[0]]
    #   end
    #   ```
    #
    Logger::Severity.constants.each do |severity|
      class_eval(<<-EOT, __FILE__, __LINE__ + 1)
        def #{severity.downcase}(msg_or_progname = nil, msg_payload = {}, &block)
          # Логика add() такая, что если блока нет, то 3-й аргумент
          # становится сообщением, а если блок есть, то 3-й аргумент
          # это имя программы.
          # Нам же, в случае если блока нет, нужно слить строку и payload
          # в одно сообщение.
          if !block_given?
            msg_or_progname = msg_or_progname, msg_payload, caller[0]
          end

          add(Logger::#{severity}, nil, msg_or_progname, &block)
        end
      EOT
    end

    def progname=(name)
      super
      # см. объяснение в Formatting
      formatter.progname_memo = progname if formatter.respond_to?(:progname_memo)
    end

    #
    # "Углубленное" клонирование - клонируем форматтер.
    # (Если мы клонируем логгер, то скорее всего хотим как-то изменить его 
    # состояние, и скорее всего не захотим затронуть форматер оригинала)
    # (NB: хотя это м.б. неожиданно для вызывающего контекста)
    #
    def initialize_clone(orig)
      super
      self.formatter = orig.formatter.clone
    end

  end
end
