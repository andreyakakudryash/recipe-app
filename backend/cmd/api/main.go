package main

import (
	"backend/internal/config"
	"backend/internal/db"
	"backend/internal/handlers"
	"backend/internal/repository"
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	cfg := config.Load()
	database := db.Connect(cfg)

	recipeRepo := repository.NewRecipeRepository(database)
	recipeHandler := handlers.NewRecipeHandler(recipeRepo)

	app := fiber.New(fiber.Config{
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	})
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE",
		AllowHeaders: "Content-Type",
	}))
	app.Use(logger.New())
	app.Use(recover.New())

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})

	// Роуты
	api := app.Group("/api/v1")
	api.Get("/recipes/count", recipeHandler.GetCount)
	api.Get("/recipes", recipeHandler.GetAll)
	api.Get("/recipes/search", recipeHandler.Search)
	api.Get("/recipes/:id", recipeHandler.GetByID)
	api.Get("/recipes/:id/ingredients", recipeHandler.GetIngredients)
	api.Post("/recipes", recipeHandler.Create)
	api.Put("/recipes/:id", recipeHandler.Update)
	api.Delete("/recipes/:id", recipeHandler.Delete)

	log.Printf("Сервер запущен на порту %s", cfg.ServerPort)
	log.Fatal(app.Listen(":" + cfg.ServerPort))
}
