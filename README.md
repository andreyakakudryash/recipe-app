# RecipeApp — Мобильное приложение рецептов

Мобильное приложение для управления рецептами с высокой нагрузкой (1M+ записей в БД), развёрнутое в Kubernetes.

## Демонстрация работы

[Видео демонстрации приложения]()

## Стек технологий

- **Backend:** Go (Fiber) — REST API
- **Database:** PostgreSQL 16 (партиционирование по кухням, полнотекстовый поиск, GIN-индексы)
- **Mobile:** iOS (SwiftUI) — нативный клиент
- **Контейнеризация:** Docker, Docker Compose
- **Оркестрация:** Kubernetes (Yandex Cloud Managed K8s)
- **CI/CD:** Yandex Container Registry
- **Нагрузочное тестирование:** k6

## Архитектура

```
Пользователь (iOS)
       ↓
Load Balancer (публичный IP)
       ↓
Kubernetes Cluster (Yandex Cloud)
  ├── recipe-backend (2 реплики, Go API)
  └── PostgreSQL 16 (StatefulSet, persistent storage)
```

## Структура проекта

```
recipe_app/
├── backend/              # Go API сервер
│   ├── cmd/api/          # Точка входа (main.go)
│   ├── internal/
│   │   ├── config/       # Конфигурация из env
│   │   ├── db/           # Подключение к PostgreSQL
│   │   ├── handlers/     # HTTP обработчики
│   │   ├── models/       # Структуры данных
│   │   └── repository/   # Запросы к БД
│   └── Dockerfile
├── ios/                  # iOS приложение (SwiftUI)
│   └── RecipeApp/
│       ├── Models/       # Recipe, Ingredient
│       ├── Network/      # APIClient
│       ├── ViewModels/   # RecipeViewModel
│       └── Views/        # UI экраны
├── db/
│   └── init.sql          # Схема БД, партиции, индексы
├── seeder/               # Генератор данных (Go, COPY protocol)
├── k8s/                  # Kubernetes манифесты
│   ├── namespace.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── postgres/
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── service.yaml
│       └── statefulset.yaml
├── docker-compose.yml    # Локальная разработка
└── load-test.js          # Нагрузочный тест (k6)
```

## API Endpoints

| Метод  | URL                              | Описание              |
|--------|----------------------------------|-----------------------|
| GET    | /health                          | Health check          |
| GET    | /api/v1/recipes                  | Список (cursor-based) |
| GET    | /api/v1/recipes/search?q=борщ    | Полнотекстовый поиск  |
| GET    | /api/v1/recipes/:id              | Один рецепт           |
| GET    | /api/v1/recipes/:id/ingredients  | Ингредиенты рецепта   |
| GET    | /api/v1/recipes/count            | Количество рецептов   |
| POST   | /api/v1/recipes                  | Создать рецепт        |
| PUT    | /api/v1/recipes/:id              | Обновить рецепт       |
| DELETE | /api/v1/recipes/:id              | Удалить рецепт        |


## Быстрый старт (локально)

```bash
# Поднять PostgreSQL + Backend
docker compose up -d

# Проверить
curl http://localhost:8080/health

# Засидить базу данных
cd seeder && go run main.go
```

## Деплой в Kubernetes (Yandex Cloud)

```bash
# Создать кластер
yc managed-kubernetes cluster create --name recipe-cluster ...

# Собрать и загрузить образ
docker build --platform linux/amd64 -t cr.yandex/REGISTRY_ID/recipe-backend:v1.0 ./backend
docker push cr.yandex/REGISTRY_ID/recipe-backend:v1.0

# Применить манифесты
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres/
kubectl apply -f k8s/backend/

# Проверить
kubectl get pods -n recipe-app
kubectl get svc -n recipe-app
```

## Функционал iOS приложения

- Просмотр списка рецептов с бесконечным скроллом
- Полнотекстовый поиск по названию
- Фильтрация по кухне и времени готовки
- Создание, редактирование рецептов
- Избранное с сохранением в UserDefaults
- Удаление рецептов из избранного (свайп)
- Переключение темы (светлая/тёмная)
- Переключение сетки (1/2 колонки)

## Нагрузочное тестирование

```bash
brew install k6
k6 run load-test.js
```

## Масштабирование

```bash
# Увеличить количество реплик бэкенда
kubectl scale deployment recipe-backend -n recipe-app --replicas=5

# Уменьшить обратно
kubectl scale deployment recipe-backend -n recipe-app --replicas=2
```
