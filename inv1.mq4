//+------------------------------------------------------------------+
//|     inv1  无形系统V1                         
//|     1、profitmgr 增加接收buy or sell信号，执行自动解对冲
//|     2、增加最大持仓时间限制参数
//|                                                      
//|                                              
//+------------------------------------------------------------------+
#property copyright "xiaoxin003"
#property link      "yangjx009@139.com"
#property version   "1.0"
#property strict

#include <Arrays\ArrayInt.mqh>
#include "inc\dictionary.mqh" //keyvalue数据字典类
#include "inc\trademgr.mqh"   //交易工具类
#include "inc\citems.mqh"     //交易组item


extern int       MagicNumber     = 20180528;
extern double    Lots            = 1;
extern double    TPinMoney       = 150;          //Net TP (money)
extern int       intSL           = 8;            //止损点数，不用加0

extern double    distance        = 5;   //加仓间隔点数

int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1,CheckTimeM5;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CDictionary *objDict = NULL;     //订单数据字典类
int tmp = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   Print("begin");
   if(Digits==2 || Digits==4) Pip = Point;
   else if(Digits==3 || Digits==5) Pip = 10*Point;
   else if(Digits==6) Pip = 100*Point;
   if(objDict == NULL){
      objDict = new CDictionary();
      objCTradeMgr = new CTradeMgr(MagicNumber, Pip, NumberOfTries, Slippage);
   }
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("deinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

string strSignal = "none";
int intTrigger = 0;   //产生信号过多少分钟
bool isSignalOpenOrder = false;  //当前信号是否已开单
void OnTick()
{
     subPrintDetails();
     //M5产生信号
     if(CheckTimeM5==iTime(NULL,PERIOD_M5,0)){
         
     } else {
         CheckTimeM5 = iTime(NULL,PERIOD_M5,0);
         //每次M5新柱，执行信号检测
         string strSg = signal();
         if(strSignal != strSg && strSg != "none"){
            //等于0表示趋势改变
            strSignal = strSg;
            intTrigger = 0;
            isSignalOpenOrder = false;
         }
     }
     
     //M1产生交易
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         return;
     } else {
         CheckTimeM1 = iTime(NULL,PERIOD_M1,0);
         tpMgr();
         doTrade();
         intTrigger += 1;
     }
 }


 //信号检测
string signal()
{
   double bullishDivVal = iCustom(NULL,PERIOD_M5,"FX5_Divergence_v2.0_yjx",2,2);  //up
   double bearishDivVal = iCustom(NULL,PERIOD_M5,"FX5_Divergence_v2.0_yjx",3,2);  //down
   
   if(bullishDivVal != EMPTY_VALUE){
      return "up";
   }
   
   if(bearishDivVal != EMPTY_VALUE){
      return "down";
   }
   return "none";
}

void tpMgr(){
   if(objCTradeMgr.Total()<=0)return ;
   int tradeType,tradeTicket;
   double tradePrice,tradeProfit;
   datetime dt,dtNow;
   for(int cnt=0;cnt<OrdersTotal();cnt++)
   {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()<=OP_SELL &&
         OrderSymbol()==Symbol() &&
         OrderMagicNumber()==MagicNumber)
      {
         dt = OrderOpenTime();
         tradeType = OrderType();
         tradePrice = OrderOpenPrice();
         tradeTicket = OrderTicket();
         tradeProfit = OrderProfit();
         dtNow = iTime(NULL,PERIOD_M5,1);
         if(tradeType == OP_BUY){
            if(tradeProfit >= TPinMoney){
               objCTradeMgr.Close(tradeTicket);
            }else if((dtNow-dt)/(PERIOD_M5*60) >=10){
               if(iClose(NULL,PERIOD_M5,1) < GetM5Ma10(1)){
                  objCTradeMgr.Close(tradeTicket);
               }
            }
            
            
         }
         if(tradeType == OP_SELL){
            if(tradeProfit >= TPinMoney){
               objCTradeMgr.Close(tradeTicket);
            }else if((dtNow-dt)/(PERIOD_M5*60) >=10){
               if(iClose(NULL,PERIOD_M5,1) > GetM5Ma10(1)){
                  objCTradeMgr.Close(tradeTicket);
               }
            }
         }
         
         
      }         
   }
}


//交易判断
void doTrade(){
   if(strSignal == "up" && intTrigger<120){
      //buy
      if(intTrigger == 0){
         //产生信号
         //objProfitMgr.onSignal(strSignal);
      }
      checkTradeM1(strSignal);
   }
   
   if(strSignal == "down" && intTrigger<120){
      //sell
      if(intTrigger == 0){
         //产生信号
         //objProfitMgr.onSignal(strSignal);
      }
      checkTradeM1(strSignal);
   }
}

void checkTradeM1(string type){
   if(isSignalOpenOrder)return;
   if(objCTradeMgr.Total()>0)return ;
   double spanA,spanB,oop;
   int t;
   //spanA = iIchimoku(NULL,0,2,3,5,MODE_SENKOUSPANA,1);
   //spanB = iIchimoku(NULL,0,2,3,5,MODE_SENKOUSPANB,1);
   if(strSignal == "up"){
      //if(Close[1] > spanA && Close[1] > spanB){
      //if(Ask - GetM1Ma10(1) >0 && Ask - GetM1Ma10(1) <=2*Pip){
      int iLest = iLowest(NULL,0,MODE_LOW,12,0);
      double iL = iLow(NULL,0,iLest);
      if(Ask - iL > 2*Pip)return;
         //云图之上
         t = objCTradeMgr.Buy(Lots, intSL, 0, "DIV_UP");
         if(t != 0){
            isSignalOpenOrder = true;
            
         }
      //}
   }else if(strSignal == "down"){
      //if(Close[1] < spanA && Close[1] < spanB){
      //if(GetM1Ma10(1) - Bid >0 && GetM1Ma10(1) -Bid <=2*Pip){
      int iHest = iHighest(NULL,0,MODE_HIGH,12,0);
      double iH = iHigh(NULL,0,iHest);
      if(iH - Bid > 2*Pip)return;
         //云图之下
         t = objCTradeMgr.Sell(Lots, intSL, 0, "DIV_DOWN");
         if(t != 0){
            isSignalOpenOrder = true;
            
         }
      //}
   }
}

double GetM1Ma10(int index){
   return iMA(NULL,PERIOD_M1,10,0,MODE_EMA,PRICE_CLOSE,index);
}

double GetM5Ma10(int index){
   return iMA(NULL,PERIOD_M5,10,0,MODE_EMA,PRICE_CLOSE,index);
}



void subPrintDetails()
{
   //
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   Comment(sComment);
}

double TotalNetProfit()
{
     double op = 0;
     for(int cnt=0;cnt<OrdersTotal();cnt++)
      {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()<=OP_SELL &&
            OrderSymbol()==Symbol() &&
            OrderMagicNumber()==MagicNumber)
         {
            op = op + OrderProfit();
         }         
      }
      return op;
}


