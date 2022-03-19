module mem_delayed_test();
    reg clk;
    wire [data_width - 1:0] rd_data;
    reg [data_width - 1:0] wr_data;
    reg [addr_width - 1:0] addr;
    wire ack;
    wire busy;

    reg rd_req;
    reg wr_req;
    reg rst;

    reg oob_wen;

    mem_delayed #(.mem_simulated_delay(5)) mem_delayed1 (
        .clk(clk),
        .rst(rst),
        .busy(busy),
        .ack(ack),
        .rd_req(rd_req),
        .wr_req(wr_req),
        .rd_data(rd_data),
        .wr_data(wr_data),
        .addr(addr),
        .oob_wen(oob_wen)
    );

    task check_read(
        [addr_width - 1:0] tgt_addr,
        [data_width - 1:0] expected_data,
        [7:0] expected_cycles
    );
        reg [7:0] cycles;
        $display("check read addr=%h exp_data=%h", tgt_addr, expected_data);
        cycles = 0;
        assert (~busy);
        addr = tgt_addr;
        wr_req = 1'b0;
        rd_req = 1'b1;
        #10
        assert(busy);
        do begin
            assert(busy);
            cycles = cycles + 1;
            #10;
        end while(~ack && cycles < 1000);
        assert(~busy);
        assert(rd_data == expected_data);
        $display("cycles %d rd_data=%0h expected_data=%0h", cycles, rd_data, expected_data);
        assert (cycles == expected_cycles);
    endtask

    task write(
        [addr_width - 1:0] tgt_addr,
        [data_width - 1:0] tgt_data,
        [7:0] expected_cycles
    );
        reg [7:0] cycles;
        cycles = 0;
        assert (~busy);
        addr = tgt_addr;
        wr_data = tgt_data;
        wr_req = 1'b1;
        rd_req = 1'b0;

        #10
        assert(busy);
        addr = 'x;
        wr_data = 'x;
        wr_req = 1'b0;
        do begin
            assert(busy);
            cycles = cycles + 1;
            #10;
        end while(~ack && cycles < 1000);

        assert(~busy);
        assert (cycles == expected_cycles);
    endtask

    initial begin
        clk = 1;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        $monitor("t=%0d test.mon ack=%d busy=%d rd_req=%h wr_req=%h addr=%0h rd_data=%0h wr_data=%0h", $time, ack, busy, rd_req, wr_req, addr, rd_data, wr_data);
        rst = 1;

        #10
        rst = 0;
        wr_req = 0;
        oob_wen = 0;
        $display("reset off");

        write(16'h8, 16'hab, mem_delayed1.mem_simulated_delay);
        write(16'h10, 16'hcd, mem_delayed1.mem_simulated_delay);

        check_read(16'h10, 16'hcd, mem_delayed1.mem_simulated_delay);
        check_read(16'h8, 16'hab, mem_delayed1.mem_simulated_delay);
        check_read(16'h10, 16'hcd, mem_delayed1.mem_simulated_delay);
        check_read(16'h8, 16'hab, mem_delayed1.mem_simulated_delay);

        write(16'h14, 16'h11, mem_delayed1.mem_simulated_delay);
        write(16'h18, 16'h22, mem_delayed1.mem_simulated_delay);
        check_read(16'h14, 16'h11, mem_delayed1.mem_simulated_delay);
        check_read(16'h18, 16'h22, mem_delayed1.mem_simulated_delay);

        check_read(16'h10, 16'hcd, mem_delayed1.mem_simulated_delay);
        check_read(16'h8, 16'hab, mem_delayed1.mem_simulated_delay);

        write(16'd8, 16'hab, mem_delayed1.mem_simulated_delay);
        write(16'd11, 16'hcd, mem_delayed1.mem_simulated_delay);
        check_read(16'd8, 16'hcd, mem_delayed1.mem_simulated_delay);

        write(16'd8, 16'hab, mem_delayed1.mem_simulated_delay);
        write(16'd12, 16'hcd, mem_delayed1.mem_simulated_delay);
        check_read(16'd8, 16'hab, mem_delayed1.mem_simulated_delay);
        check_read(16'd12, 16'hcd, mem_delayed1.mem_simulated_delay);

        assert(~busy);

        #200 $finish();
    end
endmodule
