package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

// Go项目构建Docker镜像，并验证时区等系统信息
func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		fmt.Fprintf(w, "<h1>Hello world</h1>  <h2>时间：%s</h2> <h2>时区：%s</h2>",
			time.Now().Format("2006-01-02 15:04:05"), os.Getenv("TZ"))
	})
	err := http.ListenAndServe(":80", nil)
	if err != nil {
		panic(err)
	}
}
