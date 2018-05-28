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
#include "inc\martimgr.mqh"   //马丁管理类
#include "inc\mamgr.mqh"      //均线数值管理类
#include "inc\profitmgr.mqh"  

extern int       MagicNumber     = 20180528;
extern bool      isHandCloseHedg = false;   //是否手动解对冲
extern double    Lots            = 0.1;
extern double    hedgingPips     = 12;     //亏损多少点开对冲单默认12
extern double    TPinMoney       = 11;          //Net TP (money)
extern int       MaxGroupNum     = 2;

extern int       MaxMartiNum     = 0;
extern double    Mutilplier      = 1;   //马丁加仓倍数
extern int       GridSize        = 50;

extern int       fastMa          = 50;
extern int       slowMa          = 89;
extern int       slowerMa        = 120;

extern double    distance        = 5;   //加仓间隔点数
extern int       TradingNum      = 2;    //未开对冲单的同时持仓最大数量 
extern int       afterHandCloseMinutes = 180;   //手动解对冲后多少分钟后，订单组如还未到达盈利点，则强制关闭保护

int       NumberOfTries   = 10,
          Slippage        = 5;
datetime  CheckTimeM1,CheckTimeM5;
double    Pip;
CTradeMgr *objCTradeMgr;  //订单管理类
CMartiMgr *objCMartiMgr;  //马丁管理类
CDictionary *objDict = NULL;     //订单数据字典类
CProfitMgr *objProfitMgr; //利润和仓位管理类
int tmp = 0;

string arrTradingType[5];   //用于记录当前交易中并且未对冲的交易类型，在subPrintDetails()初始化
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
      objCMartiMgr = new CMartiMgr(objCTradeMgr, objDict);
      objProfitMgr = new CProfitMgr(objCTradeMgr,objDict);
   }
   objCMartiMgr.Init(GridSize, MaxMartiNum, Mutilplier);
   objProfitMgr.Init(TPinMoney, isHandCloseHedg, hedgingPips, afterHandCloseMinutes);
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
void OnTick()
{
     subPrintDetails();
     //M5产生信号
     if(CheckTimeM5==iTime(NULL,PERIOD_M5,0)){
         
     } else {
         CheckTimeM5 = iTime(NULL,PERIOD_M5,0);
         //每次M5新柱，执行信号检测
         strSignal = signal();
     }
     
     //M1产生交易
     if(CheckTimeM1==iTime(NULL,PERIOD_M1,0)){
         return;
     } else {
         CheckTimeM1 = iTime(NULL,PERIOD_M1,0);
         objCMartiMgr.CheckAllMarti();
         objProfitMgr.CheckTakeprofit();
         objProfitMgr.CheckOpenHedg();
     }
 }


 //信号检测
string signal()
{
   double bullishDivVal = iCustom(NULL,PERIOD_M5,"FX5_Divergence_v2.0",2,2);  //up
   double bearishDivVal = iCustom(NULL,PERIOD_M5,"FX5_Divergence_v2.0",3,2);  //down
   
   if(bullishDivVal != EMPTY_VALUE){
      return "up";
   }
   
   if(bearishDivVal != EMPTY_VALUE){
      return "down";
   }
   return "none";
}




void subPrintDetails()
{
   //
   string arrTradingType_Tmp[5] = {"none","none","none","none","none"};
   string tradingTypeComment = "\n trading type:";
   int forTmp = 0;
   
   string sComment   = "";
   string sp         = "----------------------------------------\n";
   string NL         = "\n";

   sComment = sp;
   sComment = sComment + "Net = " + TotalNetProfit() + NL; 
   sComment = sComment + "GroupNum = " + objDict.Total() + NL; 
   sComment = sComment + sp;
   sComment = sComment + "Lots=" + DoubleToStr(Lots,2) + NL;
   CItems* currItem = objDict.GetFirstNode();
   for(int i = 1; (currItem != NULL && CheckPointer(currItem)!=POINTER_INVALID); i++)
   {
      sComment = sComment + sp;
      sComment = sComment + currItem.GetTicket()+ ":" + currItem.Hedg + " | ";
      for(int j=0;j<currItem.Marti.Total();j++){
         sComment = sComment + currItem.Marti.At(j) + ",";
      }
      //持仓类型填充
      if(currItem.Hedg == 0 && forTmp<5){
         arrTradingType_Tmp[forTmp] = currItem.GetType();
         forTmp += 1;
      }
      sComment = sComment + NL;
      if(objDict.Total() >0){
         currItem = objDict.GetNextNode();
      }else{
         currItem = NULL;
      }
   }
   ArrayCopy(arrTradingType,arrTradingType_Tmp,0,0,WHOLE_ARRAY);
   for(int i=0;i<ArraySize(arrTradingType);i++){
      tradingTypeComment = tradingTypeComment + arrTradingType[i] + " ,";
   }
   sComment = sComment + tradingTypeComment;
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

//交易中的单子，并且未开对冲的，是否包含传入的交易类型
bool isTypeInTrading(string type){
   for(int i=0;i<ArraySize(arrTradingType);i++){
      if(arrTradingType[i] == type){
         return true;
      }
   }
   return false;
}
//交易中的单子，并且未开对冲的数量
int tradingCount(){
   int num = 0;
   for(int i=0;i<ArraySize(arrTradingType);i++){
      if(arrTradingType[i] != "none"){
         num += 1;
      }
   }
   return num;
}


