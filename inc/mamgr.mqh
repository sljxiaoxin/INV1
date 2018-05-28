//+------------------------------------------------------------------+
//|                                                  CTradeMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

//MA指标管理类
 class CMaMgr
 {
   private:
      
      static const int s_limit;
      static double s_ma10Overlying_buffer[200];
      static double s_ma120Overlying_buffer[200];
   
   public:
      static double s_ma10;
      static double s_ma10_pre;
      static double s_ma10Overlying;
      static double s_ma10Overlying_pre;
      static double s_ma120;
      static double s_ma120_pre;
      static double s_ma120Overlying;
      static double s_ma120Overlying_pre;  
      static double s_ArrFastMa[50];
      static double s_ArrSlowMa[50];
      static double s_ArrSlowerMa[50];   
      CMaMgr(){};
      ~CMaMgr(){};
      static void Init(int fast, int slow, int slower){
         for(int j=0; j<50; j++){
            s_ArrFastMa[j]  = iMA(NULL,0,fast,0,MODE_EMA,PRICE_CLOSE,j+1);
            s_ArrSlowMa[j] = iMA(NULL,0,slow,0,MODE_EMA,PRICE_CLOSE,j+1);
            s_ArrSlowerMa[j] = iMA(NULL,0,slower,0,MODE_EMA,PRICE_CLOSE,j+1);
         }
         
         double ma10Overlying_buffer[200];
         double ma120Overlying_buffer[200];
         ArraySetAsSeries(ma10Overlying_buffer,true);   //倒序索引
         ArraySetAsSeries(ma120Overlying_buffer,true);
         for(int i=0; i<s_limit; i++){
            ma10Overlying_buffer[i]  = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,i);
            ma120Overlying_buffer[i] = iMA(NULL,0,120,0,MODE_EMA,PRICE_CLOSE,i);
         }
         s_ma10              = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,1);
         s_ma10_pre          = iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,2);
         s_ma10Overlying     = iMAOnArray(ma10Overlying_buffer,s_limit,10,0,MODE_EMA,1);
         s_ma10Overlying_pre = iMAOnArray(ma10Overlying_buffer,s_limit,10,0,MODE_EMA,2);
         s_ma120             = iMA(NULL,0,120,0,MODE_EMA,PRICE_CLOSE,1);
         s_ma120_pre         = iMA(NULL,0,120,0,MODE_EMA,PRICE_CLOSE,2);
         s_ma120Overlying    = iMAOnArray(ma120Overlying_buffer,s_limit,120,0,MODE_EMA,1);
         s_ma120Overlying_pre = iMAOnArray(ma120Overlying_buffer,s_limit,120,0,MODE_EMA,2);
         
      }
      
      static double GetMa10(int index){
         return iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,index);
      }
      static double GetMa120(int index){
         return iMA(NULL,0,120,0,MODE_EMA,PRICE_CLOSE,index);
      }
      static double GetMa10Overlying(int index){
         return iMAOnArray(s_ma10Overlying_buffer,s_limit,10,0,MODE_EMA,index);
      }
      static double GetMa120Overlying(int index){
         return iMAOnArray(s_ma120Overlying_buffer,s_limit,120,0,MODE_EMA,index);
      }
      
      
 };
 const int CMaMgr::s_limit=200;
 double CMaMgr::s_ma10Overlying_buffer[200] = {0};
 double CMaMgr::s_ma120Overlying_buffer[200] = {0};
 double CMaMgr::s_ma10 = 0;
 double CMaMgr::s_ma10_pre = 0;
 double CMaMgr::s_ma10Overlying = 0;
 double CMaMgr::s_ma10Overlying_pre = 0;
 double CMaMgr::s_ma120 = 0;
 double CMaMgr::s_ma120_pre = 0;
 double CMaMgr::s_ma120Overlying = 0;
 double CMaMgr::s_ma120Overlying_pre = 0;
 double CMaMgr::s_ArrFastMa[50]   = {0};
 double CMaMgr::s_ArrSlowMa[50]   = {0};
 double CMaMgr::s_ArrSlowerMa[50] = {0};
 
 