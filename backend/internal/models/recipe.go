package models

import "time"

type Recipe struct {
	ID          int64     `db:"id"          json:"id"`
	Title       string    `db:"title"        json:"title"`
	Description string    `db:"description"  json:"description"`
	CuisineID   int       `db:"cuisine_id"   json:"cuisine_id"`
	CuisineName string    `db:"cuisine_name" json:"cuisine_name"`
	CookTime    int       `db:"cook_time"    json:"cook_time"`
	Servings    int       `db:"servings"     json:"servings"`
	Difficulty  int       `db:"difficulty"   json:"difficulty"`
	CreatedAt   time.Time `db:"created_at"   json:"created_at"`
}

type CreateRecipeRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	CuisineID   int    `json:"cuisine_id"`
	CookTime    int    `json:"cook_time"`
	Servings    int    `json:"servings"`
	Difficulty  int    `json:"difficulty"`
}

type UpdateRecipeRequest struct {
	Title       string `json:"title"`
	Description string `json:"description"`
	CookTime    int    `json:"cook_time"`
	Servings    int    `json:"servings"`
	Difficulty  int    `json:"difficulty"`
}

type ListResponse struct {
	Data       []Recipe `json:"data"`
	Total      int64    `json:"total"`
	NextCursor int64    `json:"next_cursor"`
}

type Ingredient struct {
	Name   string  `db:"name"   json:"name"`
	Amount float64 `db:"amount" json:"amount"`
	Unit   string  `db:"unit"   json:"unit"`
}
