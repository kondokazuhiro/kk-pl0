package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"

	"kkpl0/pl0core"
)

func readInstructions(file string) ([]pl0core.Instruction, error) {
	rf, err := os.Open(file)
	if err != nil {
		return nil, err
	}
	defer rf.Close()

	return pl0core.ReadInstructions(bufio.NewReader(rf))
}

func run(file string, debug bool) error {
	instructions, err := readInstructions(file)
	if err != nil {
		return err
	}
	if debug {
		for i, inst := range instructions {
			fmt.Printf("%d:\t%s\n", i, inst)
		}
	}

	vm := pl0core.NewPL0VM()
	vm.Debug = debug
	return vm.Run(instructions)
}

func usage() {
	fmt.Fprintf(flag.CommandLine.Output(),
		"Usage: %s [options] program\n", os.Args[0])
	flag.PrintDefaults()
}

func main() {
	var debug bool

	flag.BoolVar(&debug, "debug", false, "debug flag")
	flag.Usage = usage
	flag.Parse()

	if flag.NArg() != 1 {
		usage()
		os.Exit(2)
	}

	err := run(flag.Arg(0), debug)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}
