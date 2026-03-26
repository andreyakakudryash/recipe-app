package repository

import (
	"backend/internal/models"
	"fmt"

	"github.com/jmoiron/sqlx"
)

type RecipeRepository struct {
	db *sqlx.DB
}

func NewRecipeRepository(db *sqlx.DB) *RecipeRepository {
	return &RecipeRepository{db: db}
}

func (r *RecipeRepository) GetAll(cursor int64, limit int, cuisineID int, maxCookTime int) ([]models.Recipe, error) {
	query := `
		SELECT r.id, r.title, r.description, r.cuisine_id,
		       c.name as cuisine_name, r.cook_time, r.servings,
		       r.difficulty, r.created_at
		FROM recipes r
		JOIN cuisines c ON c.id = r.cuisine_id
		WHERE 1=1`

	args := []interface{}{}
	argN := 1

	if cursor > 0 {
		query += fmt.Sprintf(" AND r.id < $%d", argN)
		args = append(args, cursor)
		argN++
	}
	if cuisineID > 0 {
		query += fmt.Sprintf(" AND r.cuisine_id = $%d", argN)
		args = append(args, cuisineID)
		argN++
	}
	if maxCookTime > 0 {
		query += fmt.Sprintf(" AND r.cook_time <= $%d", argN)
		args = append(args, maxCookTime)
		argN++
	}

	query += fmt.Sprintf(" ORDER BY r.id DESC LIMIT $%d", argN)
	args = append(args, limit)

	var recipes []models.Recipe
	err := r.db.Select(&recipes, query, args...)
	return recipes, err
}

func (r *RecipeRepository) GetByID(id int64) (*models.Recipe, error) {
	var recipe models.Recipe
	err := r.db.Get(&recipe, `
		SELECT r.id, r.title, r.description, r.cuisine_id,
		       c.name as cuisine_name, r.cook_time, r.servings,
		       r.difficulty, r.created_at
		FROM recipes r
		JOIN cuisines c ON c.id = r.cuisine_id
		WHERE r.id = $1`, id)
	if err != nil {
		return nil, err
	}
	return &recipe, nil
}

func (r *RecipeRepository) Search(query string, cursor int64, limit int) ([]models.Recipe, error) {
	var recipes []models.Recipe

	sql := `
		SELECT r.id, r.title, r.description, r.cuisine_id,
		       c.name as cuisine_name, r.cook_time, r.servings,
		       r.difficulty, r.created_at
		FROM recipes r
		JOIN cuisines c ON c.id = r.cuisine_id
		WHERE (
			to_tsvector('russian', r.title || ' ' || coalesce(r.description, ''))
			@@ plainto_tsquery('russian', $1)
		)`

	args := []interface{}{query}
	argN := 2

	if cursor > 0 {
		sql += fmt.Sprintf(" AND r.id < $%d", argN)
		args = append(args, cursor)
		argN++
	}

	sql += fmt.Sprintf(" ORDER BY r.id DESC LIMIT $%d", argN)
	args = append(args, limit)

	err := r.db.Select(&recipes, sql, args...)
	return recipes, err
}

func (r *RecipeRepository) Create(req *models.CreateRecipeRequest) (*models.Recipe, error) {
	var recipe models.Recipe
	err := r.db.QueryRowx(`
		WITH inserted AS (
			INSERT INTO recipes (title, description, cuisine_id, cook_time, servings, difficulty)
			VALUES ($1, $2, $3, $4, $5, $6)
			RETURNING id, title, description, cuisine_id, cook_time, servings, difficulty, created_at
		)
		SELECT i.id, i.title, i.description, i.cuisine_id,
		       c.name as cuisine_name, i.cook_time, i.servings,
		       i.difficulty, i.created_at
		FROM inserted i
		JOIN cuisines c ON c.id = i.cuisine_id`,
		req.Title, req.Description, req.CuisineID,
		req.CookTime, req.Servings, req.Difficulty,
	).StructScan(&recipe)
	if err != nil {
		return nil, err
	}
	return &recipe, nil
}

func (r *RecipeRepository) Update(id int64, req *models.UpdateRecipeRequest) (*models.Recipe, error) {
	var recipe models.Recipe
	err := r.db.QueryRowx(`
		WITH updated AS (
			UPDATE recipes
			SET title = $1, description = $2, cook_time = $3,
			    servings = $4, difficulty = $5
			WHERE id = $6
			RETURNING id, title, description, cuisine_id, cook_time, servings, difficulty, created_at
		)
		SELECT u.id, u.title, u.description, u.cuisine_id,
		       c.name as cuisine_name, u.cook_time, u.servings,
		       u.difficulty, u.created_at
		FROM updated u
		JOIN cuisines c ON c.id = u.cuisine_id`,
		req.Title, req.Description, req.CookTime,
		req.Servings, req.Difficulty, id,
	).StructScan(&recipe)
	if err != nil {
		return nil, err
	}
	return &recipe, nil
}

func (r *RecipeRepository) Delete(id int64) error {
	result, err := r.db.Exec(`DELETE FROM recipes WHERE id = $1`, id)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("not_found")
	}
	return nil
}

func (r *RecipeRepository) Count() (int64, error) {
	var count int64
	err := r.db.Get(&count, `
		SELECT COALESCE(SUM(n_live_tup), 0)::bigint
		FROM pg_stat_user_tables
		WHERE relname LIKE 'recipes_%'`)
	if err != nil || count == 0 {
		err = r.db.Get(&count, `
			SELECT reltuples::bigint
			FROM pg_class
			WHERE relname = 'recipes'`)
	}
	return count, err
}

func (r *RecipeRepository) GetIngredients(recipeID int64) ([]models.Ingredient, error) {
	var ingredients []models.Ingredient
	err := r.db.Select(&ingredients, `
		SELECT i.name, ri.amount, ri.unit
		FROM recipe_ingredients ri
		JOIN ingredients i ON i.id = ri.ingredient_id
		WHERE ri.recipe_id = $1`, recipeID)
	return ingredients, err
}
