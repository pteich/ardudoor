#include <SPI.h>
#include <Ethernet.h>

#include <EthernetDHCP.h>

// Libraries für 1-Wire-Bus
#include <OneWire.h>
// Library für DS-Tempearatur-Sensor
#include <DallasTemperature.h>
// include the library code
#include <LiquidCrystal.h>

// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 7
#define DOOR_OFFICE 8
#define DOOR_BUILDING 9

byte mac[] = { 0x54, 0x55, 0x58, 0x11, 0x00, 0x22 };
String readString = String(100);
unsigned long lastReadingTime = 0;
unsigned long lastLeaseTime = 0;
float actualTemp = 0;
const byte* ipAddr;
const byte degreeSymbol = B11011111;
const byte uumlSymbol = B11111100;

const char* ip_to_str(const uint8_t*);

// Activate 1-Wire-Bus
OneWire oneWire(ONE_WIRE_BUS);

// activate temperature sensor class
DallasTemperature sensors(&oneWire);

// LCD init RS, R/W, E, D4-D7
LiquidCrystal lcd(0,1,2,3,4,5,6);

// Getting server ready at port 80
Server server(80);

void setup() 
{
  
  lcd.begin(16, 2);
  
  // start up Dallas library
  lcd.clear();
  lcd.setCursor(0, 1);
  lcd.print("Suche Sensoren");
  sensors.begin();  

  delay(100);
  lcd.setCursor(0, 1);    
  lcd.print(sensors.getDeviceCount(),DEC); 
  lcd.print(" Sensoren      "); 

  pinMode(DOOR_OFFICE, OUTPUT);
  pinMode(DOOR_BUILDING, OUTPUT);

  // self check on startup - activate both relays
  digitalWrite(DOOR_OFFICE, HIGH);
  digitalWrite(DOOR_BUILDING, HIGH);  

  delay(1000);
  
  digitalWrite(tuerOben, LOW);
  digitalWrite(tuerUnten, LOW);  
  
  // start server, get ip address
  lcd.setCursor(0, 1);  
  lcd.print("Init Server     "); 

  EthernetDHCP.begin(mac);
  ipAddr = EthernetDHCP.ipAddress();
  
  // print IP on LCD
  lcd.setCursor(0, 0);  
  lcd.print(ip_to_str(ipAddr));

  server.begin();  
  
  delay(1000); // wait a second
  
  lcd.setCursor(0, 1);  
  lcd.print("                ");    
}

void loop() 
{
    
  // check temperature only once in a while
  if (millis() - lastReadingTime > 5000) {      
    getTemperatures();
    lastReadingTime = millis();
  }
  
  // same for DHCP address maintain
  if (millis() - lastLeaseTime > 500000) {      
    lastLeaseTime = millis();
    EthernetDHCP.maintain();    
  }
  
  // check for new clients
  listenForClients();  
}

// read and print temperature
void getTemperatures() 
{
    lcd.setCursor(0, 1);   
    lcd.setCursor(0, 1);    
    sensors.requestTemperatures();
    lcd.print("Temp: "); 
    actualTemp = sensors.getTempCByIndex(0);
    lcd.print(actualTemp);
    lcd.print(degreeSymbol);
    lcd.print("    ");    
}

void lcdDebug(String msg)
{
    msg.replace("ü",char(uumlSymbol));
    lcd.setCursor(0, 1);
    lcd.print("                ");
    lcd.setCursor(0, 1);    
    lcd.print(msg);
}

void listenForClients() 
{
  // listen for incoming clients
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        
        if (readString.length() < 100) {        
          readString = readString + c;
        }        

        // check for end of line        
        if (c == '\n' && currentLineIsBlank) {
          
          // check for mode=unten param - well, it's German ;)
          if(readString.indexOf("mode=unten") > -1) {
            lcdDebug("Tür unten offen");            
            digitalWrite(DOOR_BUILDING, HIGH);
            delay(500);
            digitalWrite(DOOR_BUILDING, LOW);
          }

          if(readString.indexOf("mode=oben") > -1) {
            lcdDebug("Tür oben offen");                        
            digitalWrite(DOOR_OFFICE, HIGH);
            delay(500);
            digitalWrite(DOOR_OFFICE, LOW);
          }
          
          if(readString.indexOf("mode=beide") > -1) {
            lcdDebug("Beide Türen");                        
            digitalWrite(DOOR_OFFICE, HIGH);
            digitalWrite(DOOR_BUILDING, HIGH);            
            delay(500);
            digitalWrite(DOOR_OFFICE, LOW);
            digitalWrite(DOOR_BUILDING, LOW);            
          }          
          
          // send http response - default site
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html;charset=utf-8");
          client.println();
          client.print("<html><head>");
          client.print("<title>Druck & Werte Türöffner</title>");
          client.print("<style> a { border: 1px outset gray; text-decoration: none; text-align:center;background-color: #EFEFEF; padding-top: 15px; display:block; width: 150px; height: 25px; font-size: 14px; cursor: pointer; margin-bottom: 15px;}</style>");          
          client.println("</head>");

          client.print("<body bgcolor=\"#CCCCCC\">");
          client.print("<a href=\"?mode=unten\">Tür unten</a>");                    
          client.print("<a href=\"?mode=oben\">Tür oben</a>");                    
          client.print("<a href=\"?mode=beide\">Beide Türen</a>");                    
          client.print("<hr>Temperatur: ");
          client.print(actualTemp);
          client.print(" °C");
          client.print("<hr>Ver. 1.2 - Powered by Arduino</body></html>");          
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(300);
    readString="";
    // close the connection:
    client.stop();
  }  
}

// format IP as proper string
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}
