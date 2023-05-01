rm -rf *ucdb
make clean
make compile
chmod -R 777 work
make compile
make optimize

make run_cli GEN_TEST_TYPE=consecutive_read_test TEST_SEED=random
make run_cli GEN_TEST_TYPE=consecutive_write_test TEST_SEED=random
make run_cli GEN_TEST_TYPE=alt_read_write_test TEST_SEED=random
make run_cli GEN_TEST_TYPE=register_aliasing TEST_SEED=random
make run_cli GEN_TEST_TYPE=write_on_read_only_register TEST_SEED=random
make run_cli GEN_TEST_TYPE=don_bit_check TEST_SEED=random
make run_cli GEN_TEST_TYPE=bus_busy_capture_id_check TEST_SEED=random
make run_cli GEN_TEST_TYPE=default_offset_check TEST_SEED=random
make run_cli GEN_TEST_TYPE=read_write_permission TEST_SEED=random
make run_cli GEN_TEST_TYPE=reset_iicm_check TEST_SEED=random
make run_cli GEN_TEST_TYPE=error_check TEST_SEED=random

make merge_coverage
make view_coverage

