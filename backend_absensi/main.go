package main

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/glebarez/sqlite"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

// --- DATABASE MODELS ---

type User struct {
	ID         uint   `gorm:"primaryKey" json:"user_id"`
	Email      string `gorm:"unique" json:"email"`
	Password   string `json:"-"`
	Name       string `json:"name"`
	Role       string `json:"role"`
	Department string `json:"department"`
}

type AttendanceLog struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user"`
	LocalID   int       `json:"local_id"`
	Type      string    `json:"type"`
	Timestamp string    `json:"timestamp"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	PhotoURL  string    `json:"photo_url"`
	CreatedAt time.Time `json:"created_at"`
}

type SyncRecord struct {
	LocalID     int     `json:"local_id"`
	Type        string  `json:"type"`
	Timestamp   string  `json:"timestamp"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	PhotoBase64 string  `json:"photo_base64"`
}

type SyncRequest struct {
	Records []SyncRecord `json:"records"`
}

var db *gorm.DB
var jwtKey = []byte("rahasia_super_aman")

// --- MAIN FUNCTION ---

func main() {
	var err error
	db, err = gorm.Open(sqlite.Open("absensi.db"), &gorm.Config{})
	if err != nil {
		panic("Gagal koneksi database: " + err.Error())
	}

	db.AutoMigrate(&User{}, &AttendanceLog{})

	// Seed User Dummy
	var count int64
	db.Model(&User{}).Count(&count)
	if count == 0 {
		db.Create(&User{
			Email:      "admin",
			Password:   "1234",
			Name:       "Administrator",
			Role:       "Admin",
			Department: "IT",
		})
		fmt.Println("[INFO] User admin dibuat.")
	}

	r := gin.Default()

	r.LoadHTMLGlob("templates/*")
	os.MkdirAll("./uploads", os.ModePerm)
	r.Static("/uploads", "./uploads")

	r.GET("/", func(c *gin.Context) { c.Redirect(http.StatusFound, "/admin/login") })

	admin := r.Group("/admin")
	{
		admin.GET("/login", viewLogin)
		admin.POST("/login", processLogin)
		admin.GET("/logout", processLogout)

		admin.Use(cookieAuthMiddleware())
		{
			admin.GET("/dashboard", viewDashboard)
			admin.POST("/attendance/delete", deleteAttendance)

			admin.GET("/users", viewUsers)
			admin.POST("/users/create", createUser)
			admin.POST("/users/delete", deleteUser)
			// ROUTE BARU: UPDATE PASSWORD
			admin.POST("/users/update_password", updateUserPassword)

			admin.GET("/schedule", viewSchedule)
		}
	}

	api := r.Group("/api")
	{
		api.POST("/auth/login", apiLoginHandler)
		api.POST("/attendance/sync", apiAuthMiddleware(), apiSyncHandler)
	}

	fmt.Println("Server berjalan di http://localhost:8000")
	r.Run(":8000")
}

// ================= WEB HANDLERS =================

func viewLogin(c *gin.Context) {
	c.HTML(http.StatusOK, "login.html", gin.H{"Title": "Login Admin"})
}

func processLogin(c *gin.Context) {
	email := c.PostForm("email")
	password := c.PostForm("password")
	var user User
	if err := db.Where("email = ? AND password = ?", email, password).First(&user).Error; err != nil {
		c.HTML(http.StatusOK, "login.html", gin.H{"Error": "Email/Pass Salah"})
		return
	}
	c.SetCookie("admin_session", user.Email, 3600, "/", "localhost", false, true)
	c.Redirect(http.StatusFound, "/admin/dashboard")
}

func processLogout(c *gin.Context) {
	c.SetCookie("admin_session", "", -1, "/", "localhost", false, true)
	c.Redirect(http.StatusFound, "/admin/login")
}

func viewDashboard(c *gin.Context) {
	var logs []AttendanceLog
	db.Preload("User").Order("created_at desc").Find(&logs)
	c.HTML(http.StatusOK, "dashboard.html", gin.H{
		"Title":      "Dashboard Absensi",
		"ActiveMenu": "absensi",
		"Logs":       logs,
		"UserEmail":  c.MustGet("user_email"),
	})
}

func deleteAttendance(c *gin.Context) {
	id := c.PostForm("id")
	if err := db.Delete(&AttendanceLog{}, id).Error; err != nil {
		fmt.Println("Gagal hapus:", err)
	}
	c.Redirect(http.StatusFound, "/admin/dashboard")
}

func viewUsers(c *gin.Context) {
	var users []User
	db.Find(&users)
	c.HTML(http.StatusOK, "dashboard.html", gin.H{
		"Title":      "Users",
		"ActiveMenu": "user",
		"ShowUsers":  true,
		"Users":      users,
		"UserEmail":  c.MustGet("user_email"),
	})
}

func createUser(c *gin.Context) {
	var newUser User
	newUser.Name = c.PostForm("name")
	newUser.Email = c.PostForm("email")
	newUser.Password = c.PostForm("password")
	newUser.Role = c.PostForm("role")
	newUser.Department = c.PostForm("department")

	if err := db.Create(&newUser).Error; err != nil {
		fmt.Println("Gagal create user:", err)
	}
	c.Redirect(http.StatusFound, "/admin/users")
}

func deleteUser(c *gin.Context) {
	id := c.PostForm("id")
	if id == "1" { // Protect Admin
		c.Redirect(http.StatusFound, "/admin/users")
		return
	}
	db.Delete(&User{}, id)
	c.Redirect(http.StatusFound, "/admin/users")
}

// --- FUNGSI BARU: UPDATE PASSWORD ---
func updateUserPassword(c *gin.Context) {
	id := c.PostForm("id")
	newPassword := c.PostForm("password")

	if newPassword != "" {
		var user User
		if err := db.First(&user, id).Error; err == nil {
			user.Password = newPassword
			db.Save(&user)
			fmt.Printf("Password user %s berhasil diubah\n", user.Name)
		}
	}
	c.Redirect(http.StatusFound, "/admin/users")
}

func viewSchedule(c *gin.Context) {
	c.HTML(http.StatusOK, "dashboard.html", gin.H{"Title": "Jadwal", "ActiveMenu": "schedule", "ShowSchedule": true, "UserEmail": c.MustGet("user_email")})
}

func cookieAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		cookie, _ := c.Cookie("admin_session")
		if cookie == "" {
			c.Redirect(http.StatusFound, "/admin/login")
			c.Abort()
			return
		}
		c.Set("user_email", cookie)
		c.Next()
	}
}

// ================= API HANDLERS =================

func apiLoginHandler(c *gin.Context) {
	var input struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	var user User
	if err := db.Where("email = ? AND password = ?", input.Email, input.Password).First(&user).Error; err != nil {
		c.JSON(401, gin.H{"success": false, "message": "Login Gagal"})
		return
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})
	tString, _ := token.SignedString(jwtKey)

	fmt.Printf("[LOGIN] User %s login sukses.\n", user.Email)
	c.JSON(200, gin.H{"success": true, "data": gin.H{"token": tString, "name": user.Name}})
}

func apiSyncHandler(c *gin.Context) {
	userID := uint(c.MustGet("user_id").(float64))
	var req SyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"success": false, "message": err.Error()})
		return
	}

	savedCount := 0
	for _, rec := range req.Records {
		photoPath := ""
		if rec.PhotoBase64 != "" {
			filename := fmt.Sprintf("u%d_%d_%s_%s.jpg", userID, rec.LocalID, rec.Type, time.Now().Format("20060102150405"))
			savePath := filepath.Join("uploads", filename)
			b64 := rec.PhotoBase64
			if idx := strings.Index(b64, ","); idx != -1 {
				b64 = b64[idx+1:]
			}
			dec, _ := base64.StdEncoding.DecodeString(b64)
			os.WriteFile(savePath, dec, 0644)
			photoPath = fmt.Sprintf("/uploads/%s", filename)
		}

		var exists int64
		db.Model(&AttendanceLog{}).Where("user_id = ? AND local_id = ? AND type = ?", userID, rec.LocalID, rec.Type).Count(&exists)
		if exists == 0 {
			db.Create(&AttendanceLog{
				UserID: userID, LocalID: rec.LocalID, Type: rec.Type, Timestamp: rec.Timestamp,
				Latitude: rec.Latitude, Longitude: rec.Longitude, PhotoURL: photoPath,
			})
			savedCount++
		}
	}
	c.JSON(200, gin.H{"success": true, "synced_count": savedCount})
}

func apiAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(401, gin.H{"error": "No token"})
			return
		}
		tokenString := strings.Replace(authHeader, "Bearer ", "", 1)
		token, _ := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) { return jwtKey, nil })
		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			c.Set("user_id", claims["user_id"])
			c.Next()
		} else {
			c.AbortWithStatusJSON(401, gin.H{"error": "Invalid token"})
		}
	}
}
