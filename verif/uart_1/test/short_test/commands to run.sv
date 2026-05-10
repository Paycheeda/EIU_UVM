
make run TEST_NAME=uart_base_test WIDTH=8 PLUSARGS="+num_pkts=50" // change width accordingly for tx and packet
make run TEST_NAME=rx_base_test WIDTH=9 PLUSARGS="+num_pkts=20" //change width and packet

make run TEST_NAME=rx_base_test PLUSARGS="+num_uart_packets=5"
make run TEST_NAME=uart_base_test PLUSARGS="+num_uart_packets=5"
make run PLUSARGS="+num_uart_packets=10" // LOOPBACK

sed -i 's/^[ ]\+/\t/' Makefile //SUREFIRE WAY OF FIXING THE PUNCTUATION OF MAKEFILE
make run PLUSARGS="+UVM_TESTNAME=fifo_standalone_test +num_fifo_packets=2100 +wr_freq=500.0 +rd_freq=10.0"

make run TEST_NAME=chaos_test PLUSARGS="+NUM_PKTS=10 +ERR_PROB=100 +ERR_TYPE=BOTH" // PARITY or STOP errors for loopback uart fifo