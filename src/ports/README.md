# ports/

Interfaces the core needs from the outside world (data, input, delivery, clock, configuration...) and the plain data types that cross them.

A port is the one-way door of this method: it is hard to change later, so spend two minutes on its shape. Ports depend on nothing but the standard library: never on core, adapters or app. One contract suite in `contracts/` per port.
