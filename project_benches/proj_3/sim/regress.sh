rm -rf *ucdb
make clean
make compile
make optimize

make run_cli GEN_TRANS_TYPE=i2cmb_test TEST_SEED=random
make merge_coverage
