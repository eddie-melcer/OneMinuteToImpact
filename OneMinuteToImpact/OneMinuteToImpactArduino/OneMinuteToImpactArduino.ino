int p1LedPin =  11;      // the number of the LED pin
int p2LedPin =  12;      // the number of the LED pin
int buttonPin = 2;        // the number of the pushbutton pin
int buttonState = 0;         // variable for reading the pushbutton status

int p1StrapPin = 3;        // the number of the pushbutton pin
int p1StrapState = 0;         // variable for reading the pushbutton status
int p2StrapPin = 4;        // the number of the pushbutton pin
int p2StrapState = 0;         // variable for reading the pushbutton status

int p1LeftIRsensor = A0;  // Analog input pin that the Player 1, Left IR is attached to
int p1RightIRsensor = A1;  // Analog input pin that the Player 1, Right IR is attached to
int p2LeftIRsensor = A2;  // Analog input pin that the Player 2, Left IR is attached to
int p2RightIRsensor = A3;  // Analog input pin that the Player 2, Right IR is attached to

int p1LeftSensorValue;        // value read from the pot Player 1, Left IR
int p1RightSensorValue;        // value read from the pot Player 1, Right IR
int p2LeftSensorValue;        // value read from the pot Player 2, Left IR
int p2RightSensorValue;        // value read from the pot Player 2, Right IR

int p1LeftMapValue;        // value output to the PWM (analog out) Player 1, Left IR
int p1RightMapValue;        // value output to the PWM (analog out) Player 1, Right IR
int p2LeftMapValue;        // value output to the PWM (analog out) Player 2, Left IR
int p2RightMapValue;        // value output to the PWM (analog out) Player 2, Right IR

boolean Debug = false;

void setup() {
  // initialize the LED pin as an output:
  pinMode(p1LedPin, OUTPUT);   
  pinMode(p2LedPin, OUTPUT);   
  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);  
  // initialize the strap buttons as an input:  
  pinMode(p1StrapPin, INPUT);  
  pinMode(p2StrapPin, INPUT);  
  // initialize serial communications at 9600 bps:
  Serial.begin(9600); 
}

void loop() {
  //Ballon LED lights based on data from processing
  // send data only when you receive data:
  if (Serial.available() > 0) {
    // read the incoming byte:
    int ledValue = Serial.read();

    // say what you got:
    Serial.print("I received: ");
    Serial.println(ledValue, DEC);
    //if ledValue = 0, Player 1 has ballon, else Player 2 has ballon
    if(ledValue == 0)
    {
      digitalWrite(p1LedPin, LOW); 
      digitalWrite(p2LedPin, HIGH); 
    }
    else
    {
      digitalWrite(p2LedPin, LOW); 
      digitalWrite(p1LedPin,HIGH); 
    }
  }
  
  // read the state of the pushbutton value:
  buttonState = digitalRead(buttonPin);
  
  // read the state of the strap button values:
  p1StrapState = digitalRead(p1StrapPin);
  p2StrapState = digitalRead(p2StrapPin);
  
  // read the analog in value:
  p1LeftSensorValue = analogRead(p1LeftIRsensor); 
  p1RightSensorValue = analogRead(p1RightIRsensor);  
  p2LeftSensorValue = analogRead(p2LeftIRsensor); 
  p2RightSensorValue = analogRead(p2RightIRsensor);  
  
  // map it to the range of the analog out:
  p1LeftMapValue = 512 - map(p1LeftSensorValue, 0, 700, 0, 512);         
  p1RightMapValue = 512 - map(p1RightSensorValue, 0, 700, 0, 512);    
  p2LeftMapValue = 512 - map(p2LeftSensorValue, 0, 700, 0, 512);
  p2RightMapValue = 512 - map(p2RightSensorValue, 0, 700, 0, 512);
  
 
  // print the results to the serial monitor:
  String s = String(buttonState) + "," + String(p1StrapState) + "," + String(p2StrapState) + "," + String(p1LeftMapValue) + "," + String(p1RightMapValue) + "," + String(p2LeftMapValue) + "," + String(p2RightMapValue) + "!";
  if(Debug)
    Serial.println(s);
  else
    Serial.print(s);
/*  
  Serial.print(p1StrapState, DEC);  // print sensor 1
  Serial.print(",");                // print ','
  Serial.print(p2StrapState, DEC);  // print sensor 1
  Serial.print(",");                // print ','
  Serial.print(buttonState, DEC);  // print sensor 1
  Serial.print(",");                // print ',' 
  Serial.print(p1LeftSensorValue, DEC);  // print sensor 1
  Serial.print(",");                // print ','
  Serial.print(p1RightSensorValue, DEC);  // print sensor 2
  Serial.print(",");                // print ','
  Serial.print(p2LeftSensorValue, DEC);  // print sensor 3
  Serial.print(",");                // print ','
  Serial.println(p2RightSensorValue, DEC);  // print sensor 4
*/
  // wait 300 milliseconds before the next loop
  // for the analog-to-digital converter to settle
  // after the last reading:
  delay(100);                     
}
