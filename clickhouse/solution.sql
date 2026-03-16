-- Решение заданий по ClickHouse

CREATE DATABASE IF NOT EXISTS server_db;

-- 1. Создание таблицы
USE server_db;

-- Сделал ORDER BY по endpoint и timestamp отталкиваясь от запросов в заданиях
CREATE TABLE IF NOT EXISTS server_logs
(
    user_id UInt32,
    endpoint String,
    response_time_ms UInt32,
    status_code UInt16,
    timestamp DateTime
)
ENGINE = MergeTree()
ORDER BY (timestamp, endpoint);

-- 2. Загрузка данных из CSV
-- Подсказка: можно использовать clickhouse-client с параметром --query
-- Пример команды (выполняется в терминале):
-- cat server_logs.csv | clickhouse-client --query="INSERT INTO server_logs FORMAT CSVWithNames"


-- 3. Запрос: Топ-5 самых медленных endpoint'ов (по среднему времени ответа)
SELECT
    endpoint,
    avg(response_time_ms) as avg_response_time_ms
FROM server_logs
GROUP BY (endpoint)
ORDER BY avg_response_time_ms DESC
LIMIT 5;


-- 4. Запрос: Количество запросов по часам за весь период в логах
SELECT
    formatDateTime(timestamp, '%Y-%m-%d %H:00:00') as hour,
    count() as request_count
FROM server_logs
GROUP BY hour;

-- 5. Запрос: Процент ошибок (status_code >= 400) для каждого endpoint'а
SELECT
    endpoint,
    round(countIf(status_code >= 400) * 100 / count(), 2) as error_percent
FROM server_logs
GROUP BY endpoint;
