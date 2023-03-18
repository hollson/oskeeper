package main

//go:generate go build -ldflags="-s -w" -o hello-server main.go
func main() {
	println("hello world!")
}
