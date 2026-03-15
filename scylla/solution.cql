-- Решение заданий по Scylla/Cassandra
CREATE KEYSPACE user_posts_ks
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE user_posts_ks;

-- 1 Задание
CREATE TABLE posts_by_user_id (
    user_id  INT,
    username TEXT,
    post_id INT,
    content    TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (user_id, created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);

SELECT post_id, content, created_at
FROM posts_by_user_id
WHERE user_id = 123;

-- 2 Задание
-- Для этого запроса просто добавил username в первую таблицу, можно не создавать новую
SELECT post_id, content, created_at, username
FROM posts_by_user_id
WHERE user_id = 123
LIMIT 1;

-- 3 Задание
-- Для этого запроса тоже подходит первая таблица
SELECT post_id, content, created_at
FROM posts_by_user_id
WHERE user_id = 123
AND created_at >= '2010-10-10';

-- 4 Задание
-- В этом задании я уже создал новую таблицу так как первая не подходит, нужен другой ключ партиции
-- И еще я добавил post_id в primary key так как возможно что будут созданы два поста одновременно
-- с одной темой разными пользователями
CREATE TABLE posts_by_topic_and_date
(
    topic_id INT,
    created_at TIMESTAMP,
    post_id INT,
    user_id INT,
    username TEXT,
    PRIMARY KEY (topic_id, created_at, post_id)
) WITH CLUSTERING ORDER BY (created_at DESC);

SELECT user_id, username, post_id, created_at
FROM posts_by_topic_and_date
WHERE topic_id = 1
AND created_at >= '2010-10-10' AND created_at < '2010-10-11';
