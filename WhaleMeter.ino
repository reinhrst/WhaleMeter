#include <Wire.h>
#include <RFduinoBLE.h>


/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
 
// Pin 3 has an green LED connected on the RGB LED shield
// give it a name:
int UV_EN = 3;
int UV_VAL = 2;
int L_SCL = 6;
int L_SDA = 5;
int TSL2561_ADDRESS = 0b0111001;
int TSL2561_CMD = 0x80;
int TSL_2561_BLOCK = 0x10;

int TSL_REG_CONTROL = 0x0;
int TSL_REG_TIMING = 0x1;
int TSL_REG_INTERRUPT = 0x6;
int TSL_REG_DATA = 0xC;


byte _error;
char advertisementData[9];
word batt;

// the setup routine runs once when you press reset:
void setup() {
  Serial.begin(9600);
  delay(1000);
  writeUv(0);
  writeBatt(100);
  writeIr(0);
  writeVis(0);
  advertisementData[8] = 0;

  pinMode(UV_EN, OUTPUT);
  digitalWrite(UV_EN, HIGH); // enable the UV meter
  Serial.println("start");
  setup_TSL2561();
  Serial.println("setup done");
  
  RFduinoBLE.deviceName="Whale";
  RFduinoBLE.advertisementData = advertisementData;
  RFduinoBLE.begin();
}



void setup_TSL2561(){
  Wire.beginOnPins(L_SCL, L_SDA);
  Wire.beginTransmission(TSL2561_ADDRESS);
  if (!(writeByte(TSL_REG_CONTROL, 0b11) && // powerup
        writeByte(TSL_REG_TIMING, 0b10) && // 402ms integration time. no gain
        writeByte(TSL_REG_INTERRUPT, 0))) { // no interrupts
        Serial.println("error in setup");
        Serial.println(getError());
  }
}

// the loop routine runs over and over again forever:
void loop() {
  writeUv(analogRead(2));
  word vis, ir;
  readData(vis, ir);
  writeVis(vis);
  writeIr(ir);
  batt++;
  writeBatt(batt);
  RFduinoBLE.advertisementData = advertisementData;
  Serial.println("hi");
  
  delay(1000);
}

void writeUv(word val) {
   writeAdvertisementData(val, 0);
}
void writeVis(word val) {
   writeAdvertisementData(val, 2);
}
void writeIr(word val) {
   writeAdvertisementData(val, 4);
}
void writeBatt(word val) {
   writeAdvertisementData(val, 6);
}

void writeAdvertisementData(word val, int pos) {
  byte temp[2] = {(byte) (val & 0xFF) + 1, (byte) ((val >> 8) & 0xFF) + 1};
  if (!temp[0]) {
    temp[0]=0xFF;
    temp[1]=0xFF;
  }
  if (!temp[1]) {
    temp[1] = 0xFF;
  }
  memcpy(advertisementData + pos, temp, 2);
}

boolean readData(unsigned int &vis, unsigned int &ir)
	// Reads data
{
	// Set up command byte for read
	Wire.beginTransmission(TSL2561_ADDRESS);
	Wire.write(TSL_REG_DATA | TSL2561_CMD);
	_error = Wire.endTransmission();

	// Read bytes
	if (_error == 0)
	{
          Wire.requestFrom(TSL2561_ADDRESS,4);
	  if (Wire.available() == 4) {
                  byte low, high;
                  low = Wire.read();
                  high = Wire.read();
                  vis = word(high, low);
                  low = Wire.read();
                  high = Wire.read();
                  ir = word(high, low);
                  return true;
          }
	}
	return(false);
}


boolean readByte(unsigned char address, unsigned char &value)
	// Reads a byte from a TSL2561 address
	// Address: TSL2561 address (0 to 15)
	// Value will be set to stored byte
	// Returns true (1) if successful, false (0) if there was an I2C error
	// (Also see getError() above)
{
	// Set up command byte for read
	Wire.beginTransmission(TSL2561_ADDRESS);
	Wire.write((address & 0x0F) | TSL2561_CMD);
	_error = Wire.endTransmission();

	// Read requested byte
	if (_error == 0)
	{
		Wire.requestFrom(TSL2561_ADDRESS,1);
		if (Wire.available() == 1)
		{
			value = Wire.read();
			return(true);
		}
	}
	return(false);
}

boolean writeByte(unsigned char address, unsigned char value)
	// Write a byte to a TSL2561 address
	// Address: TSL2561 address (0 to 15)
	// Value: byte to write to address
	// Returns true (1) if successful, false (0) if there was an I2C error
	// (Also see getError() above)
{
	// Set up command byte for write
	Wire.beginTransmission(TSL2561_ADDRESS);
	Wire.write((address & 0x0F) | TSL2561_CMD);
	// Write byte
	Wire.write(value);
	_error = Wire.endTransmission();
	if (_error == 0)
		return(true);

	return(false);
}

byte getError(void)
	// If any library command fails, you can retrieve an extended
	// error code using this command. Errors are from the wire library: 
	// 0 = Success
	// 1 = Data too long to fit in transmit buffer
	// 2 = Received NACK on transmit of address
	// 3 = Received NACK on transmit of data
	// 4 = Other error
{
	return(_error);
}

