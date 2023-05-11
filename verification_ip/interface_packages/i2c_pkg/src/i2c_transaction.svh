class i2c_transaction extends ncsu_transaction;
    /*
    A class used to represent an I2C Transaction.

    This class is responsible for handling I2C transactions, which include specifying the slave address, read/write operation, data, number of bytes, and bus number.

    Attributes
    ----------
    address : bit [I2C_SLAVE_ADDR_SIZE-1:0]
        The slave address for the I2C transaction
    rw : bit
        Specifies if the transaction is a read (1) or write (0) operation
    data : bit [I2C_BYTE_SIZE-1:0][]
        The data involved in the I2C transaction
    num_bytes : int
        The number of bytes involved in the transaction
    bus_num : int
        The bus number where the transaction takes place
    */
    bit [I2C_SLAVE_ADDR_SIZE-1:0] address;
    bit rw;
    bit [I2C_BYTE_SIZE-1:0] data [];
    int num_bytes;
    int bus_num;

    function new(string name="",
                bit [I2C_SLAVE_ADDR_SIZE-1:0] address = 0,
                bit rw = WRITE, 
                int num_bytes = 0,
                int bus_num = 0
                );
        /*
        Constructs all the necessary attributes for the i2c_transaction object.

        Parameters
        ----------
        name : string
            The name of the I2C transaction
        address : bit [I2C_SLAVE_ADDR_SIZE-1:0]
            The slave address for the I2C transaction
        rw : bit
            Specifies if the transaction is a read (1) or write (0) operation
        num_bytes : int
            The number of bytes involved in the transaction
        bus_num : int
            The bus number where the transaction takes place
        */
        super.new(name);
        this.address = address;
        this.rw = rw;
        this.num_bytes = num_bytes;
        this.bus_num = bus_num;
    endfunction

    virtual function string convert2string();
        /*
        Converts the I2C transaction details to a string format.

        Returns
        -------
        string
            A string representation of the I2C transaction
        */
        return {super.convert2string(),$sformatf("num_bytes:%d address:0x%x rw:%x data:%p", num_bytes, address, rw, data)};
    endfunction

endclass : i2c_transaction
