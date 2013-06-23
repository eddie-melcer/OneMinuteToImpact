/***** Imports and Variables *****/
// Serial and Sound Imports
import processing.serial.*;
import ddf.minim.*;

// Serial Related Variables
Serial myPort;
ArduinoData arduinoData;

// Sound Related Variables
Minim minim;
SoundManager soundManager;

// Game Related Variables
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
      String arduinoString = myPort.readStringUntil(GameHelper.Delimiter);
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
    if(arduinoData.StartButtonValue == GameHelper.High && !soundManager.IsPlayingCountdown()){
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
      if(timeSinceLastBeacon == GameHelper.BeaconFrequency/2){
        soundManager.PlayBeacon(p1.CalculateVolume(p2), p1.CalculatePan(p2));      
      }else if(timeSinceLastBeacon >= GameHelper.BeaconFrequency){
        soundManager.PlayBeacon(p1.CalculateVolume(p2), p1.CalculatePan(p2));
        timeSinceLastBeacon = 0;
      }
    }
    
    // Update Player Penalty if They Have One
    if(p1.IsPenalized()){
      p1.Penalty--;
    }
    if(p2.IsPenalized()){
      p2.Penalty--;
    }
    
    // Are We Close Enough to Fight
    if(abs(p1.X - p2.X) <= GameHelper.BattleThreshold && !fighting){
      // Check for cheating!!!
      if(arduinoData.Strap1Value == GameHelper.High){
        p1.Penalty = GameHelper.CheatingPenaltyTime;
      }
      if(arduinoData.Strap2Value == GameHelper.High){
        p2.Penalty = GameHelper.CheatingPenaltyTime;
      }
      soundManager.PlayFight();
      fighting = true;
    }else if(abs(p1.X - p2.X) > GameHelper.BattleThreshold && fighting){
      println("---------------------ESCAPE!!!!-------------------------");
      endFight();
    }
    
    if(fighting && ((arduinoData.Strap1Value == GameHelper.High && !p1.IsPenalized()) || (arduinoData.Strap2Value == GameHelper.High && !p2.IsPenalized()))){
      // Make sure there is no tie
      if(!((arduinoData.Strap1Value == GameHelper.High && !p1.IsPenalized()) && (arduinoData.Strap2Value == GameHelper.High && !p2.IsPenalized()))){
        if(arduinoData.Strap1Value == GameHelper.High && !p1.IsPenalized()){
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
    
    if((millis() - roundStartTime) >= (GameHelper.RoundTime - GameHelper.WarningTime) && !warning){
      if(Debug)
        print("----------- WARNING ----------");
      soundManager.PlayWindRushing();
      warning = true;
    }
    
    if((millis() - roundStartTime) >= GameHelper.RoundTime){
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
    if(key == 's' || key == 'S')arduinoData.Strap1Value = GameHelper.High;
    if(key == 'a' || key == 'A')arduinoData.LeftIR1Value = 255;
    if(key == 'j' || key == 'J')arduinoData.LeftIR2Value = 255;
    if(key == 'k' || key == 'K')arduinoData.Strap2Value = GameHelper.High;
    if(key == 'l' || key == 'L')arduinoData.RightIR2Value = 255;
    if(key == ' ') arduinoData.StartButtonValue = GameHelper.High;
  }
}

void keyReleased(){
  if(Debug){
    if(key == 'd' || key == 'D')arduinoData.RightIR1Value = GameHelper.Low;
    if(key == 's' || key == 'S')arduinoData.Strap1Value = GameHelper.Low;
    if(key == 'a' || key == 'A')arduinoData.LeftIR1Value = GameHelper.Low;
    if(key == 'j' || key == 'J')arduinoData.LeftIR2Value = GameHelper.Low;
    if(key == 'k' || key == 'K')arduinoData.Strap2Value = GameHelper.Low;
    if(key == 'l' || key == 'L')arduinoData.RightIR2Value = GameHelper.Low;
    if(key == ' ') arduinoData.StartButtonValue = GameHelper.Low;
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
  int x1 = (int)random(GameHelper.FieldWidth/2 - GameHelper.MinimumCenterSpacing);
  int x2 = GameHelper.FieldWidth/2 + GameHelper.MinimumCenterSpacing + (int)random(GameHelper.FieldWidth/2 - GameHelper.MinimumCenterSpacing);
  
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
    StartButtonValue = splitValues[GameHelper.StartButtonIndex];
    Strap1Value = splitValues[GameHelper.Strap1Index];
    Strap2Value = splitValues[GameHelper.Strap2Index];
    LeftIR1Value = splitValues[GameHelper.LeftIR1Index];
    RightIR1Value = splitValues[GameHelper.RightIR1Index];
    LeftIR2Value = splitValues[GameHelper.LeftIR2Index];
    RightIR2Value = splitValues[GameHelper.RightIR2Index];
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
  int Penalty;
  
  Player(){
    Penalty = 0;
  }
  
  void Move(int left, int right){
    float value = map(right - left, -255, 255, -GameHelper.MaxPlayerMovementSpeed, GameHelper.MaxPlayerMovementSpeed);
    if(value > 0 && !HasParachute)
      value += 1;
    else if(value < 0 && !HasParachute)
      value -= 1;
    X += value;
    X = constrain(X, 0, GameHelper.FieldWidth);
  }
  
  float CalculateVolume(Player p){
    return (GameHelper.FieldWidth - abs(X - p.X))/GameHelper.FieldWidth;
  }
  
  float CalculatePan(Player p){
    return (-abs(X - p.X)*2)/GameHelper.FieldWidth;
  }
  
  boolean IsPenalized(){
    return Penalty > 0;
  }
}
