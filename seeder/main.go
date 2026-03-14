package main

import (
	"database/sql"
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/lib/pq"
	_ "github.com/lib/pq"
)

var (
	cuisineIDs = []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	recipeTitles = []string{
		"Паста карбонара", "Суши с лососем", "Тако с говядиной",
		"Круассан", "Карри с курицей", "Кунг Пао",
		"Борщ", "Мусака", "Бургер", "Пад Тай",
		"Пицца Маргарита", "Рамен", "Буррито", "Луковый суп",
		"Самоса", "Димсам", "Пельмени", "Гирос",
		"Стейк", "Зелёное карри", "Ризотто", "Темпура",
		"Энчилада", "Киш Лорен", "Палак панир", "Мапо тофу",
		"Щи", "Спанакопита", "Мак энд чиз", "Массаман карри",
	}

	descriptions = []string{
		"Классическое блюдо с богатым вкусом",
		"Лёгкое и полезное блюдо для всей семьи",
		"Традиционный рецепт с секретными специями",
		"Быстро и вкусно — идеально для ужина",
		"Нежная текстура и насыщенный аромат",
		"Острое и пряное блюдо для ценителей",
		"Домашний рецепт передающийся из поколения в поколение",
		"Изысканное блюдо ресторанного уровня",
	}

	units = []string{"г", "кг", "мл", "л", "ст.л.", "ч.л.", "шт", "щепотка"}

	tagNames = []string{
		"завтрак", "обед", "ужин", "быстро", "вегетарианское",
		"острое", "десерт", "суп", "салат", "гриль",
		"выпечка", "здоровое", "детское", "праздничное",
	}

	ingredientNames = []string{
		"Мука", "Сахар", "Соль", "Масло", "Яйца",
		"Молоко", "Сливки", "Томаты", "Лук", "Чеснок",
		"Курица", "Говядина", "Свинина", "Лосось", "Тунец",
		"Рис", "Паста", "Картофель", "Морковь", "Перец",
		"Оливковое масло", "Соевый соус", "Имбирь", "Куркума",
		"Базилик", "Орегано", "Тимьян", "Розмарин", "Кориандр",
		"Пармезан", "Моцарелла", "Фета", "Сметана", "Йогурт",
	}
)

const (
	totalRecipes = 100_000_000
	batchSize    = 10_000
	dbConnStr    = "host=localhost port=5432 user=recipe_user password=recipe_pass dbname=recipe_db sslmode=disable"
)

func main() {
	db, err := sql.Open("postgres", dbConnStr)
	if err != nil {
		log.Fatal("Ошибка подключения:", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		log.Fatal("БД недоступна:", err)
	}
	fmt.Println("Подключились к БД")

	tagIDs := seedTags(db)
	ingredientIDs := seedIngredients(db)
	fmt.Printf("Теги: %d, Ингредиенты: %d\n", len(tagIDs), len(ingredientIDs))

	var already int
	db.QueryRow("SELECT COUNT(*) FROM recipes").Scan(&already)
	fmt.Printf("Уже в БД: %d рецептов\n", already)

	start := time.Now()
	total := already

	for total < totalRecipes {
		size := batchSize
		if total+size > totalRecipes {
			size = totalRecipes - total
		}

		insertBatchCopy(db, size, tagIDs, ingredientIDs)
		total += size

		elapsed := time.Since(start)
		speed := float64(total-already) / elapsed.Seconds()
		remaining := float64(totalRecipes-total) / speed
		fmt.Printf("%d / %d | %.0f рец/сек | осталось ~%.0f мин\n",
			total, totalRecipes, speed, remaining/60)
	}

	fmt.Printf("\nГотово! Всего %d рецептов за %s\n", totalRecipes, time.Since(start))
}

func seedTags(db *sql.DB) []int {
	var ids []int
	for _, name := range tagNames {
		var id int
		db.QueryRow(`
			INSERT INTO tags (name) VALUES ($1)
			ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			RETURNING id`, name).Scan(&id)
		ids = append(ids, id)
	}
	return ids
}

func seedIngredients(db *sql.DB) []int {
	var ids []int
	for _, name := range ingredientNames {
		var id int
		db.QueryRow(`
			INSERT INTO ingredients (name) VALUES ($1)
			ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			RETURNING id`, name).Scan(&id)
		ids = append(ids, id)
	}
	return ids
}

func insertBatchCopy(db *sql.DB, size int, tagIDs, ingredientIDs []int) {
	// Транзакция 1 — вставляем рецепты
	tx, err := db.Begin()
	if err != nil {
		log.Fatal("Ошибка транзакции:", err)
	}

	recipeStmt, err := tx.Prepare(pq.CopyIn("recipes",
		"title", "description", "cuisine_id", "cook_time", "servings", "difficulty"))
	if err != nil {
		tx.Rollback()
		log.Fatal("Ошибка prepare COPY recipes:", err)
	}

	for i := 0; i < size; i++ {
		title := fmt.Sprintf("%s #%d",
			recipeTitles[rand.Intn(len(recipeTitles))],
			rand.Intn(10_000_000))
		desc := descriptions[rand.Intn(len(descriptions))]
		cuisineID := cuisineIDs[rand.Intn(len(cuisineIDs))]
		cookTime := rand.Intn(180) + 5
		servings := rand.Intn(8) + 1
		difficulty := rand.Intn(5) + 1

		_, err = recipeStmt.Exec(title, desc, cuisineID, cookTime, servings, difficulty)
		if err != nil {
			tx.Rollback()
			log.Fatal("Ошибка COPY exec:", err)
		}
	}

	_, err = recipeStmt.Exec()
	if err != nil {
		tx.Rollback()
		log.Fatal("Ошибка финализации COPY recipes:", err)
	}
	recipeStmt.Close()

	if err = tx.Commit(); err != nil {
		log.Fatal("Ошибка commit recipes:", err)
	}

	// Получаем ID — отдельным запросом вне транзакции
	recipeRows, err := db.Query(`
		SELECT id FROM recipes 
		ORDER BY id DESC 
		LIMIT $1`, size)
	if err != nil {
		log.Fatal("Ошибка получения ID:", err)
	}

	var recipeIDs []int64
	for recipeRows.Next() {
		var id int64
		recipeRows.Scan(&id)
		recipeIDs = append(recipeIDs, id)
	}
	recipeRows.Close()

	// Транзакция 2 — вставляем ингредиенты
	tx2, err := db.Begin()
	if err != nil {
		log.Fatal("Ошибка транзакции 2:", err)
	}

	ingStmt, err := tx2.Prepare(pq.CopyIn("recipe_ingredients",
		"recipe_id", "ingredient_id", "amount", "unit"))
	if err != nil {
		tx2.Rollback()
		log.Fatal("Ошибка prepare COPY ingredients:", err)
	}

	for _, recipeID := range recipeIDs {
		ingCount := rand.Intn(3) + 3
		used := map[int]bool{}
		for i := 0; i < ingCount; i++ {
			ingID := ingredientIDs[rand.Intn(len(ingredientIDs))]
			if used[ingID] {
				continue
			}
			used[ingID] = true
			amount := rand.Float64()*500 + 1
			unit := units[rand.Intn(len(units))]
			_, err = ingStmt.Exec(recipeID, ingID, amount, unit)
			if err != nil {
				tx2.Rollback()
				log.Fatal("Ошибка COPY ingredient exec:", err)
			}
		}
	}

	_, err = ingStmt.Exec()
	if err != nil {
		tx2.Rollback()
		log.Fatal("Ошибка финализации COPY ingredients:", err)
	}
	ingStmt.Close()

	if err = tx2.Commit(); err != nil {
		log.Fatal("Ошибка commit ingredients:", err)
	}

	// Транзакция 3 — вставляем теги
	tx3, err := db.Begin()
	if err != nil {
		log.Fatal("Ошибка транзакции 3:", err)
	}

	tagStmt, err := tx3.Prepare(pq.CopyIn("recipe_tags",
		"recipe_id", "tag_id"))
	if err != nil {
		tx3.Rollback()
		log.Fatal("Ошибка prepare COPY tags:", err)
	}

	for _, recipeID := range recipeIDs {
		tagCount := rand.Intn(2) + 1
		usedTags := map[int]bool{}
		for i := 0; i < tagCount; i++ {
			tagID := tagIDs[rand.Intn(len(tagIDs))]
			if usedTags[tagID] {
				continue
			}
			usedTags[tagID] = true
			_, err = tagStmt.Exec(recipeID, tagID)
			if err != nil {
				tx3.Rollback()
				log.Fatal("Ошибка COPY tag exec:", err)
			}
		}
	}

	_, err = tagStmt.Exec()
	if err != nil {
		tx3.Rollback()
		log.Fatal("Ошибка финализации COPY tags:", err)
	}
	tagStmt.Close()

	if err = tx3.Commit(); err != nil {
		log.Fatal("Ошибка commit tags:", err)
	}
}
