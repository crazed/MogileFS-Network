This is a fork of the original [MogileFS-Network](https://github.com/mogilefs/MogileFS-Network) that provides the following changes:

* support multiple local zones per tracker
* use a random sorter for cmd_create_open_order_devices rather than sorting by free space (better utilization of all devices)
