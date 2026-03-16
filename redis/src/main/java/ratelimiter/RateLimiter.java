package ratelimiter;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.time.Instant;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;

public class RateLimiter {

  private final Jedis redis;
  private final String label;
  private final long maxRequestCount;
  private final long timeWindowSeconds;

  public RateLimiter(Jedis redis, String label, long maxRequestCount, long timeWindowSeconds) {
    this.redis = redis;
    this.label = label;
    this.maxRequestCount = maxRequestCount;
    this.timeWindowSeconds = timeWindowSeconds;
  }

  // Я решил реализовать алгоритм со скользящим окном на zset (отсортированный сет).
  // Даже в доке редиса про zset написано что один из юз кейсов это rate limiter,
  // и в целом мне этот алгоритм понравился.
  // Тесты проверил, прошло все тесты.
  public boolean pass() {
    // Берем время текущего запроса и считаем время начала окна
    long now = System.currentTimeMillis();
    long windowStart = now - timeWindowSeconds * 1000;

    // Удаляем записи которые не попадают в окно
    redis.zremrangeByScore(label, 0, windowStart);

    // Получаем кол-во запросов
    long requests = redis.zcard(label);

    // Если кол-во запросов больше допустимого, то возвращаем false,
    // таким образом у нас не будет тратиться много памяти на хранение запросов.
    // Например представим ситуацию что окно 3 сек, нас дудосят со скоростью 10000 запросов/сек,
    // и допустимое кол-во запросов - 100. Максимум будет хранится по этому label 100 запросов, какая бы ни была атака,
    // так как проверка идет до zadd.
    if (requests >= maxRequestCount) {
      return false;
    }

    // Иначе добавляем текущий запрос (название будет request{какое то рандомное число}, score - время)
    // рандомное число нужно чтобы запросы не перезаписывали друг друга.
    redis.zadd(label, now, "request" + Math.random());

    // И теперь возвращаем true так как мы разрешили этот запрос
    return true;
  }

  public static void main(String[] args) {
    JedisPool pool = new JedisPool("localhost", 6379);

    try (Jedis redis = pool.getResource()) {
      RateLimiter rateLimiter = new RateLimiter(redis, "pr_rate", 1, 1);

      BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
      long prev = Instant.now().toEpochMilli();
      long now;

      while (true) {
        try {
          String s = br.readLine();
          if (s == null || s.equals("q")) {
            return;
          }
          boolean passed = rateLimiter.pass();

          now = Instant.now().toEpochMilli();
          if (passed) {
            System.out.printf("%d ms: %s", now - prev, "passed");
            prev = now;
          } else {
            System.out.printf("%d ms: %s", now - prev, "limited");
          }
        } catch (IOException e) {
          e.printStackTrace();
        }
      }

    }
  }
}
