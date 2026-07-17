////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : commands to run.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  simulation command notes for Ethernet verification
////////////////////////////////////////////////////////////////////////////////

make run PLUSARGS="+num_pkts=1 +payload_size=1472" // eth tx
make run PLUSARGS="+num_pkts=100 +fault_prob=50 +en_crc=1 +en_er=1 +en_drop=1" //eth rx
make run PLUSARGS="+num_pkts=10 +fault_prob=50" // eth rx IF
make run PLUSARGS="+num_pkts=10 +bad_crc_prob=10 +rx_er_prob=20"

make run NUM_PKTS=50 CRC_ERR=0 PHY_ERR=0 PREAMBLE_ERR=0

make run PLUSARGS="+NUM_PKTS=1 +PAYLOAD_SIZE=1472 +CRC_ERR=0 +PHY_ERR=0 +PREAMBLE_ERR=0" GUI=1 //eth.sv
make run PLUSARGS="+NUM_PKTS=5 +APP_FREQ=32 +CRC_ERR=0 +PHY_ERR=0"//ETH.SV




sed -i 's/^[ ]\+/\t/' Makefile 