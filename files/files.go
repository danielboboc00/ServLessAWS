package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/rds/auth"
	_ "github.com/go-sql-driver/mysql"
	mysql "github.com/go-sql-driver/mysql"
)

// Define a struct to hold the data from the database
type File struct {
	ID   int
	Name string
	Size int
}

// Define the handler function that takes an APIGatewayProxyRequest and returns an APIGatewayProxyResponse
func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Get the id parameter from the request path
	id := request.QueryStringParameters["id"]

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		panic("configuration error: " + err.Error())
	}

	region := os.Getenv("DB_REGION")
	database_user := os.Getenv("DB_USERNAME")
	database_host := os.Getenv("DB_HOST")
	database_port := os.Getenv("DB_PORT")
	database_name := os.Getenv("DB_NAME")
	database_endpoint := fmt.Sprintf("%s:%s", database_host, database_port)

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

	// Prepare the SQL query to select the row from the files table based on the id
	query := "SELECT id, name, size FROM Files WHERE id = ?"

	// Execute the query and scan the result into a File struct
	var file File

	fmt.Println("executing query...")

	err = db.QueryRow(query, id).Scan(&file.ID, &file.Name, &file.Size)

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("executing update...")

	// Prepare the SQL query to update the downloads column by one for the matching row
	update := "UPDATE Files SET downloads = downloads + 1 WHERE id = ?"

	// Execute the update statement and check for errors
	_, err = db.Exec(update, id)

	if err != nil {
		log.Fatal(err)
	}

	b, err := json.Marshal(file)
	if err != nil {
		log.Fatal(err)
	}

	// Return a response with the file data as JSON
	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       string(b),
	}, nil

}

func main() {
	lambda.Start(handler)
}
