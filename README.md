#Storage

##Описание

Простое key-value хранилище, реализованное с помощью tarantool

##Требования

Установленные [tarantool][] [tarantool]:https://tarantool.io + tarantool [http][] [http]:https://github.com/tarantool/http

##Запуск

`tarantool storage.lua`

##Конфигурация

Http-сервер будет запущен с настройками подключения, указанными в config.lua. По умолчанию localhost:8081.
Так же можно указать максимальное количество запросов в секунду, по умолчанию 10.

##Запросы

Сервер отвечает объектом, содержащим следующие поля:
 - string version - версия API
 - unixstamp time - время генерации ответа
 - boolean status - результат выполнение: true при успешном выполнение, false в случае ошибки. (Дублируется в заголовке x-api-status)
 - string data - сообщение о результате выполнения в случае успеха
 - string error - сообщение об ошибке
 - integer id - идентификатор записи в хранилище, по которому произведена попытка выполнения запроса

*Существующие ограничения*

Идентификатор записи id присваивается автоматически с помощью автоинкрементной последовательности, имеет тип integer.
Поле key должно быть уникальным.
Полу value представляет из себя ассоциативный массив значений произвольной структуры.


* __Вставка значения__

_Путь_: /kv
_Тело_: {key: string, value: object}.

`curl --location --request POST 'http://localhost:8081/kv' \
--header 'Content-Type: application/json' \
--data-raw '{
    "key": "person",
    "value": {"name":"bob","age":32}"
}'`


* __Получение значения__

_Путь_: /kv/:id
_Тело_: Игнорируется
_Результат_: содержимое кортежа в поле data

`curl --location --request GET 'http://localhost:8081/kv/1' \
--header 'Content-Type: application/json'`


* __Редактирование значения__

_Путь_: /kv/:id
_Тело_: {value: object}

`curl --location --request PUT 'http://localhost:8081/kv' \
--header 'Content-Type: application/json' \
--data-raw '{
    "value": {"name":"alice","age":33}"
}'`


* __Удаление значения__

_Путь_: /kv/:id
_Тело_: Игнорируется

`curl --location --request DELETE 'http://localhost:8081/kv/1' \
--header 'Content-Type: application/json'`
