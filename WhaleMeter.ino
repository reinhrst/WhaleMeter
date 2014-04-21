#include <Wire.h>
#include <RFduinoBLE.h>


/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.
 
  This example code is in the public domain.
 */
int LED = 1; 
int BATT = 6;
int UV_EN = 5;
int UV_VAL = 4;
int L_SCL = 2;
int L_SDA = 3;
int TSL2561_ADDRESS = 0b0111001;
int TSL2561_CMD = 0x80;
int TSL_2561_BLOCK = 0x10;

int TSL_REG_CONTROL = 0x0;
int TSL_REG_TIMING = 0x1;
int TSL_REG_INTERRUPT = 0x6;
int TSL_REG_DATA = 0xC;


byte _error;
char advertisementData[10];
word batt;

// the setup routine runs once when you press reset:
void setup() {
  writeUv(0);
  writeBatt(0);
  writeIr(0);
  writeVis(0);
  advertisementData[9] = 0;

  pinMode(UV_VAL, INPUT);
  pinMode(BATT, INPUT);

  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW); // led off
  pinMode(UV_EN, OUTPUT);
  digitalWrite(UV_EN, HIGH); // enable the UV meter
  Serial.println("start");
  setup_TSL2561();
  Serial.println("setup done");
  RFduinoBLE.advertisementInterval = 160;
  
  RFduinoBLE.deviceName="Whale";
}



void setup_TSL2561(){
  Wire.beginOnPins(L_SCL, L_SDA);
  Wire.beginTransmission(TSL2561_ADDRESS);
  if (!(writeByte(TSL_REG_CONTROL, 0b11) && // powerup
        writeByte(TSL_REG_TIMING, 0b10 /* 402ms interval */ | 0x10 /* 16x gain */) &&
        writeByte(TSL_REG_INTERRUPT, 0))) { // no interrupts
        Serial.println("error in setup");
        Serial.println(getError());
  }
}

// the loop routine runs over and over again forever:
void loop() {
  word uv,vis, ir;
  uv = analogRead(UV_VAL);
  batt = analogRead(BATT);
  readData(vis, ir);
  writeUv(uv);
  writeBatt(batt);
  writeVis(vis);
  writeIr(ir);

  RFduinoBLE.advertisementData = advertisementData;
  RFduinoBLE.begin();
  RFduino_ULPDelay(990);
  RFduinoBLE.end();

  digitalWrite(LED, HIGH);
  RFduino_ULPDelay(10);
  digitalWrite(LED, LOW);
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
  
  byte temp[2] = {(byte) (val & 0xFF), (byte) ((val >> 8) & 0xFF)};
  byte mask = 0 | (0b11 << (6-pos));
  byte value = 0 | (((temp[0] & 1) << 1 | (temp[1] & 1)) << (6-pos));
  temp[0] |= 1;
  temp[1] |= 1;
  memcpy(advertisementData + pos, temp, 2);
  advertisementData[8] = advertisementData[8] & ~mask | value;
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

