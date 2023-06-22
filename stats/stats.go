package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/rds/auth"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	_ "github.com/go-sql-driver/mysql"
	mysql "github.com/go-sql-driver/mysql"
)

// Define a struct to hold the data from the database
type File struct {
	ID        int
	Name      string
	Size      int
	Downloads int
}

// Define the handler function that takes an S3Event and returns an error
func handler(ctx context.Context) error {

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		panic("configuration error: " + err.Error())
	}

	region := os.Getenv("DB_REGION")
	database_user := os.Getenv("DB_USERNAME")
	database_host := os.Getenv("DB_HOST")
	database_port := os.Getenv("DB_PORT")
	database_name := os.Getenv("DB_NAME")

	bucket_name := os.Getenv("BUCKET_NAME")

	database_endpoint := fmt.Sprintf("%s:%s", database_host, database_port)

	// Create a new AWS session
	sess := session.Must(
		session.NewSession(
			&aws.Config{
				Region: aws.String(region),
			},
		),
	)

	// Generate an auth token for connecting to the proxy
	auth_token, err := auth.BuildAuthToken(
		ctx,
		database_endpoint, // Database Endpoint (With Port)
		region,            // AWS Region
		database_user,     // Database Account
		cfg.Credentials,
	)

	if err != nil {
		log.Fatal(err)
	}

	rootCertPool := x509.NewCertPool()
	pem, err := ioutil.ReadFile("bundle.pem")
	if err != nil {
		log.Fatal(err)
	}
	if ok := rootCertPool.AppendCertsFromPEM(pem); !ok {
		log.Fatal("Failed to append PEM.")
	}
	mysql.RegisterTLSConfig("rds", &tls.Config{
		ServerName: database_host,
		RootCAs:    rootCertPool,
	})

	connection_string := fmt.Sprintf("%s:%s@tcp(%s)/%s?tls=rds&allowCleartextPasswords=true",
		database_user,
		auth_token,
		database_endpoint,
		database_name,
	)

	fmt.Println(connection_string)
	// Create a new database connection using the auth token
	db, err := sql.Open(
		"mysql",
		connection_string,
	)

	if err != nil {
		log.Fatal(err)
	}

	defer db.Close()

	// Prepare the SQL query to select all rows from the files table
	query := "SELECT id, name, size, downloads FROM Files"

	fmt.Println("executing query...")
	// Execute the query and get the result set
	rows, err := db.Query(query)

	if err != nil {
		log.Fatal(err)
	}

	defer rows.Close()

	// Create a slice of File structs to hold the data
	var files []File

	// Loop through the rows and scan each one into a File struct
	for rows.Next() {
		var file File

		err = rows.Scan(&file.ID, &file.Name, &file.Size, &file.Downloads)

		if err != nil {
			log.Fatal(err)
		}

		// Append the File struct to the slice
		files = append(files, file)
	}

	// Check for errors from iterating over rows
	if err = rows.Err(); err != nil {
		log.Fatal(err)
	}

	fmt.Println("marshalling...")
	// Marshal the slice of File structs into JSON bytes
	data, err := json.Marshal(files)

	if err != nil {
		log.Fatal(err)
	}

	// Create a new S3 uploader using the session
	uploader := s3manager.NewUploader(sess)
	key_name := time.Now().Format("20060102T150405Z")

	fmt.Println("uploading...")
	// Upload the JSON bytes to the specified S3 bucket and key
	_, err = uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(bucket_name), // Replace with your S3 bucket name
		Key:    aws.String(key_name),    // Replace with your S3 key name
		Body:   bytes.NewReader(data),
	})

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("finished!")

	return nil
}

func main() {
	lambda.Start(handler)
}
