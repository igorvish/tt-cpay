# README

## Задача

> Для нашего проекта неприемлем стандартный формат логов, необходимо привести все логи к другому формату... (см. TT-CPAY.md)

## Реализация

Задача практически полностью закрывается гемами <https://github.com/rocketjob/semantic_logger> или <https://github.com/shadabahmed/logstasher>.

Здесь она решается без их использования.

Чтобы обеспечить требуемую сигнатуру и форматирование, реализованы расширения `ApplicationLogging::Logging` и `ApplicationLogging::Formatting`. Эти расширения работают с любым логером, который реализует стандартный интерфейс руби-логера. Сохранена работа с тегами.

Чтобы привести стандартные логи рельс к такому же структурному формату, использован механизм ActiveSupport::Notifications и заменены стандартные сабскрайберы событий ActionController и ActiveJob.

Для того чтобы логировать события Grape и Sidekiq, для них добавлены middleware, которые генерируют события, так же логирующиеся в соответствующих сабскрайберах.

Для демонстрации работы сделано логирование в ELK (логи пишутся напрямую при помощи <https://github.com/dwbutler/logstash-logger>).

Основные файлы проекта:

```
.
├── Dockerfile
├── ...
├── app
│   ├── ...
│   ├── controllers
│   │   ├── api
│   │   │   └── v1
│   │   │       └── home_api.rb       # Вызов логера
│   │   ├── ...
│   │   └── home_controller.rb        # Вызов логера и отложенная задача
│   ├── ...
│   ├── jobs
│   │   ├── ...
│   │   └── sample_job.rb             # Тестовая задача вызывающая логер
│   ├── ...
├── config
│   ├── application.rb                # Загрузка railtie
│   ├── ...
│   ├── environments
│   │   ├── development.rb            # Инициализация логера
│   │   ├── ...
│   ├── initializers
│   │   ├── ...
│   │   ├── sidekiq.rb                # Установка логера и middleware
│   │   └── ...
│   ├── ...
├── ...
├── docker-compose.yml                # app, jobs, redis, logstash, elastic, kibana
├── lib
│   ├── application_logging
│   │   ├──
│   │   ├── formatting.rb             # Модуль с функционалом форматирования сообщения
│   │   ├── grape_middleware.rb       # Middleware для логирования grape-запросов
│   │   ├── logging.rb                # Модуль с методами логирования
│   │   ├── railtie.rb                # Railtie с отпиской стандартных и подпиской собственных сабскрайберов
│   │   ├── sidekiq_job_logger.rb     # "Middleware" для логирования событий обработки задач
│   │   └── subscribers               # Сабскрайберы соответствующих событий
│   │       ├── action_controller.rb    # ...
│   │       ├── active_job.rb           # ...
│   │       ├── grape_middleware.rb     # ...
│   │       └── sidekiq_job_logger.rb   # ...
│   ├── application_logging.rb        # Модуль-экстендер
│   ├── ...
├── ...
```

## Развертывание и интерфейсы

Проект развертывается через docker-compose:

```bash
# Так как Elastic требователен к памяти, может потребоваться дать VM >2ГБ.
# После старта всех сервисов (app, jobs, redis, logstash, elastic, kibana) необходимо еще немного времени на инициализацию ELK.
docker-compose up
```

После развертывания можно проверить работу. Логи будут идти в ELK <http://localhost:5601/> и дублироваться в STDOUT:

```bash
# При обращении вызывается логер и ставится отложенная задача. Так же логируются события ActionController.
# Rails.logger.info('Hello World from HomeController#index')
curl "http://localhost:3000/"

# ... Отрабатвает отложенная задача, в ней вызывается логер. Так же логируются события Sidekiq и ActiveJob.
# ... Rails.logger.info('New document created', entity_id: '...', email: '...')

# При обращении вызывается логер. Так же логируется событие обращения через Grape::Middleware.
# Rails.logger.info('Hello World from Grape action')
curl "http://localhost:3000/api/v1/home"

# Посмотреть логи в Кибане:
open http://localhost:5601/
```

-------------------------------------------------------------------------------

#### ELK debugging

```
curl "localhost:9200/_cat/health?v"
curl "localhost:9200/_cat/nodes?v"
curl "localhost:9200/_cat/indices?v"

curl "localhost:9200/logstash-*/apps/_count?pretty"
curl "localhost:9200/logstash-*/apps/_search?pretty"

curl -XDELETE 'http://localhost:9200/logstash-*/'
```
