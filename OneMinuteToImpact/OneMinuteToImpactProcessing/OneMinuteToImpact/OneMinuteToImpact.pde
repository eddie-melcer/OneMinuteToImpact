/***** Imports and Variables *****/
// Serial and Sound Imports
import processing.serial.*;
import ddf.minim.*;

// Serial Related Variables
Serial myPort;
final int Delimiter = 33;
final int NumberArduinoValues = 7;
final int StartButtonIndex = 0;
final int Strap1Index = 1;
final int Strap2Index = 2;
final int LeftIR1Index = 3;
final int RightIR1Index = 4;
final int LeftIR2Index = 5;
final int RightIR2Index = 6;
final int High = 1;
final int Low = 0;
ArduinoData arduinoData;

// Sound Related Variables
Minim minim;
SoundManager soundManager;

// Game Related Variables
final int RoundTime = 60 * 1000;
final int WarningTime = 10 * 1000;
final int FieldWidth = 1024;
final int MaxPlayerMovementSpeed = 3;
final int MinimumCenterSpacing = 64;
final int BattleThreshold = 128;
final int BeaconFrequency = 120;
GameState currentGameState;
int roundStartTime;
int timeSinceLastBeacon;
boolean starting;
boolean fighting;
boolean warning;
Player p1, p2;

// Debugging
boolean Debug = true;

int fall=0;
float exp = .001;

/***** Functions *****/
void setup(){
  if(!Debug){
    // Set this to the display size of the computer it is running on
    size(1280, 768);
      //size(100, 100);
      // Hide the mouse
    noCursor();
  
    // Setup serial
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, 9600);
  }
  
  arduinoData = new ArduinoData("0,0,0,0,0,0,0");
  
  // Setup Sound
  minim = new Minim(this);
  soundManager = new SoundManager(minim);
  
  // Setup Game
  currentGameState = GameState.Waiting;
  roundStartTime = millis();
  timeSinceLastBeacon = 0;
  starting = false;
  fighting = false;
  warning = false;
  p1 = new Player();
  p2 = new Player();
}

void draw(){
  background(0);
  
  if(!Debug){
    // Clear out old arduinoData first
    arduinoData.LoadData("0,0,0,0,0,0,0");

    // Read in new data if avaliable
    if (myPort.available() > 0) {
      // read string and store it in arduinoString
      String arduinoString = myPort.readStringUntil(Delimiter);
      // Make sure that the read succeeded


      if(arduinoString != null && arduinoString.length() ==22){
        println(arduinoString);
        arduinoData.LoadData(arduinoString);
      }
    }
  }else{
    arduinoData.DisplayData();
  }
  
  // Manage Game States
  if(currentGameState == GameState.Waiting){
    // Are we starting a new game? Setup players and start countdown.
    if(arduinoData.StartButtonValue == High && !soundManager.IsPlayingCountdown()){
      setupPlayers();
      soundManager.PlayCountdown();
      starting = true;
    }

    // Is countdown finished? Let's play!
    if(starting && !soundManager.IsPlayingCountdown()){
      starting = false;
      roundStartTime = millis();
      currentGameState = GameState.Playing;
    }
  }else if(currentGameState == GameState.Playing){
    if(Debug)
      println("Player1: " + p1.X + " Player2: " + p2.X);

    // Move Players
    p1.Move(arduinoData.LeftIR1Value, arduinoData.RightIR1Value);
    p2.Move(arduinoData.LeftIR2Value, arduinoData.RightIR2Value);
    
    // Update Beacon Time and Play
    if(!fighting){
      timeSinceLastBeacon++;
      if(timeSinceLastBeacon == BeaconFrequency/2){
        soundManager.PlayBeacon(p1.CalculateVolume(p2), p1.CalculatePan(p2));      
      }else if(timeSinceLastBeacon >= BeaconFrequency){
        soundManager.PlayBeacon(p1.CalculateVolume(p2), p1.CalculatePan(p2));
        timeSinceLastBeacon = 0;
      }
    }
    
    if(abs(p1.X - p2.X) <= BattleThreshold && !fighting){
      soundManager.PlayFight();
      fighting = true;
    }else if(abs(p1.X - p2.X) > BattleThreshold && fighting){
      println("---------------------ESCAPE!!!!-------------------------");
      endFight();
    }
    
    if(fighting && (arduinoData.Strap1Value == High || arduinoData.Strap2Value == High)){
      if(!(arduinoData.Strap1Value == High && arduinoData.Strap2Value == High)){
        if(arduinoData.Strap1Value == High){
          p1.HasParachute = true;
          p2.HasParachute = false;
        }else{
          p2.HasParachute = true;
          p1.HasParachute = false;
        }
        
        // Let arduino know who has parachute
        if(!Debug){
          myPort.write(p1.HasParachute ? 1 : 0);
        }else{
          println(p1.HasParachute ? 1 : 0);
        }
      }
      
      endFight();
      randomPlayerPlacement();
    }
    
    if((millis() - roundStartTime) >= (RoundTime - WarningTime) && !warning){
      if(Debug)
        print("----------- WARNING ----------");
      soundManager.PlayWindRushing();
      warning = true;
    }
    
    if((millis() - roundStartTime) >= RoundTime){
      warning = false;
      fighting = false;
      currentGameState = GameState.Victory;
      soundManager.PlayDeath();
      if(p1.HasParachute)
        soundManager.PlayWin1();
      else
        soundManager.PlayWin2();
    }
  }else{
    if(!soundManager.IsWinPlaying()){
      currentGameState = GameState.Waiting;
    }
  }
}

void keyPressed(){
  if(Debug){
    if(key == 'd' || key == 'D')arduinoData.RightIR1Value = 255;
    if(key == 's' || key == 'S')arduinoData.Strap1Value = High;
    if(key == 'a' || key == 'A')arduinoData.LeftIR1Value = 255;
    if(key == 'j' || key == 'J')arduinoData.LeftIR2Value = 255;
    if(key == 'k' || key == 'K')arduinoData.Strap2Value = High;
    if(key == 'l' || key == 'L')arduinoData.RightIR2Value = 255;
    if(key == ' ') arduinoData.StartButtonValue = High;
  }
}

void keyReleased(){
  if(Debug){
    if(key == 'd' || key == 'D')arduinoData.RightIR1Value = Low;
    if(key == 's' || key == 'S')arduinoData.Strap1Value = Low;
    if(key == 'a' || key == 'A')arduinoData.LeftIR1Value = Low;
    if(key == 'j' || key == 'J')arduinoData.LeftIR2Value = Low;
    if(key == 'k' || key == 'K')arduinoData.Strap2Value = Low;
    if(key == 'l' || key == 'L')arduinoData.RightIR2Value = Low;
    if(key == ' ') arduinoData.StartButtonValue = Low;
  }
}

//boolean sketchFullScreen() {
  // Need this to remove bars around sketch
  //return !Debug;
//}

void setupPlayers(){
  randomPlayerPlacement();
  p1.HasParachute = false;
  p2.HasParachute = false;
  
  // Randomly determine who has the parachute
  int choice = (int)random(2);
  if(choice == 1)
    p1.HasParachute = true;
  else
    p2.HasParachute = true;
  
  // Let arduino know who has parachute
  if(!Debug){
    myPort.write(p1.HasParachute ? 1 : 0);
  }else{
    println(p1.HasParachute ? 1 : 0);
  }
}

void randomPlayerPlacement(){
  // Random X for left and right players with a padding in the center to prevent immediate fighting
  int x1 = (int)random(FieldWidth/2 - MinimumCenterSpacing);
  int x2 = FieldWidth/2 + MinimumCenterSpacing + (int)random(FieldWidth/2 - MinimumCenterSpacing);
  
  if((int)random(2) == 0){
    p1.X = x1;
    p2.X = x2;
  }else{
    p1.X = x2;
    p2.X = x1;    
  }
}

void endFight(){
  soundManager.PlayFightEnd();
  fighting = false;
  timeSinceLastBeacon = 0;
}


/***** Classes *****/
class ArduinoData {
  int StartButtonValue, Strap1Value, Strap2Value, LeftIR1Value, RightIR1Value, LeftIR2Value, RightIR2Value;
  
  ArduinoData(String values){
    LoadData(values);
  }
  
  void LoadData(String values){
    // Split string to get values
    int[] splitValues = int(split(values, ","));
    
    // Store values from array into appropriate variables
    StartButtonValue = splitValues[StartButtonIndex];
    Strap1Value = splitValues[Strap1Index];
    Strap2Value = splitValues[Strap2Index];
    LeftIR1Value = splitValues[LeftIR1Index];
    RightIR1Value = splitValues[RightIR1Index];
    LeftIR2Value = splitValues[LeftIR2Index];
    RightIR2Value = splitValues[RightIR2Index];
  }
  
  void DisplayData(){
    println(StartButtonValue + "," + Strap1Value + "," + Strap2Value + "," + LeftIR1Value + "," + RightIR1Value + "," + LeftIR2Value + "," + RightIR2Value);
  }
}

class SoundManager{
  Minim SoundControl;
  AudioSnippet Countdown, Beacon;
  AudioSample Fight, FightEnd;
  AudioPlayer Rushing, Death, Win1, Win2;
  
  SoundManager(Minim minim){
    SoundControl = minim;
    Countdown = minim.loadSnippet("Countdown.wav");
    Beacon = minim.loadSnippet("Beacon.wav");
    Fight = minim.loadSample("Fight.wav", 2048);
    FightEnd = minim.loadSample("FightEnd.wav", 2048);
    Rushing = minim.loadFile("Rushing.wav", 2048);
    Death = minim.loadFile("Death.wav", 2048);
    Win1 = minim.loadFile("Win1.mp3", 2048);
    Win2 = minim.loadFile("Win2.mp3", 2048);
  }
  
  void PlayCountdown(){
    Countdown.rewind();
    Countdown.play();
  }
  
  boolean IsPlayingCountdown(){
    return Countdown.isPlaying();
  }
  
  void PlayWindRushing(){
    Rushing.rewind();
    Rushing.play();
  }
  
  boolean IsPlayingWindRushing(){
    return Rushing.isPlaying();
  }
  
  void PlayDeath(){
    Death.rewind();
    Death.play();
  }
  
  boolean IsPlayingDeath(){
    return Death.isPlaying();
  }
  
  void PlayBeacon(float volume, float pan){
    Beacon.rewind();
    Beacon.setGain(map(volume, 0, 1, -35, 0));
    Beacon.setPan(pan);
    Beacon.play();
  }
  
  void PlayFight(){
    Fight.trigger();
  }
  
  void PlayFightEnd(){
    FightEnd.trigger();
  }
  
  void PlayWin1(){
    Win1.rewind();
    Win1.play();
  }
  
  boolean IsWinPlaying(){
    return Win1.isPlaying() || Win2.isPlaying();
  }
  
  void PlayWin2(){
    Win2.rewind();
    Win2.play();
  }
}

class Player{
  float X;
  boolean HasParachute;
  
  Player(){
    
  }
  
  void Move(int left, int right){
    float value = map(right - left, -255, 255, -MaxPlayerMovementSpeed, MaxPlayerMovementSpeed);
    if(value > 0 && !HasParachute)
      value += 1;
    else if(value < 0 && !HasParachute)
      value -= 1;
    X += value;
    X = constrain(X, 0, FieldWidth);
  }
  
  float CalculateVolume(Player p){
    return (FieldWidth - abs(X - p.X))/FieldWidth;
  }
  
  float CalculatePan(Player p){
    return (-abs(X - p.X)*2)/FieldWidth;
  }
}
