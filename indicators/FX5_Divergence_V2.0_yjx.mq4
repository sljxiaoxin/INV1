//+------------------------------------------------------------------+
//|                                          FX5_Divergence_V2.0.mq4 |
//|                                                              FX5 |
//|                                                    hazem@uk2.net |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2007, FX5"
#property link      "hazem@uk2.net"
//----
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_color1 LimeGreen
#property indicator_color2 FireBrick
#property indicator_color3 Green
#property indicator_color4 Red
//---- input parameters
extern string separator1 = "*** OSMA Settings ***";
extern int    fastEMA = 12;
extern int    slowEMA = 26;
extern int    signal = 9;
extern string separator2 = "*** Indicator Settings ***";
extern double positiveSensitivity = 0.0001;
extern double negativeSensitivity = -0.0001;
extern double historyBarsCount = 0;
extern bool   drawDivergenceLines = true;
extern bool   displayAlert = true;
//---- buffers
double upOsMA[];
double downOsMA[];
double bullishDivergence[];
double bearishDivergence[];
double OsMA[];
double Pip;
//----
static datetime lastAlertTime;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//----  add by yjx
  if(Digits==2 || Digits==4) Pip = Point;
   else if(Digits==3 || Digits==5) Pip = 10*Point;
   else if(Digits==6) Pip = 100*Point;
   
   IndicatorBuffers(5); 
//---- indicators
   SetIndexStyle(0, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 2);
   SetIndexStyle(2, DRAW_ARROW);
   SetIndexStyle(3, DRAW_ARROW);
   SetIndexStyle(4, DRAW_NONE);
//----   
   SetIndexBuffer(0, upOsMA);
   SetIndexBuffer(1, downOsMA);
   SetIndexBuffer(2, bullishDivergence);
   SetIndexBuffer(3, bearishDivergence);
   SetIndexBuffer(4, OsMA);
//----   
   SetIndexArrow(2, 233);
   SetIndexArrow(3, 234);
//----
   IndicatorDigits(Digits + 2);
   IndicatorShortName("FX5_Divergence_v2.0(" + fastEMA + "," + 
                      slowEMA + "," + signal + ")");
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
     {
       string label = ObjectName(i);
       if(StringSubstr(label, 0, 14) != "DivergenceLine")
           continue;
       ObjectDelete(label);   
     }
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   int countedBars = IndicatorCounted();
   if (countedBars < 0)
       countedBars = 0;
   CalculateIndicator(countedBars);
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateIndicator(int countedBars)
  {
   int limit = Bars - 10;
   if(countedBars >0){
      countedBars = countedBars - 11;
   }
   for(int i = limit - countedBars; i >= 0; i--)
     {
      CalculateOsMA(i);
      CatchBullishDivergence(i + 2);
      CatchBearishDivergence(i + 2);
     }              
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateOsMA(int i)
  {
   OsMA[i] = iOsMA(NULL, 0, fastEMA, slowEMA, signal, PRICE_CLOSE, i);
   if(OsMA[i] > 0)
     {
      upOsMA[i] = OsMA[i];
      downOsMA[i] = 0;
     }
   else 
       if(OsMA[i] < 0)
         {
           downOsMA[i] = OsMA[i];
           upOsMA[i] = 0;   
         }
   else
     {
       upOsMA[i] = 0;
       downOsMA[i] = 0;   
     }         
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CatchBullishDivergence(int shift)
  {
   if(IsIndicatorTrough(shift) == false)
       return; 
   int currentTrough = shift;
   int lastTrough = GetIndicatorLastTrough(shift);
   //add by yjx
   if(lastTrough - currentTrough <=11 || lastTrough - currentTrough >= 80)
      return;
//----
   //if(OsMA[currentTrough] > OsMA[lastTrough] && Low[currentTrough] < Low[lastTrough])
   if(OsMA[currentTrough] > OsMA[lastTrough] && (Low[lastTrough] - Low[currentTrough]) >= 2.5*Pip)
     {
       bullishDivergence[currentTrough] = OsMA[currentTrough];
      
       if(drawDivergenceLines == true)
         {
           DrawPriceTrendLine(Time[currentTrough], Time[lastTrough], 
                              Low[currentTrough], 
                              Low[lastTrough], Green, STYLE_SOLID);
           DrawIndicatorTrendLine(Time[currentTrough], Time[lastTrough], 
                                  OsMA[currentTrough],
                                  OsMA[lastTrough], Green, STYLE_SOLID);
         }
       if(displayAlert == true)
           DisplayAlert("Classical bullish divergence on: ", currentTrough);  
     }
//----
   //if(OsMA[currentTrough] < OsMA[lastTrough] && Low[currentTrough] > Low[lastTrough])
   if(OsMA[currentTrough] < OsMA[lastTrough] && Low[currentTrough] - Low[lastTrough] >= 2.5*Pip)
     {
       bullishDivergence[currentTrough] = OsMA[currentTrough];
       //----
       if(drawDivergenceLines == true)
         {
           DrawPriceTrendLine(Time[currentTrough], Time[lastTrough], 
                              Low[currentTrough], 
                              Low[lastTrough], Green, STYLE_DOT);
           DrawIndicatorTrendLine(Time[currentTrough], Time[lastTrough], 
                                  OsMA[currentTrough],
                                  OsMA[lastTrough], Green, STYLE_DOT);
         }
       if(displayAlert == true)
           DisplayAlert("Reverse bullish divergence on: ", currentTrough);   
     }      
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CatchBearishDivergence(int shift)
  {
   if(IsIndicatorPeak(shift) == false)
       return;
   int currentPeak = shift;
   int lastPeak = GetIndicatorLastPeak(shift);  
   //add by yjx
   if(lastPeak - currentPeak <=11 || lastPeak - currentPeak >= 80)
      return; 
//----
   //Print("Pip=>",Pip,";value yjx =>", High[currentPeak] - High[lastPeak]);
   //if(OsMA[currentPeak] < OsMA[lastPeak] && High[currentPeak] > High[lastPeak])
   if(OsMA[currentPeak] < OsMA[lastPeak] && High[currentPeak] - High[lastPeak] >= 2.5*Pip)
     {
       bearishDivergence[currentPeak] = OsMA[currentPeak];
       //----
       if(drawDivergenceLines == true)
         {
           DrawPriceTrendLine(Time[currentPeak], Time[lastPeak], 
                              High[currentPeak], 
                              High[lastPeak], Red, STYLE_SOLID);
           DrawIndicatorTrendLine(Time[currentPeak], Time[lastPeak], 
                                  OsMA[currentPeak],
                                  OsMA[lastPeak], Red, STYLE_SOLID);
         }
       if(displayAlert == true)
           DisplayAlert("Classical bearish divergence on: ", 
                        currentPeak);  
     }
//----
   //if(OsMA[currentPeak] > OsMA[lastPeak] && High[currentPeak] < High[lastPeak])
   if(OsMA[currentPeak] > OsMA[lastPeak] && High[lastPeak] - High[currentPeak] >=2.5*Pip )
     {
       bearishDivergence[currentPeak] = OsMA[currentPeak];
      
       if(drawDivergenceLines == true)
         {
           DrawPriceTrendLine(Time[currentPeak], Time[lastPeak], 
                              High[currentPeak], 
                              High[lastPeak], Red, STYLE_DOT);
           DrawIndicatorTrendLine(Time[currentPeak], Time[lastPeak], 
                                  OsMA[currentPeak],
                                  OsMA[lastPeak], Red, STYLE_DOT);
         }
       if(displayAlert == true)
           DisplayAlert("Reverse bearish divergence on: ", currentPeak);   
     }   
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsIndicatorPeak(int shift)
  {
   if(OsMA[shift] > 0 + positiveSensitivity && 
      OsMA[shift] > OsMA[shift+1] && OsMA[shift] > OsMA[shift-1])
     {
       int limit = Bars - 10;
       for(int i = shift + 1; i < limit; i++)
         {
           if(OsMA[i] < 0)
               return(true);
           if(OsMA[i] > OsMA[shift])
               break;            
         }
     }   
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsIndicatorTrough(int shift)
  {
   if(OsMA[shift] < 0 + negativeSensitivity && 
      OsMA[shift] < OsMA[shift+1] && OsMA[shift] < OsMA[shift-1])
     {
      int limit = Bars - 10;
       for(int i = shift + 1; i < limit; i++)
         {
           if(OsMA[i] > 0)
               return(true);
           if(OsMA[i] < OsMA[shift])
               break;            
         }
     }   
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndicatorLastPeak(int shift)
  {
   bool redZone = false;
   int limit = Bars - 10;
   for(int i = shift; i < limit; i++)
     {
       if(OsMA[i] > 0 && redZone == false)
          continue;
       if(OsMA[i] < 0)
         {
           redZone = true;
           continue;
         }
       if(OsMA[i] < positiveSensitivity)
           continue;
       if(OsMA[i] > OsMA[i+1] && OsMA[i] > OsMA[i-1])
           return(i);
     }
   return(-1);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetIndicatorLastTrough(int shift)
{
   bool greenZone = false;
   int limit = Bars - 10;
   for (int i = shift; i < limit; i++)
   {
      if (OsMA[i] < 0 && greenZone == false)
         continue;
      if (OsMA[i] > 0)
      {
         greenZone = true;
         continue;
      }
      if (OsMA[i] > negativeSensitivity)
         continue;      
      if (OsMA[i] < OsMA[i+1] && OsMA[i] < OsMA[i-1])
         return(i);
   }
   return(-1);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayAlert(string message, int shift)
  {
   if(shift <= 2 && Time[shift] != lastAlertTime)
     {
       lastAlertTime = Time[shift];
       Alert(message, Symbol(), " , ", Period(), " minutes chart");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawPriceTrendLine(datetime x1, datetime x2, double y1, 
                        double y2, color lineColor, double style)
  {
   string label = "DivergenceLine2.0# " + DoubleToStr(x1, 0);
   ObjectDelete(label);
   ObjectCreate(label, OBJ_TREND, 0, x1, y1, x2, y2, 0, 0);
   ObjectSet(label, OBJPROP_RAY, 0);
   ObjectSet(label, OBJPROP_COLOR, lineColor);
   ObjectSet(label, OBJPROP_STYLE, style);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawIndicatorTrendLine(datetime x1, datetime x2, double y1, 
                            double y2, color lineColor, double style)
  {
   int indicatorWindow = WindowFind("FX5_Divergence_v2.0(" + 
                                    fastEMA + "," + slowEMA + "," + 
                                    signal + ")");
//----
   if(indicatorWindow < 0)
       return;   
   string label = "DivergenceLine2.0$# " + DoubleToStr(x1, 0);
   ObjectDelete(label);
   ObjectCreate(label, OBJ_TREND, indicatorWindow, x1, y1, x2, y2, 0, 0);
   ObjectSet(label, OBJPROP_RAY, 0);
   ObjectSet(label, OBJPROP_COLOR, lineColor);
   ObjectSet(label, OBJPROP_STYLE, style);
  }
//+------------------------------------------------------------------+


