package main

import (
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"name":    os.Getenv("APP_NAME"),
			"version": os.Getenv("APP_VERSION"),
			"commit":  os.Getenv("GIT_COMMIT"),
			"time":    time.Now().Format("2006-01-02 15:04:05"),
		})
	})

	router.Run(":8080")
	// fmt.Println("=> ", time.Now().Format("2006-01-02 15:04:05"))
}
