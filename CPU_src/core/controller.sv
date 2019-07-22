module controller(input  logic [5:0] op, funct,
                  input  logic       zero,
                  output logic [1:0] memtoreg, 
                  output logic       memwrite,
 //                 output logic       pcsrc, alusrc,
                  
                  output logic [2:0] int_cause,
                  output logic       cause_write,
                  output logic       exit_kernel,
                  output logic       jump_reg,
                  input  logic       overflow,
                  input  logic       kernel_mode,
                  output logic       write_c0,

                  output logic       alusrc,
                  output logic       regdst, regwrite,
                  output logic       branch,
                  output logic       jump,
                  output logic [2:0] alucontrol);

  logic [1:0] aluop;
//  logic       branch;

  maindec md
            (
                .op             (op),

                .funct          (funct),
                .kernel_mode    (kernel_mode),
                .overflow       (overflow),
                .int_cause      (int_cause),
                .cause_write    (cause_write),
                .exit_kernel    (exit_kernel),
                .jump_reg       (jump_reg),
                .write_c0       (write_c0),

                .memtoreg       (memtoreg), 
                .memwrite       (memwrite), 
                .branch         (branch),
                .alusrc         (alusrc), 
                .regdst         (regdst), 
                .regwrite       (regwrite),
                .jump           (jump),
                .aluop          (aluop)
            );

  aludec  ad(funct, aluop, alucontrol);

//  assign pcsrc = branch & zero;
endmodule// controller




module maindec(input  logic [5:0] op,

               input  logic [5:0] funct,
               input  logic       kernel_mode,
               input  logic       overflow,
               output logic [2:0] int_cause,
               output logic       cause_write,
               output logic       exit_kernel,
               output logic       jump_reg,
               output logic       write_c0,

                  
               output logic [1:0] memtoreg, 
               output logic       memwrite, branch, alusrc,
               output logic       regdst, regwrite,
               output logic       jump,
               output logic [1:0] aluop);

  logic [10:0] controls;

  always_comb
    if(overflow)
        int_cause = 3'b001;//арифметическое переполение
    else if((op == 6'b010000 ||
            op == 6'b111100 ||
            op == 6'b111000) && kernel_mode) 
        
        int_cause = 3'b010; // спец команда в режиме пользователя 
    
    else // неопознанная  команда 
        case (op)
            6'b000000: case(funct)          // R-type instructions
                        6'b000000: int_cause = 0; // sll
                        6'b100000: int_cause = 0; // add
                        6'b100010: int_cause = 0; // sub
                        6'b100100: int_cause = 0; // and
                        6'b100101: int_cause = 0; // or
                        6'b101010: int_cause = 0; // slt
                        default:   int_cause = 3'b011; // illegal funct
                       endcase // RTYE
            6'b100011: int_cause = 0; // LW
            6'b101011: int_cause = 0; // SW
            6'b000100: int_cause = 0; // BEQ
            6'b001000: int_cause = 0; // ADDI
            6'b000010: int_cause = 0; // J
            6'b010000: int_cause = 0; // movrf
            6'b111100: int_cause = 0; // movc0
            6'b111000: int_cause = 0; // exk
            6'b110000: int_cause = 0; // jr
            6'b110001: int_cause = 0; // nop
            default:   int_cause = 3'b011; // illegal op
        endcase

  assign cause_write = (int_cause != 0) ? 1'b1 : 1'b0;
  assign exit_kernel = (op == 6'b111000) ? 1'b1 : 1'b0;
  assign write_c0    = (op == 6'b111100) ? 1'b1 : 1'b0;

  assign {regwrite, regdst, alusrc, branch, memwrite,
          memtoreg, jump_reg, jump, aluop} = controls;

  always_comb
    case(op)
      6'b000000: controls <= 11'b11000000010; // RTYPE
      6'b100011: controls <= 11'b10100010000; // LW
      6'b101011: controls <= 11'b00101000000; // SW
      6'b000100: controls <= 11'b00010000001; // BEQ
      6'b001000: controls <= 11'b10100000000; // ADDI
      6'b000010: controls <= 11'b00000000100; // J
 
      6'b010000: if(~kernel_mode)
                    controls <= 11'b11000100000; //movrf переместить в р.файл
                 else                                            
                    controls <= 0;
      6'b111100: if(~kernel_mode)
                    controls <= 11'b00000000000; // movc0 переместить в с0
                 else 
                    controls <= 0;
      6'b111000: if(~kernel_mode)
                    controls <= 11'b00000000000; //exit kernel mode
                 else 
                    controls <= 0;

      6'b110000: controls <= 11'b00000001000; //jr

      6'b110001: controls <= 11'b00000000000; // nop

      default:   controls <= 11'b00000000000; // illegal op
    endcase
endmodule// maindec




module aludec(input  logic [5:0] funct,
              input  logic [1:0] aluop,
              output logic [2:0] alucontrol);

  always_comb
    case(aluop)
      2'b00: alucontrol <= 3'b010;  // add (for lw/sw/addi)
      2'b01: alucontrol <= 3'b110;  // sub (for beq)
      default: case(funct)          // R-type instructions
          6'b000000: alucontrol <= 3'b011; // sll
          6'b100000: alucontrol <= 3'b010; // add
          6'b100010: alucontrol <= 3'b110; // sub
          6'b100100: alucontrol <= 3'b000; // and
          6'b100101: alucontrol <= 3'b001; // or
          6'b101010: alucontrol <= 3'b111; // slt
          default:   alucontrol <= 3'bxxx; // ???
        endcase
    endcase
endmodule//aludec