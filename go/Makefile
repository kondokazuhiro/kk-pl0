all: pl0vm

pl0vm: $(wildcard pl0core/*.go cmd/pl0vm/*.go)
	go build ./cmd/pl0vm

clean:
	-rm pl0vm
