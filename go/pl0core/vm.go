package pl0core

import (
	"fmt"
	"io"
	"os"
)

const (
	// PL0VMStackSize is PL0VM stack size.
	PL0VMStackSize = 2048

	// PL0VMMaxLevel is PL0VM max level.
	PL0VMMaxLevel = 5
)

// PL0VM is PL/0 VM
type PL0VM struct {
	Debug   bool
	Output  io.Writer
	stack   [PL0VMStackSize]int
	display [PL0VMMaxLevel]int
	top     int
	pc      int
}

// NewPL0VM creates a PL0VM instance.
func NewPL0VM() *PL0VM {
	vm := new(PL0VM)
	vm.Debug = false
	vm.Output = os.Stdout
	vm.top = 0
	vm.pc = 0
	return vm
}

// Run executes instructions.
func (vm *PL0VM) Run(instructions []Instruction) error {
	vm.top = 0
	vm.pc = 0
	vm.display[0] = 0
	vm.stack[vm.top] = vm.display[0]
	vm.stack[vm.top+1] = vm.pc

	for {
		inst := instructions[vm.pc]
		vm.pc++

		err := vm.executeInstruction(inst)
		if err != nil {
			return err
		}

		if vm.Debug {
			vm.printState(inst)
		}
		if vm.pc == 0 {
			break
		}
	}
	return nil
}

func (vm *PL0VM) printState(inst Instruction) {
	fmt.Fprintf(vm.Output, "%s\n", inst)
	fmt.Fprintf(vm.Output, "  pc=%d\n", vm.pc)
}

func (vm *PL0VM) executeInstruction(inst Instruction) error {
	switch inst.GetCode() {
	case InstructLOD:
		ai := inst.(*AddrInstruction)
		vm.push(vm.stack[vm.display[ai.Level]+ai.Offset])
	case InstructLDA:
		ai := inst.(*AddrInstruction)
		vm.push(vm.display[ai.Level] + ai.Offset)
	case InstructSTO:
		// OPR,SID is used instead of STO in pl0c.rb.
		ai := inst.(*AddrInstruction)
		vm.stack[vm.display[ai.Level]+ai.Offset] = vm.pop()
	case InstructLIT:
		vi := inst.(*ValueInstruction)
		vm.push(vi.Value)
	case InstructCAL:
		ai := inst.(*AddrInstruction)
		calleeLevel := ai.Level + 1
		vm.stack[vm.top] = vm.display[calleeLevel]
		vm.stack[vm.top+1] = vm.pc
		vm.display[calleeLevel] = vm.top
		vm.pc = ai.Offset
	case InstructRET:
		ai := inst.(*AddrInstruction)
		calleeLevel := ai.Level
		numFuncParams := ai.Offset
		retValue := vm.pop()
		vm.top = vm.display[calleeLevel]
		vm.display[calleeLevel] = vm.stack[vm.top]
		vm.pc = vm.stack[vm.top+1]
		vm.top -= numFuncParams
		vm.push(retValue)
	case InstructICT:
		vi := inst.(*ValueInstruction)
		if vm.top+vi.Value >= PL0VMStackSize {
			panic("stack overflow")
		}
		vm.top += vi.Value
	case InstructJMP:
		vi := inst.(*ValueInstruction)
		vm.pc = vi.Value
	case InstructJPC:
		if vm.pop() == 0 {
			vi := inst.(*ValueInstruction)
			vm.pc = vi.Value
		}
	case InstructOPR:
		err := vm.doOpration(inst.(*OperationInstruction))
		if err != nil {
			return err
		}
	default:
		return fmt.Errorf("Unknown instruction code: %d", inst.GetCode())
	}

	return nil
}

func (vm *PL0VM) push(value int) {
	if vm.top+1 >= PL0VMStackSize {
		panic("stack overflow")
	}
	vm.stack[vm.top] = value
	vm.top++
}

func (vm *PL0VM) pop() int {
	vm.top--
	return vm.stack[vm.top]
}

func (vm *PL0VM) doOpration(oi *OperationInstruction) error {
	switch oi.OpType {
	case OpTypeNEG:
		vm.stack[vm.top-1] = -vm.stack[vm.top-1]
	case OpTypeODD:
		vm.stack[vm.top-1] = vm.stack[vm.top-1] & 1
	case OpTypeADD:
		vm.operateBinaryInt(func(a int, b int) int { return a + b })
	case OpTypeSUB:
		vm.operateBinaryInt(func(a int, b int) int { return a - b })
	case OpTypeMUL:
		vm.operateBinaryInt(func(a int, b int) int { return a * b })
	case OpTypeDIV:
		vm.operateBinaryInt(func(a int, b int) int { return a / b })
	case OpTypeEQ:
		vm.operateBinaryBool(func(a int, b int) bool { return a == b })
	case OpTypeLS:
		vm.operateBinaryBool(func(a int, b int) bool { return a < b })
	case OpTypeGR:
		vm.operateBinaryBool(func(a int, b int) bool { return a > b })
	case OpTypeNEQ:
		vm.operateBinaryBool(func(a int, b int) bool { return a != b })
	case OpTypeLSEQ:
		vm.operateBinaryBool(func(a int, b int) bool { return a <= b })
	case OpTypeGREQ:
		vm.operateBinaryBool(func(a int, b int) bool { return a >= b })
	case OpTypeWRT:
		fmt.Fprintf(vm.Output, "%d ", vm.pop())
	case OpTypeWRL:
		fmt.Fprintln(vm.Output)
	case OpTypeLID:
		vm.stack[vm.top-1] = vm.stack[vm.stack[vm.top-1]]
	case OpTypeSID:
		vm.stack[vm.stack[vm.top-2]] = vm.stack[vm.top-1]
		vm.top -= 2
	default:
		return fmt.Errorf("Unknown operation type: %d", oi.OpType)
	}
	return nil
}

func (vm *PL0VM) operateBinaryInt(calc func(a int, b int) int) {
	vm.pop()
	vm.stack[vm.top-1] = calc(vm.stack[vm.top-1], vm.stack[vm.top])
}

func (vm *PL0VM) operateBinaryBool(calc func(a int, b int) bool) {
	vm.pop()
	if calc(vm.stack[vm.top-1], vm.stack[vm.top]) {
		vm.stack[vm.top-1] = 1
	} else {
		vm.stack[vm.top-1] = 0
	}
}
