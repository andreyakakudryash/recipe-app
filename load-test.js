import http from 'k6/http';
import { check, sleep } from 'k6';

// Настройки теста
export const options = {
    stages: [
        { duration: '30s', target: 100 },  // разгон до 10 пользователей
        { duration: '1m',  target: 500 },  // держим 50 пользователей
        { duration: '30s', target: 1000 }, // пик 100 пользователей
        { duration: '30s', target: 0 },   // спад
    ],
    thresholds: {
        http_req_duration: ['p(95)<1000'], // 95% запросов быстрее 500ms
        http_req_failed:   ['rate<0.05'], // меньше 1% ошибок
    },
};

const BASE_URL = 'http://127.0.0.1:63869/api/v1';

export default function () {
    // Тест 1 — список рецептов
    const list = http.get(`${BASE_URL}/recipes`);
    check(list, {
        'список — статус 200':       (r) => r.status === 200,
        'список — быстрее 200ms':    (r) => r.timings.duration < 200,
    });

    sleep(0.5);

    // Тест 2 — поиск
    const search = http.get(`${BASE_URL}/recipes/search?q=борщ`);
    check(search, {
        'поиск — статус 200':        (r) => r.status === 200,
        'поиск — быстрее 300ms':     (r) => r.timings.duration < 300,
    });

    sleep(0.5);

    // Тест 3 — получить рецепт по ID
    const id = Math.floor(Math.random() * 1000) + 1;
    const detail = http.get(`${BASE_URL}/recipes/${id}`);
    check(detail, {
        'детали — статус 200 или 404': (r) => r.status === 200 || r.status === 404,
        'детали — быстрее 200ms':      (r) => r.timings.duration < 200,
    });

    sleep(0.5);

    // Тест 4 — создать рецепт
    const cuisineID = Math.floor(Math.random() * 10) + 1;
    const payload = JSON.stringify({
        title:       `Тестовый рецепт ${Date.now()}`,
        description: 'Нагрузочный тест',
        cuisine_id:  cuisineID,
        cook_time:   30,
        servings:    4,
        difficulty:  2,
    });
    const create = http.post(`${BASE_URL}/recipes`, payload, {
        headers: { 'Content-Type': 'application/json' },
    });
    check(create, {
        'создание — статус 201':     (r) => r.status === 201,
        'создание — быстрее 500ms':  (r) => r.timings.duration < 500,
    });

    sleep(1);
}