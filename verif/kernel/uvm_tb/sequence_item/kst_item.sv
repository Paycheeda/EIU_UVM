`ifndef KST_ITEM_SV
`define KST_ITEM_SV

class kst_item extends uvm_sequence_item;
    `uvm_object_utils(kst_item)

    string target_name; // Swapped to string to avoid compiler enum issues

    function new(string name = "kst_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("START/DONE PULSE DETECTED -> Target: %s", target_name);
    endfunction
endclass

`endif