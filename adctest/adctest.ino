/**
test tsea83 adc
**/

// digital pin 2 has a pushbutton attached to it. Give it a name:
int mux0 = 10;
int mux1 = 11;
int conv= 12;

// the setup routine runs once when you press reset:
void setup() {
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
  // make the pushbutton's pin an input:
  pinMode(mux0, OUTPUT);
  pinMode(mux1, OUTPUT);
  pinMode(conv, OUTPUT);
  digitalWrite(conv, 1);
  
  pinMode(8, INPUT);
  pinMode(9, INPUT);
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  pinMode(4, INPUT);
  pinMode(5, INPUT);
  pinMode(6, INPUT);
  pinMode(7, INPUT);
  delay(100);
}

// the loop routine runs over and over again forever:
void loop() {
  //read left pot
  digitalWrite(mux0, 1);
  digitalWrite(mux1, 0);
  digitalWrite(conv, 0);
  delayMicroseconds(10);
  digitalWrite(conv, 1);
  delayMicroseconds(10);
  unsigned char left_pot=0;
  //Serial.print("start:");
  for (int i=2;i<10;i++){
    //Serial.print(digitalRead(i));
  left_pot+=digitalRead(i)<<(i-2);
  }
  
  Serial.print("right pot:");
  Serial.print(left_pot);
  Serial.print("\n");
  
    //read left pot
  digitalWrite(mux0, 0);
  digitalWrite(mux1, 1);
  digitalWrite(conv, 0);
  delayMicroseconds(10);
  digitalWrite(conv, 1);
  delayMicroseconds(10);
  left_pot=0;
  //Serial.print("start:");
  for (int i=2;i<10;i++){
   // Serial.print(digitalRead(i));
  left_pot+=digitalRead(i)<<(i-2);
  }
  
  Serial.print("left pot:");
  Serial.print(left_pot);
  Serial.print("\n");
  
    //read speed pot
  digitalWrite(mux0, 0);
  digitalWrite(mux1, 0);
  digitalWrite(conv, 0);
  delayMicroseconds(10);
  digitalWrite(conv, 1);
  delayMicroseconds(10);
  left_pot=0;
  //Serial.print("start:");
  for (int i=2;i<10;i++){
    //Serial.print(digitalRead(i));
  left_pot+=digitalRead(i)<<(i-2);
  }
  
  Serial.print("speed pot:");
  Serial.print(left_pot);
  Serial.print("\n");
  
  
  
    //read button pot
  digitalWrite(mux0, 1);
  digitalWrite(mux1, 1);
  digitalWrite(conv, 0);
  delayMicroseconds(10);
  digitalWrite(conv, 1);
  delayMicroseconds(10);
  left_pot=0;
  //Serial.print("start:");
  for (int i=2;i<10;i++){
   // Serial.print(digitalRead(i));
  left_pot+=digitalRead(i)<<(i-2);
  }
  
  Serial.print("button:");
  Serial.print(left_pot);
  Serial.print("\n");
  delay(2000);
  
}

