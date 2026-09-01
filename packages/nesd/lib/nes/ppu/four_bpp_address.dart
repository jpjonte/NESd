library;

int fourBppPlanarAddress(int address, int planeHi) =>
    ((address & 0x1ff0) << 1) | (planeHi << 4) | (address & 0xf);

int fourBppWideAddress(int address, int planeHi) => (address << 1) | planeHi;
