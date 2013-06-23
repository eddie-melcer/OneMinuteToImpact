// The All Important Game States
enum GameState{
  Waiting,
  Playing,
  Victory
};

class GameHelper{
  // Serial Related Constants
  static final int Delimiter = 33;
  static final int NumberArduinoValues = 7;
  static final int StartButtonIndex = 0;
  static final int Strap1Index = 1;
  static final int Strap2Index = 2;
  static final int LeftIR1Index = 3;
  static final int RightIR1Index = 4;
  static final int LeftIR2Index = 5;
  static final int RightIR2Index = 6;
  static final int High = 1;
  static final int Low = 0;
  
  // Game Related Constants
  static final int RoundTime = 60 * 1000;
  static final int WarningTime = 10 * 1000;
  static final int FieldWidth = 1024;
  static final int MaxPlayerMovementSpeed = 3;
  static final int MinimumCenterSpacing = 64;
  static final int BattleThreshold = 128;
  static final int BeaconFrequency = 120;
  static final int CheatingPenaltyTime = 90;
}
