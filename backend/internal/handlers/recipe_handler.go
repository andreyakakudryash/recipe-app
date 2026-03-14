package handlers

import (
	"backend/internal/models"
	"backend/internal/repository"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

type RecipeHandler struct {
	repo *repository.RecipeRepository
}

func NewRecipeHandler(repo *repository.RecipeRepository) *RecipeHandler {
	return &RecipeHandler{repo: repo}
}

func (h *RecipeHandler) GetAll(c *fiber.Ctx) error {
	cursor, _ := strconv.ParseInt(c.Query("cursor", "0"), 10, 64)
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	cuisineID, _ := strconv.Atoi(c.Query("cuisine_id", "0"))
	maxCookTime, _ := strconv.Atoi(c.Query("max_cook_time", "0"))

	if limit > 100 {
		limit = 100
	}

	recipes, err := h.repo.GetAll(cursor, limit, cuisineID, maxCookTime)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var nextCursor int64
	if len(recipes) == limit {
		nextCursor = recipes[len(recipes)-1].ID
	}

	return c.JSON(fiber.Map{
		"data":        recipes,
		"next_cursor": nextCursor,
	})
}

func (h *RecipeHandler) GetByID(c *fiber.Ctx) error {
	id, err := strconv.ParseInt(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "неверный ID"})
	}

	recipe, err := h.repo.GetByID(id)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "рецепт не найден"})
	}

	return c.JSON(recipe)
}

func (h *RecipeHandler) Search(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return c.Status(400).JSON(fiber.Map{"error": "параметр q обязателен"})
	}

	cursor, _ := strconv.ParseInt(c.Query("cursor", "0"), 10, 64)
	limit, _ := strconv.Atoi(c.Query("limit", "20"))

	recipes, err := h.repo.Search(query, cursor, limit)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	var nextCursor int64
	if len(recipes) == limit {
		nextCursor = recipes[len(recipes)-1].ID
	}

	return c.JSON(fiber.Map{
		"data":        recipes,
		"next_cursor": nextCursor,
	})
}

func (h *RecipeHandler) Create(c *fiber.Ctx) error {
	var req models.CreateRecipeRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "неверный формат запроса"})
	}

	if req.Title == "" || req.CuisineID == 0 {
		return c.Status(400).JSON(fiber.Map{"error": "title и cuisine_id обязательны"})
	}

	recipe, err := h.repo.Create(&req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.Status(201).JSON(recipe)
}

func (h *RecipeHandler) Update(c *fiber.Ctx) error {
	id, err := strconv.ParseInt(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "неверный ID"})
	}

	var req models.UpdateRecipeRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "неверный формат запроса"})
	}

	recipe, err := h.repo.Update(id, &req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(recipe)
}

func (h *RecipeHandler) Delete(c *fiber.Ctx) error {
	id, err := strconv.ParseInt(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "неверный ID"})
	}

	if err := h.repo.Delete(id); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"message": "рецепт удалён"})
}

func (h *RecipeHandler) GetIngredients(c *fiber.Ctx) error {
	id, err := strconv.ParseInt(c.Params("id"), 10, 64)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "неверный ID"})
	}

	ingredients, err := h.repo.GetIngredients(id)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(fiber.Map{"data": ingredients})
}

func (h *RecipeHandler) GetCount(c *fiber.Ctx) error {
	count, err := h.repo.Count()
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}
	return c.JSON(fiber.Map{"count": count})
}
