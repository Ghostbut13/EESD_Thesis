class sn_model extends uvm_agent;
    `uvm_component_utils(sn_model)

    //params for configuring sn model
    localparam MEM_QUEUE_SIZE = 16;
    localparam READ_LATENCY = 10;
    localparam WRITE_LATENCY = 20;
    
    //mem_packet for sn model
    typedef struct {
        req_trans req_pkt;
        rsp_trans rsp_pkt;
        dat_trans dat_pkt;
        time ready;
    } mem_packet;
    
    //port connections in sn model
    uvm_get_port #(req_trans) req_noc2sn_port_i;
    uvm_get_port #(dat_trans) dat_noc2sn_port_i;

    uvm_put_port #(dat_trans) dat_sn2noc_port_o;
    uvm_put_port #(rsp_trans) rsp_sn2noc_port_o;

    //memory read and write queues
    mem_packet read_queue [$];
    mem_packet write_queue [$];
    
    //associative array for simulated memory model
    bit[511:0] memory_array [longint];
    
    //associative array for tracking dbid addr association
    longint dbid_map [int];
    
    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
          
        req_noc2sn_port_i = new("req_noc2sn_port_i",this);
        dat_noc2sn_port_i = new("dat_noc2sn_port_i",this);
        dat_sn2noc_port_o = new("dat_sn2noc_port_o",this);
        rsp_sn2noc_port_o = new("rsp_sn2noc_port_o",this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    virtual task run_phase(uvm_phase phase);
        fork
            handle_noc2sn_req;
            process_req;
            handle_noc2sn_dat;
        join
    endtask : run_phase

    //dbid generation for writeback requests
    function int get_next_dbid();
        static int dbid = 0;
    
        int ret = dbid;
        dbid++;
    
        if(dbid == MEM_QUEUE_SIZE)
            dbid = 0;
    
        assert(!dbid_map.exists(ret));
        return ret;
     
    endfunction : get_next_dbid
    
    //update dbid addr association
    function void update_dbid(int id, longint addr);
        dbid_map[id] = addr;
    endfunction : update_dbid
    
    //read from memory model; return 0 on cold miss else return data
    function bit[511:0] read_mem(longint addr);
        if(memory_array.exists(addr)) begin
            //`uvm_info(get_type_name(), $psprintf("FETCHING BLOCK at time: %d", $time),500);
            return memory_array[addr];
        end

        //`uvm_info(get_type_name(), $psprintf("INSTANTIATING BLOCK on RD at time: %d", $time),500);
        memory_array[addr] = {(L1C_DATA_WIDTH){$urandom()}};
        return memory_array[addr];
    endfunction : read_mem
    
    //write to memory model; using byte enables for update; return data
    function bit[511:0] write_mem(longint addr, bit[511:0] dat, bit[63:0] be);

        if(memory_array.exists(addr)) begin
            //memory_array[addr] = memory_array[addr] | out;
            for(int i; i<$bits(dat)/8; i++)
                memory_array[addr][i*8+:8] = be[i] ? dat[i*8+:8] : memory_array[addr][i*8+:8];
            //`uvm_info(get_type_name(), $psprintf("BE: %h", be),500);
            //`uvm_info(get_type_name(), $psprintf("UPDATING BLOCK at time: %d", $time),500);
        end else begin
            //`uvm_info(get_type_name(), $psprintf("INSTANTIATING BLOCK on WR at time: %d", $time),500);
            assert(0);
        end
        return memory_array[addr];
    
    endfunction : write_mem
    
    function dat_trans gen_dat_from_req(req_trans req);
        dat_trans dat = new("dat");
        dat.dat_flit.src_id = req.req_flit.tgt_id;
        dat.dat_flit.tgt_id = req.req_flit.src_id;
        dat.dat_flit.txn_id = req.req_flit.txn_id;
        dat.dat_flit.opcode = COMP_DATA;
        dat.dat_flit.rsp = 3'b010;
        dat.dat_flit.be = '{default:'1};
        return dat;
    endfunction : gen_dat_from_req
    
    function rsp_trans gen_rsp_from_req(req_trans req);
        rsp_trans rsp = new("rsp");
        rsp.rsp_flit.src_id = req.req_flit.tgt_id;
        rsp.rsp_flit.tgt_id = req.req_flit.src_id;
        rsp.rsp_flit.txn_id = req.req_flit.txn_id;
        rsp.rsp_flit.opcode = COMP_DBID_RESP;
        rsp.rsp_flit.addr = req.req_flit.addr;
        rsp.rsp_flit.resp = 0;
        return rsp;
    endfunction : gen_rsp_from_req
    
    task handle_sn2noc_dat(mem_packet mp);
        mp.dat_pkt = gen_dat_from_req(mp.req_pkt);
        mp.dat_pkt.dat_flit.data = read_mem(mp.req_pkt.req_flit.addr); 
        //inserting packet with data into the output port
        `uvm_info(get_type_name(), $psprintf("Generated DAT response at time: %d", $time),500);
        `uvm_info(get_type_name(), mp.req_pkt.convert2string(),500);
        `uvm_info(get_type_name(), mp.dat_pkt.convert2string(),500);
        dat_sn2noc_port_o.put(mp.dat_pkt);
    endtask : handle_sn2noc_dat
    
    task handle_sn2noc_rsp(mem_packet mp);
        mp.rsp_pkt = gen_rsp_from_req(mp.req_pkt);
        //update association between dbid and addr
        mp.rsp_pkt.rsp_flit.dbid  = get_next_dbid();
        update_dbid(mp.rsp_pkt.rsp_flit.dbid, mp.rsp_pkt.rsp_flit.addr);
        `uvm_info(get_type_name(), $psprintf("Generated RSP response at time: %d", $time),500);
        `uvm_info(get_type_name(), mp.req_pkt.convert2string(),500);
        `uvm_info(get_type_name(), mp.rsp_pkt.convert2string(),500);
        rsp_sn2noc_port_o.put(mp.rsp_pkt);
    endtask : handle_sn2noc_rsp
    
    task handle_noc2sn_req;
        mem_packet mp;
        req_trans req_packet;
        forever begin
            //check if there is bufferspace available to handle request
            if(read_queue.size() < MEM_QUEUE_SIZE && write_queue.size() < MEM_QUEUE_SIZE) begin
                if(req_noc2sn_port_i.try_get(req_packet)) begin
                    //Check if packet can be processed
                    //then calc the ready time and inset into read/write queue
                    `uvm_info(get_type_name(), $psprintf("Received req in SN at time: %d", $time),500);
                    `uvm_info(get_type_name(), req_packet.convert2string(),500);
                    if(req_packet.req_flit.opcode == READ_NO_SNP) begin 
                        mp.req_pkt = req_packet;
                        mp.ready = $time+READ_LATENCY;
                        read_queue.push_back(mp);
                    end
    
                    if(req_packet.req_flit.opcode == WRITE_NO_SNP_FULL) begin 
                        mp.req_pkt = req_packet;
                        mp.ready = $time+WRITE_LATENCY;
                        write_queue.push_back(mp);
                    end
                end
            end
            //advance time and try again
            #1;
        end
    endtask : handle_noc2sn_req
    
    task process_req;
        forever begin
            //check if there is bufferspace available to handle request
            //then check if current time has advanced enough
            if(read_queue.size()) 
                if(read_queue[0].ready <= $time) 
                    handle_sn2noc_dat(read_queue.pop_front());
                
            if (write_queue.size()) 
                if(write_queue[0].ready <= $time)
                    handle_sn2noc_rsp(write_queue.pop_front());
                  
            //advance time
            #1;
        end
    endtask : process_req
    
    task handle_noc2sn_dat;
        longint addr;
        dat_trans dat_packet;
        forever begin
            if(dat_noc2sn_port_i.try_get(dat_packet)) begin
                `uvm_info(get_type_name(), $psprintf("Received DAT response at time: %d", $time),500);
                `uvm_info(get_type_name(), dat_packet.convert2string(),500);
                assert(dbid_map.exists(dat_packet.dat_flit.txn_id));
                addr = dbid_map[dat_packet.dat_flit.txn_id];
                dat_packet.dat_flit.data = write_mem(addr, dat_packet.dat_flit.data, dat_packet.dat_flit.be);
                dbid_map.delete(dat_packet.dat_flit.txn_id);
            end
            #1;
        end
    endtask : handle_noc2sn_dat

endclass : sn_model
