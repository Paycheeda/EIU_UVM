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
//  simulation command notes for EIU verification
////////////////////////////////////////////////////////////////////////////////

commands to run

make run PLUSARGS="+NUM_PKTS=10 +UART_BAUD=115200"

make run PLUSARGS="+NUM_PKTS=10 +UART_WIDTH=9 +UART_BAUD=115200 +UART_PARITY_EN=1 +UART_PARITY_OE=1"
make run PLUSARGS="+NUM_PKTS=10 +EN_UART1=1 +EN_UART2=0 +EN_UART3=0 +UART_WIDTH=8 +UART_PARITY_EN=1 +UART_PARITY_OE=0"
make run PLUSARGS="+NUM_PKTS=5 +EN_UART1=1 +EN_UART2=0 +EN_UART3=0"

make run PLUSARGS="+NUM_PKTS=1 +EN_UART1=0 +EN_UART2=0 +EN_UART3=0 +UART_WIDTH=8 +UART_PARITY_EN=1 +UART_PARITY_OE=0 +EN_ETH1=1 +EN_ETH2=1 +EN_ETH3=1 +EN_ETH4=1 +EN_NRZ=1 +NRZ_BPW=12 +NRZ_PLEN=50 +NRZ_ENDIAN=0"

make run PLUSARGS="+NUM_PKTS=10 +EN_UART1=0 +EN_UART2=0 +EN_UART3=0 +UART_WIDTH=8 +UART_PARITY_EN=1 +UART_PARITY_OE=0 +EN_ETH1=1 +EN_ETH2=1 +EN_ETH3=1 +EN_ETH4=1 +EN_NRZ=1 +NRZ_BPW=12 +NRZ_PLEN=50 +NRZ_ENDIAN=0 " GUI=0
make run DEBUG=1 PLUSARGS="+DEBUG_PINS +NUM_PKTS=5 +EN_UART1=1 +EN_UART2=1 +EN_UART3=1 +UART_WIDTH=8 +UART_PARITY_EN=1 +UART_PARITY_OE=0 +EN_ETH1=1 +EN_ETH2=1 +EN_ETH3=1 +EN_ETH4=1 +EN_NRZ=1 +NRZ_BPW=8 +NRZ_PLEN=50 +NRZ_ENDIAN=0 +ETH_PLEN=100" GUI=0

make run PLUSARGS="+NUM_PKTS=5 +EN_UART1=1 +EN_UART2=1 +EN_UART3=1 +UART_WIDTH=8 +UART_PARITY_EN=1 +UART_PARITY_OE=0 +EN_ETH1=1 +EN_ETH2=1 +EN_ETH3=1 +EN_ETH4=1 +EN_NRZ=1 +NRZ_BPW=8 +NRZ_PLEN=50 +NRZ_ENDIAN=0 +ETH_PLEN=100" GUI=0

