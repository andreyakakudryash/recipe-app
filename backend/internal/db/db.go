package db

import (
	"fmt"
	"log"

	"backend/internal/config"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func Connect(cfg *config.Config) *sqlx.DB {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName,
	)

	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		log.Fatal("Ошибка подключения к БД:", err)
	}

	db.SetMaxOpenConns(50)
	db.SetMaxIdleConns(10)

	log.Println("Подключились к БД")
	return db
}
