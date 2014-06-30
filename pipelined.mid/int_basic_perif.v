`timescale 1ns / 1ps
`include "zpupkg.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/20/2014 10:39:34 AM
// Design Name: 
// Module Name: interupt_controler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module int_basic_perif(
    input wire[31:0] gpioin,
    output reg[31:0] gpioout,
    output reg[31:0] gpiodir,
//    inout wire[31:0] gpio,
    input wire clk,
    input wire rst,
    input wire[31:0] wb_in,
    output reg[31:0] wb_out,
    input wire wb_wren,
    input wire[31:0] wb_adr,
    input wire[3:0] wb_sel,
    input wire wb_cyc,
    input wire wb_stb,
    output wire wb_ack,
    output wire wb_stall,
    output wire tx_serial,
    input wire rx_serial,
    input wire[interrupt_number-1:0] interrup,
    output wire cpu_irq,
    output wire[pc_bit_size-1:0]irq_adr,
    input wire exitint,
    input wire irq_ack
    );
    parameter pc_bit_size = 15;
    parameter interrupt_number = 29;
    parameter clk_hz = 100000000;
    parameter boud_rate_debug = 9600;
//    parameter boudgen_size = 16;
    
    integer i;
    genvar j;
    integer z;

    reg[7:0] itstate;
    reg intreq;
    reg irqcoming;
    wire[interrupt_number + 2:0] interuptsaray;
    reg wbackint;
    reg[63:0] counter;
    reg starttx;
    wire[7:0] rxdata;
    wire ready_recive;
    wire transmitint;
    wire reciveint;
    reg[31:0] gpiodirfifo;
    reg[31:0] gpioinfifoout;
    reg[31:0] gpioinfifoin;
    reg[31:0] gpioddr;
    reg[31:0] gpiodat;
    reg[8:0] uarttx;
    reg[8:0] uartrx;
    reg[63:0] countersmp;
    reg[1:0] uratintena;
    reg[1:0] uartintfleg;
    reg systimerintenable;
    reg systimerintfleg;
    reg[31:0] systimermax;
    reg[31:0] systimervalue;
    reg[15:0] boudrate;
    reg[31:0] intpriority;
    reg intinhighreg;
    reg intinlowreg;
    reg intinhigh;
    reg intinlow;
    reg[4:0] intnumber;

    `ifdef enable_uart
        debug_serial //#(
    //        .boudgen_size(boudgen_size)
    //    )
        serial_port(
            .clk(clk),
            .rst(rst),
            .start_trasmit(starttx),
            .ready_recive(ready_recive),
            .reciveint(reciveint),
            .transmitint(transmitint),
            .tx_data(uarttx[7:0]),
            .rx_data(rxdata),
            .tx_serial(tx_serial),
            .rx_serial(rx_serial),
            .boudgen(boudrate[15:0])
            );
    `endif

    initial begin
        boudrate <= clk_hz / boud_rate_debug;
        gpioddr <= 32'hffffffff;
        gpioinfifoout <= 0;
        gpioinfifoin <= 0;
        gpioout <= 0;
        gpiodir <= 0;
        gpiodirfifo <= 0;
    end

    assign irq_adr = `interruptadr;
    
    for(j=0;j<interrupt_number;j=j+1)begin : interrupt_copier
        assign interuptsaray[j+3] = interrup[j];
    end
    assign interuptsaray[0] = (systimerintenable == 1) ? systimerintfleg : 1'b0;
    assign interuptsaray[1] = (uratintena[`uartrxinte] == 1) ? uartintfleg[`uartrxintf] : 1'b0;
    assign interuptsaray[2] = (uratintena[`uarttxinte] == 1) ? uartintfleg[`uarttxintf] : 1'b0;

    `ifdef enable_POPINT
        assign cpu_irq = (intinhigh == 0) ? intreq : 1'b0;
    `else
        assign cpu_irq = ((intinhigh == 0) && (irqcoming == 1)) ? interuptsaray[itstate] : 1'b0;
    `endif

    assign wb_stall = 1'b0;

    assign wb_ack = (wb_cyc == 1) ? wbackint : 1'b0;
    
    always @ (posedge clk)begin
        if(rst == 1)begin
            itstate <= 0;
            intreq <= 0;
            irqcoming <= 0;            
            wbackint <= 0;
//            irq_adr <= `interruptadr;
            counter <= 0;
            starttx <= 0;
            boudrate <= clk_hz / boud_rate_debug;
            gpioddr <= 32'hffffffff;
            gpioinfifoout <= 0;
            gpioinfifoin <= 0;
            gpioout <= 0;
            gpiodir <= 0;
            gpiodirfifo <= 0;
            gpiodat <= 0;
            uarttx <= 0;
            uartrx <= 0;
            countersmp <= 0;
            `ifdef enable_itc
                intinhigh <= 0;
            `else
                intinhigh <= 1;
            `endif
            uratintena <= 0;
            uartintfleg <= 0;
            systimerintenable <= 0;
            systimerintfleg <= 0;
            systimermax <= 0;
            systimervalue <= 0;
            intpriority <= 0;
            intinhighreg <= 0;
            intinlowreg <= 0;
            intinhigh <=  0;
            intinlow <=  0;
            intnumber <= 0; 
        end
        else begin
            // itc
            `ifdef enable_itc
                if(irq_ack == 1)begin
                    intreq <= 0;
                    intinhigh <= intinhighreg;
                    `ifdef enable_priority_int                        
                        intinlow <= intinlowreg;
                    `endif
                end
                `ifdef enable_POPINT
                    `ifdef enable_priority_int
                        if((intinhighreg == 0) && (intinlowreg == 0) && (intreq == 0)) begin
                            for(i=0;i<=interrupt_number+2;i=i+1)begin : interrupt_finder_l
                                if((interuptsaray[i] == 1) && (intpriority[i] == 1))begin
                                    intreq <= 1;
                                    intinlowreg <= 1;
                                    intnumber <= i;
//                                    irq_adr <= `interruptadr;
                                end
                            end
                        end
                        if((intinhighreg == 0) && (intreq == 0)) begin
                            for(i=0;i<=interrupt_number+2;i=i+1)begin : interrupt_finder_h
                                if((interuptsaray[i] == 1) && (intpriority[i] == 0))begin
                                    intreq <= 1;
                                    intinhighreg <= 1;
                                    intnumber <= i;
//                                    irq_adr <= `interruptadr;
                                end
                            end
                        end
                    
                        if(exitint == 1)begin
                            if(intinhigh == 1)begin
                                intinhighreg <= 0;
                                intinhigh <= 0;
                            end
                            else begin
                                intinlowreg <= 0;
                                intinlow <= 0; 
                            end
                        end
                    `else                                   
                        if((intinhighreg == 0) && (intreq == 0)) begin
                            for(i=0;i<=interrupt_number+2;i=i+1)begin : interrupt_finder_nop
                                if((interuptsaray[i] == 1) && (intpriority[i] == 0))begin
                                    intreq <= 1;
                                    intinhighreg <= 1;
                                    intnumber <= i;
//                                    irq_adr <= `interruptadr;
                                end
                            end
                        end
                    
                        if(exitint == 1)begin
                            intinhighreg <= 0;
                            intinhigh <= 0;
                        end
                    `endif    
                `else
                    if((irq_ack == 0) && (intreq == 0))begin
                        irqcoming <= 0;
                        for(i=0;i<=interrupt_number+2;i=i+1)begin  : interrupt_finder_o
                            if((interuptsaray[i] == 1) && (intinhigh == 0))begin
                                itstate <= i;
                                irqcoming <= 1;
                                intnumber <= i;
                                intreq <= 1;                        
//                                irq_adr <= `interruptadr;
                            end
                        end
                        
                    end
                `endif
            `else
                intinhigh <= 1;
            `endif
            //itc end
            //systimer;            
            `ifdef enable_sys_timer
                if(systimervalue == 0)begin
                    systimervalue <= systimermax; 
                    systimerintfleg <= 1;
                end
                else begin
                    systimervalue <= systimervalue - 1;
                end
            `endif
            //systimer end;
            //uart
            `ifdef enable_uart           
                uartrx <= {ready_recive,rxdata};
                uarttx[8] <= transmitint;
                if(transmitint == 1)begin
                    uartintfleg[`uarttxintf] <= 1;
                end
                if(reciveint == 1)begin
                    uartintfleg[`uartrxintf] <= 1;
                end            
            `endif
            //uart end
            //gpio
            `ifdef enable_gpio
                gpiodirfifo <= gpioddr;
                gpiodir <= gpiodirfifo;
                gpioinfifoin <= gpioin;
                gpioinfifoout <= gpiodat;
                for(z=0;z<32;z=z+1)begin
                    if(gpioddr[z] == 1)begin
                        gpiodat[z] <= gpioinfifoin[z];
                    end
                    else begin
                        gpioout[z] <= gpioinfifoout[z];                    
                    end
                end
            `endif
            //gpio end
            //64 bit counter
            `ifdef enable_64b_timer
                counter <= counter + 1;
            `endif
            //wb
            starttx <= 0;
            wbackint <= wb_stb;
            if((wb_cyc == 1) && (wb_stb == 1)) begin
                if(wb_wren == 1)begin
                    if(wb_sel[0] == 1)begin
                        if(wb_adr[5:2] == `gpiodata)begin
                            `ifdef enable_gpio
                                gpiodat[7:0] <= wb_in[7:0];
                            `endif
                        end                    
                        else if(wb_adr[5:2] == `gpiodir)begin
                            `ifdef enable_gpio
                                gpioddr[7:0] <= wb_in[7:0];
                            `endif
                        end
                        else if(wb_adr[5:2] == `uarttx)begin
                            `ifdef enable_uart        
                                uarttx[7:0] <= wb_in[7:0];
                                starttx <= 1;
                            `endif
                        end
                        else if(wb_adr[5:2] == `counterl)begin
                            //counter 64
                            `ifdef enable_64b_timer                        
                                if(wb_in[`counterreset] == 1)begin
                                    countersmp <= 0;
                                    counter <= 0;
                                end
                                else begin
                                    if(wb_in[`countersample] == 1)begin
                                        countersmp <= counter;
                                    end
                                end                
                            `endif
                            //counter 64 en                                          
                        end
                        else if(wb_adr[5:2] == `sysgiereg)begin
                            `ifdef enable_itc
                                intinhigh <= wb_in[`gie];
                                intinhighreg <= wb_in[`gie];
                                intinlow <= wb_in[`gielow];
                                intinlowreg <= wb_in[`gielow];
                            `endif
                        end
                        else if(wb_adr[5:2] == `uartinte)begin
                            `ifdef enable_uart           
                                uratintena <= wb_in[1:0];
                            `endif
                        end
                        else if(wb_adr[5:2] == `uartintf)begin
                            `ifdef enable_uart
                                if(wb_in[`uartrxintf] == 1)begin
                                    uartintfleg[`uartrxintf] <= 0;
                                end
                                if(wb_in[`uarttxintf] == 1)begin
                                    uartintfleg[`uarttxintf] <= 0;
                                end
                            `endif
                        end
                        else if(wb_adr[5:2] == `systimerinte)begin
                            `ifdef enable_sys_timer
                                systimerintenable <= wb_in[0];
                            `endif
                        end
                        else if(wb_adr[5:2] == `systimerintf)begin
                            `ifdef enable_sys_timer
                                if(wb_in[`systimerintfleg] == 1)begin
                                    systimerintfleg <= 0;
                                end
                                if(wb_in[`systimerreset] == 1)begin
               //                     systimerintfleg <= 0;
                                    systimervalue <= systimermax;
                                end
                            `endif
                        end
                        else if(wb_adr[5:2] == `systimermax)begin
                            `ifdef enable_sys_timer
                                systimermax[7:0] <= wb_in[7:0];
                            `endif
                        end                                                                                                 
                        else if(wb_adr[5:2] == `boudrate)begin
                            `ifdef enable_uart
                                boudrate[7:0] <= wb_in[7:0];
                            `endif
                        end
                        else if(wb_adr[5:2] == `intpriobegin)begin
                            `ifdef enable_itc
                                `ifdef enable_POPINT
                                    `ifdef enable_priority_int 
                                        intpriority[7:0] <= wb_in[7:0];
                                    `endif
                                `endif
                            `endif
                        end
                    end
                    if(wb_sel[1] == 1)begin
                        if(wb_adr[5:2] == `gpiodata)begin
                            `ifdef enable_gpio
                                gpiodat[15:8] <= wb_in[15:8];
                            `endif
                        end
                        else if(wb_adr[5:2] == `gpiodir)begin
                            `ifdef enable_gpio
                                gpioddr[15:8] <= wb_in[15:8];
                            `endif
                        end
                        else if(wb_adr[5:2] == `systimermax)begin
                            `ifdef enable_sys_timer
                                systimermax[15:8] <= wb_in[15:8];
                            `endif
                        end
                        else if(wb_adr[5:2] == `boudrate)begin
                            `ifdef enable_uart
                                boudrate[15:8] <= wb_in[15:8];
                            `endif
                        end
                        else if(wb_adr[5:2] == `intpriobegin)begin
                            `ifdef enable_itc
                                `ifdef enable_POPINT
                                    `ifdef enable_priority_int
                                        intpriority[15:8] <= wb_in[15:8];
                                    `endif
                                `endif
                            `endif
                        end
                    end
                    if(wb_sel[2] == 1)begin
                        if(wb_adr[5:2] == `gpiodata)begin
                            `ifdef enable_gpio
                                gpiodat[23:16] <= wb_in[23:16];
                            `endif
                        end
                        else if(wb_adr[5:2] == `gpiodir)begin
                            `ifdef enable_gpio
                                gpioddr[23:16] <= wb_in[23:16];
                            `endif
                        end                    
                        else if(wb_adr[5:2] == `systimermax)begin
                            `ifdef enable_sys_timer
                                systimermax[23:16] <= wb_in[23:16];
                            `endif
                        end
                        else if(wb_adr[5:2] == `intpriobegin)begin
                            `ifdef enable_itc
                                `ifdef enable_POPINT
                                    `ifdef enable_priority_int
                                        intpriority[23:16] <= wb_in[23:16];
                                    `endif
                                `endif
                            `endif
                        end
//                        else if(wb_adr[5:2] == `boudrate)begin
//                            boudrate[23:16] <= wb_in[23:16];
//                        end
                    end
                    if(wb_sel[3] == 1)begin
                        if(wb_adr[5:2] == `gpiodata)begin
                            `ifdef enable_gpio
                                gpiodat[31:24] <= wb_in[31:24];
                            `endif
                        end
                        else if(wb_adr[5:2] == `gpiodir)begin
                            `ifdef enable_gpio
                                gpioddr[31:24] <= wb_in[31:24];
                            `endif
                        end
                        else if(wb_adr[5:2] == `systimermax)begin
                            `ifdef enable_sys_timer
                                systimermax[31:24] <= wb_in[31:24];
                            `endif
                        end
                        else if(wb_adr[5:2] == `intpriobegin)begin
                            `ifdef enable_itc
                                `ifdef enable_POPINT
                                    `ifdef enable_priority_int
                                        intpriority[31:24] <= wb_in[31:24];
                                    `endif
                                `endif
                            `endif
                        end
//                        else if(wb_adr[5:2] == `boudrate)begin
//                            boudrate[31:24] <= wb_in[31:24];
//                        end                        
                    end
                end
                else begin
                    if(wb_adr[5:2] == `gpiodata)begin
                        `ifdef enable_gpio
                            wb_out <= gpiodat;
                        `endif
                    end
                    else if(wb_adr[5:2] == `gpiodir)begin
                        `ifdef enable_gpio
                            wb_out <= gpioddr;
                        `endif
                    end
                    else if(wb_adr[5:2] == `uartinte)begin
                        `ifdef enable_uart
                            wb_out <= {{30{1'b0}},uratintena};
                        `endif
                    end
                    else if(wb_adr[5:2] == `uarttx)begin
                        `ifdef enable_uart
                            wb_out <= {{23{1'b0}},uarttx[8],8'h00};
                        `endif
                    end                
                    else if(wb_adr[5:2] == `uartrx)begin
                        `ifdef enable_uart
                            wb_out <= {{23{1'b0}},uartrx};
                        `endif
                    end                
                    else if(wb_adr[5:2] == `counterl)begin
                        `ifdef enable_64b_timer
                            wb_out <= countersmp[31:0];
                        `endif
                    end                
                    else if(wb_adr[5:2] == `counterh)begin
                        `ifdef enable_64b_timer
                            wb_out <= countersmp[63:32];
                        `endif
                    end                           
                    else if(wb_adr[5:2] == `sysgiereg)begin
                        `ifdef enable_itc
                            wb_out <= {{30{1'b0}},intinlow,intinhigh};
                        `endif
                    end
                    else if(wb_adr[5:2] == `uartintf)begin
                        `ifdef enable_uart
                            wb_out <= {{30{1'b0}},uartintfleg};
                        `endif
                    end
                    else if(wb_adr[5:2] == `systimerintf)begin
                        `ifdef enable_sys_timer
                            wb_out <= {{31{1'b0}},systimerintfleg};
                        `endif
                    end                                     
                    else if(wb_adr[5:2] == `systimerinte)begin
                        `ifdef enable_sys_timer
                            wb_out <= {{31{1'b0}},systimerintenable};
                        `endif
                    end
                    else if(wb_adr[5:2] == `systimervalue)begin
                        `ifdef enable_sys_timer
                            wb_out <= systimervalue;
                        `endif
                    end
                    else if(wb_adr[5:2] == `systimermax)begin
                        `ifdef enable_sys_timer
                            wb_out <= systimermax;
                        `endif
                    end
//                    else if(wb_adr[5:2] == `boudrate)begin
//                        `ifdef enable_uart
//                            wb_out <= {{16{1'b0}},boudrate};
//                        `endif
//                    end
                    else if(wb_adr[5:2] == `intpriobegin)begin
                        `ifdef enable_itc
                            `ifdef enable_POPINT
                                `ifdef enable_priority_int
                                    wb_out <= intpriority;
                                `endif
                            `endif
                        `endif
                    end
                    else if(wb_adr[5:2] == `intnumberreg)begin
                        `ifdef enable_itc
                            wb_out <= intnumber << 2;
                        `endif
                    end
                end                                     
            end
            //wb end
        end
    end
    
endmodule
