
 add_fsm_encoding \
       {sd_controller.init_state} \
       { }  \
       {{00000 00000} {00001 00001} {00010 00010} {00011 00011} {00100 00100} {00101 00101} {00110 00110} {00111 00111} {01000 01000} {01001 01001} {01010 01010} {01011 01011} {01100 01100} {01101 01101} {01110 01110} {01111 01111} {10000 10000} {10001 10001} {10010 10010} }

 add_fsm_encoding \
       {HMAC_SHA1_VECTOR.current_state} \
       { }  \
       {{000 000} {001 001} {100 010} {101 011} {111 100} }

 add_fsm_encoding \
       {PBKDF2_SHA1_F.current_state} \
       { }  \
       {{000 000} {001 001} {010 010} {011 011} {100 100} {101 101} {110 110} }

 add_fsm_encoding \
       {HMAC_SHA1_VECTOR__parameterized1.current_state} \
       { }  \
       {{000 000} {001 001} {100 010} {101 011} {111 100} }

 add_fsm_encoding \
       {PMK_VERIFY.pmk_state} \
       { }  \
       {{000 000} {001 001} {010 010} {011 011} {100 100} {101 101} {110 110} }

 add_fsm_encoding \
       {UART_TX.transmit_state} \
       { }  \
       {{000 000} {001 001} {010 011} {011 010} {100 100} }

 add_fsm_encoding \
       {WIFI_DECRYPT.uart_tx_state} \
       { }  \
       {{000 00} {001 01} {010 10} {111 11} }
