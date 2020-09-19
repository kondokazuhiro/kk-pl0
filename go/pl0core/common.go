package pl0core

import (
	"encoding/binary"
	"fmt"
	"io"
)

const (
	// InstructLIT is instruction code LIT.
	InstructLIT = 1
	// InstructOPR is instruction code OPR.
	InstructOPR = 2
	// InstructLOD is instruction code LOD.
	InstructLOD = 3
	// InstructSTO is instruction code STO.
	InstructSTO = 4
	// InstructCAL is instruction code CAL.
	InstructCAL = 5
	// InstructRET is instruction code RET.
	InstructRET = 6
	// InstructICT is instruction code ICT.
	InstructICT = 7
	// InstructJMP is instruction code JMP.
	InstructJMP = 8
	// InstructJPC is instruction code JPC.
	InstructJPC = 9
	// InstructLDA is instruction code LDA.
	InstructLDA = 10

	// OpTypeNEG is operation type NEG.
	OpTypeNEG = 1
	// OpTypeADD is operation type ADD.
	OpTypeADD = 2
	// OpTypeSUB is operation type SUB.
	OpTypeSUB = 3
	// OpTypeMUL is operation type MUL.
	OpTypeMUL = 4
	// OpTypeDIV is operation type DIV.
	OpTypeDIV = 5
	// OpTypeODD is operation type ODD.
	OpTypeODD = 6
	// OpTypeEQ is operation typee EQ.
	OpTypeEQ = 7
	// OpTypeLS is operation typee LS.
	OpTypeLS = 8
	// OpTypeGR is operation typee GR.
	OpTypeGR = 9
	// OpTypeNEQ is operation type NEQ.
	OpTypeNEQ = 10
	// OpTypeLSEQ is operation type LSEQ.
	OpTypeLSEQ = 11
	// OpTypeGREQ is operation type GREQ.
	OpTypeGREQ = 12
	// OpTypeWRT is operation type WRT.
	OpTypeWRT = 13
	// OpTypeWRL is operation type WRL.
	OpTypeWRL = 14
	// OpTypeLID is operation type LID.
	OpTypeLID = 15
	// OpTypeSID is operation type SID.
	OpTypeSID = 16
)

// Address is code address.
type Address struct {
	Level  int
	Offset int
}

// Instruction is generic instruction.
type Instruction interface {
	GetCode() byte
}

// AddrInstruction is address instruction.
type AddrInstruction struct {
	Code byte
	Address
}

// ValueInstruction is value instruction.
type ValueInstruction struct {
	Code  byte
	Value int
}

// OperationInstruction is oepration instruction.
type OperationInstruction struct {
	Code   byte
	OpType byte
}

// GetCode returns instruction code
func (ai *AddrInstruction) GetCode() byte {
	return ai.Code
}

func (ai *AddrInstruction) String() string {
	return fmt.Sprintf("code:%d address:%d,%d", ai.Code, ai.Level, ai.Offset)
}

// GetCode returns instruction code
func (vi *ValueInstruction) GetCode() byte {
	return vi.Code
}

func (vi *ValueInstruction) String() string {
	return fmt.Sprintf("code:%d value:%d ", vi.Code, vi.Value)
}

// GetCode returns instruction code
func (oi *OperationInstruction) GetCode() byte {
	return oi.Code
}

func (oi *OperationInstruction) String() string {
	return fmt.Sprintf("code:%d operation:%d ", oi.Code, oi.OpType)
}

// ReadInstructions reads instructions.
func ReadInstructions(reader io.Reader) ([]Instruction, error) {
	var instructions []Instruction

	for {
		var code byte
		var valByte byte
		var valInt16 int16
		var valInt32 int32

		err := binary.Read(reader, binary.LittleEndian, &code)
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}

		// TODO: LittleEndian to BigEndian.
		switch code {
		case InstructLIT:
			// read int32
			err = binary.Read(reader, binary.LittleEndian, &valInt32)
			if err != nil {
				return nil, err
			}
			inst := &ValueInstruction{code, int(valInt32)}
			instructions = append(instructions, inst)

		case InstructICT, InstructJMP, InstructJPC:
			// read int16
			err = binary.Read(reader, binary.LittleEndian, &valInt16)
			if err != nil {
				return nil, err
			}
			inst := &ValueInstruction{code, int(valInt16)}
			instructions = append(instructions, inst)

		case InstructLOD, InstructLDA, InstructSTO, InstructCAL, InstructRET:
			// read int16, int16
			addr := new(Address)
			err = binary.Read(reader, binary.LittleEndian, &valInt16)
			if err != nil {
				return nil, err
			}
			addr.Level = int(valInt16)
			err = binary.Read(reader, binary.LittleEndian, &valInt16)
			if err != nil {
				return nil, err
			}
			addr.Offset = int(valInt16)
			inst := &AddrInstruction{code, *addr}
			instructions = append(instructions, inst)

		case InstructOPR:
			// read byte
			err = binary.Read(reader, binary.LittleEndian, &valByte)
			if err != nil {
				return nil, err
			}
			inst := &OperationInstruction{code, valByte}
			instructions = append(instructions, inst)

		default:
			return nil, fmt.Errorf("Unknown instruction code %d", code)
		}
	}
	return instructions, nil
}
