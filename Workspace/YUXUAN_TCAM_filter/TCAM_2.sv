module TCAM 
#(parameter WIDTH = 33)
(
    // input logic clk, reset,//maybe no need
    input logic reset,
    input logic clk,
    input logic [WIDTH-1:0] tag,
    input logic [6:0] opcode,//opcode
    input logic [6:0] NID,//src NodeID
    output logic [3:0] flag//flag 0 to 3 represent RN1 to RN4, respectively. 1 send request, 0 not send
);
    localparam Y=64;
    localparam P=4;
    logic [P-1:0] present_bit [0:Y-1];
    logic [WIDTH-1:0] cache_tags [0:Y-1];// 64 lines filter. 42 cache tag width and 4 present bits
    logic tag_match;//flag in the loop means find the cache line
    logic replace_match;// if there exist the condition that present bit is all 0 replace that line
    int counter; // LRU counter
    int i;//use for test
    int a=0;
    
    parameter
        // NULL= 7'b0000_000,
        RN1 = 7'b0000_001,
        RN2 = 7'b0000_010,
        RN3 = 7'b0000_100,
        RN4 = 7'b0001_000,
        READ_SHARED = 7'b0000_001,
        READ_UNIQUE = 7'b0000_111,
        WRITE_BACK_FULL =7'b0011_011;
   
    always_comb begin // A exclusive filter
        if(reset)begin
                flag=4'b0000;
                for(int a; a<Y ;a++)begin
                    cache_tags[a]=33'b0;//initial the data
                    present_bit[a]=4'b0;
                end
                tag_match=1'b0;
                replace_match=1'b0;
                counter=0;
        end
        else begin
            //replace_match<=1'b0;
            tag_match<=1'b0;
            for (i = 0; i < Y; i++) begin // search
                //if(tag_match==1'b0)begin
                    if (tag == cache_tags[i]) begin
                            tag_match=1'b1;
                            //If a match is found, filter the address
                            //check the RN
                            //check present bit
                            case (NID)
                                RN1:if (opcode==READ_SHARED)begin
                                        present_bit[i][0]=1'b1;
                                        flag[0]=1'b0;
                                        for(int j=1;j<4;j++)begin
                                            if (present_bit[i][j]==1) begin
                                                flag[j]=1'b1;
                                            end
                                            else begin
                                                flag[j]=1'b0;
                                            end
                                        end
                                    end 
                                    else if (opcode==READ_UNIQUE)begin
                                        present_bit[i][0]=1'b1;
                                        flag[0]=1'b0;
                                        for(int j=1;j<4;j++)begin
                                            if (present_bit[i][j]==1) begin
                                                flag[j]=1'b1;
                                                present_bit[i][j]=1'b0;
                                            end
                                            else begin
                                                flag[j]=1'b0;
                                            end
                                        end
                                    end
                                    else if (opcode==WRITE_BACK_FULL)begin
                                        present_bit[i][0]=1'b0;
                                        flag=4'b0000;
                                    end
                                    else begin
                                        flag=4'b0000;
                                    end
                                RN2:if (opcode==READ_SHARED)begin
                                        for(int j=0;j<4;j++)begin
                                            if(j==1)begin
                                                present_bit[i][j]=1'b1;
                                                flag[j]=1'b0;
                                            end
                                            else begin
                                                if (present_bit[i][j]==1'b1) begin
                                                    flag[j]=1'b1;
                                                end
                                                else begin
                                                    flag[j]=1'b0;
                                                end
                                            end
                                        end
                                    end 
                                    else if (opcode==READ_UNIQUE)begin
                                        for(int j=0;j<4;j++)begin
                                            if(j==1)begin
                                                present_bit[i][j]=1'b1;
                                                flag[j]=1'b0;
                                            end
                                            else begin
                                                if (present_bit[i][j]==1) begin
                                                    flag[j]=1'b1;
                                                    present_bit[i][j]=1'b0;
                                                end
                                                else begin
                                                    flag[j]=1'b0;
                                                end
                                            end
                                        end
                                    end
                                    else if (opcode==WRITE_BACK_FULL) begin
                                        present_bit[i][1]=1'b0;
                                        flag=4'b0000;
                                    end
                                    else begin
                                        flag=4'b0000;
                                    end
                                RN3:if (opcode==READ_SHARED)begin
                                        for(int j=0;j<4;j++)begin
                                            if(j==2)begin
                                                present_bit[i][j]=1'b1;
                                                flag[j]=1'b0;
                                            end
                                            else begin
                                                if (present_bit[i][j]==1) begin
                                                    flag[j]=1'b1;
                                                end
                                                else begin
                                                    flag[j]=1'b0;
                                                end
                                            end
                                        end 
                                    end
                                    else if (opcode==READ_UNIQUE) begin
                                        for(int j=0;j<4;j++)begin
                                            if(j==2)begin
                                                present_bit[i][j]=1'b1;
                                                flag[j]=1'b0;
                                            end
                                            else begin
                                                if (present_bit[i][j]==1) begin
                                                    flag[j]=1'b1;
                                                    present_bit[i][j]=1'b0;
                                                end
                                                else begin
                                                    flag[j]=1'b0;
                                                end
                                            end
                                        end
                                    end
                                    else if (opcode==WRITE_BACK_FULL) begin
                                        present_bit[i][2]=1'b0;
                                        flag=4'b0000;
                                    end
                                    else begin
                                        flag=4'b0000;
                                    end
                                RN4:if (opcode==READ_SHARED)begin
                                        for(int j=0;j<4;j++)begin
                                            if(j==3)begin
                                                present_bit[i][j]=1'b1;
                                                flag[j]=1'b0;
                                            end
                                            else begin
                                                if (present_bit[i][j]==1) begin
                                                    flag[j]=1'b1;
                                                end
                                                else begin
                                                    flag[j]=1'b0;
                                                end
                                            end
                                        end
                                    end 
                                    else if (opcode==READ_UNIQUE) begin
                                        for(int j=0;j<4;j++)begin
                                            if(j==3)begin
                                                present_bit[i][j]=1'b1;
                                                flag[j]=1'b0;
                                            end
                                            else begin
                                                if (present_bit[i][j]==1) begin
                                                    flag[j]=1'b1;
                                                    present_bit[i][j]=1'b0;
                                                end
                                                else begin
                                                    flag[j]=1'b0;
                                                end
                                            end
                                        end
                                    end
                                    else if (opcode==WRITE_BACK_FULL) begin
                                        present_bit[i][3]=1'b0;
                                        flag=4'b0000;
                                    end
                                    else begin
                                        flag=4'b0000;
                                    end
                            endcase
                    end
                    else begin
                        flag=flag; 
                    end
            end 
            if(tag_match==1'b0)begin//
                //replace_match=1'b0;
                for(int k;k<Y;k++)begin
                    if (present_bit[k]==4'b0000)begin
                        if(replace_match==1'b0)begin
                            cache_tags[k]=tag;
                            replace_match=1'b1;
                            case (NID)
                                RN1:present_bit[k]=4'b0001;
                                RN2:present_bit[k]=4'b0010;
                                RN3:present_bit[k]=4'b0100;
                                RN4:present_bit[k]=4'b1000;
                                default:present_bit[k]=4'b0000; 
                            endcase
                            case (NID)
                                RN1:flag=4'b1110;
                                RN2:flag=4'b1101;
                                RN3:flag=4'b1011;
                                RN4:flag=4'b0111;
                                default:flag=4'b0000;
                            endcase
                        end
                        else begin
                            flag=flag;
                        end
                    end
                    else begin
                        replace_match=1'b0;
                    end
                end
                if (replace_match==1'b0)begin//LRU
                    cache_tags[counter]=tag;
                    counter=counter+1;
                    case (NID)
                        RN1:flag=4'b1110;
                        RN2:flag=4'b1101;
                        RN3:flag=4'b1011;
                        RN4:flag=4'b0111;
                        default:flag=4'b0000;
                    endcase
                    
                end
                else begin
                    counter=counter;
                    flag=flag;
                end
            end
            else begin
                tag_match=1'b0;
            end
        end
    end
    //end
endmodule


 