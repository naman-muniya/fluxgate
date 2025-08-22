package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

// Product represents a product in the catalog
type Product struct {
	ID          string    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Price       float64   `json:"price"`
	Category    string    `json:"category"`
	Stock       int       `json:"stock"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// CreateProductRequest represents product creation request
type CreateProductRequest struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	Category    string  `json:"category"`
	Stock       int     `json:"stock"`
}

// UpdateProductRequest represents product update request
type UpdateProductRequest struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Price       float64 `json:"price"`
	Category    string  `json:"category"`
	Stock       int     `json:"stock"`
}

// In-memory storage (replace with database in production)
var products = make(map[string]Product)
var nextID = 1

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	// Initialize with some test products
	initializeTestProducts()

	r := mux.NewRouter()

	// Middleware
	r.Use(loggingMiddleware)
	r.Use(corsMiddleware)

	// Routes
	r.HandleFunc("/", getProductsHandler).Methods("GET")
	r.HandleFunc("/", createProductHandler).Methods("POST")
	r.HandleFunc("/{id}", getProductByIDHandler).Methods("GET")
	r.HandleFunc("/{id}", updateProductHandler).Methods("PUT")
	r.HandleFunc("/{id}", deleteProductHandler).Methods("DELETE")
	r.HandleFunc("/health", healthHandler).Methods("GET")

	log.Printf("Product service starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

func initializeTestProducts() {
	now := time.Now()
	
	products["1"] = Product{
		ID:          "1",
		Name:        "Laptop",
		Description: "High-performance laptop for professionals",
		Price:       1299.99,
		Category:    "Electronics",
		Stock:       50,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	
	products["2"] = Product{
		ID:          "2",
		Name:        "Smartphone",
		Description: "Latest smartphone with advanced features",
		Price:       799.99,
		Category:    "Electronics",
		Stock:       100,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	
	products["3"] = Product{
		ID:          "3",
		Name:        "Coffee Maker",
		Description: "Automatic coffee maker for home use",
		Price:       89.99,
		Category:    "Home & Kitchen",
		Stock:       25,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	
	nextID = 4
}

func getProductsHandler(w http.ResponseWriter, r *http.Request) {
	// Convert map to slice for JSON response
	var productList []Product
	for _, product := range products {
		productList = append(productList, product)
	}

	// Add cache headers for NGINX caching
	w.Header().Set("Cache-Control", "public, max-age=30")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(productList)
}

func createProductHandler(w http.ResponseWriter, r *http.Request) {
	var req CreateProductRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.Name == "" || req.Price <= 0 {
		http.Error(w, "Name and price are required", http.StatusBadRequest)
		return
	}

	now := time.Now()
	productID := strconv.Itoa(nextID)
	
	product := Product{
		ID:          productID,
		Name:        req.Name,
		Description: req.Description,
		Price:       req.Price,
		Category:    req.Category,
		Stock:       req.Stock,
		CreatedAt:   now,
		UpdatedAt:   now,
	}

	products[productID] = product
	nextID++

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(product)
}

func getProductByIDHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	productID := vars["id"]

	product, exists := products[productID]
	if !exists {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	// Add cache headers for NGINX caching
	w.Header().Set("Cache-Control", "public, max-age=30")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

func updateProductHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	productID := vars["id"]

	product, exists := products[productID]
	if !exists {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	var req UpdateProductRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Update product fields
	if req.Name != "" {
		product.Name = req.Name
	}
	if req.Description != "" {
		product.Description = req.Description
	}
	if req.Price > 0 {
		product.Price = req.Price
	}
	if req.Category != "" {
		product.Category = req.Category
	}
	if req.Stock >= 0 {
		product.Stock = req.Stock
	}
	product.UpdatedAt = time.Now()

	products[productID] = product

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(product)
}

func deleteProductHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	productID := vars["id"]

	_, exists := products[productID]
	if !exists {
		http.Error(w, "Product not found", http.StatusNotFound)
		return
	}

	delete(products, productID)

	w.WriteHeader(http.StatusNoContent)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s %s", r.RemoteAddr, r.Method, r.URL)
		next.ServeHTTP(w, r)
	})
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		
		next.ServeHTTP(w, r)
	})
}
