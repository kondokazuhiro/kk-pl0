all: pl0vm

pl0vm: $(wildcard pl0core/*.go cmd/pl0vm/*.go)
	go build ./cmd/pl0vm
	go vet ./...

test:
	go test ./...

coverage:
	go test ./... -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html

clean:
	-rm pl0vm coverage.out coverage.html
