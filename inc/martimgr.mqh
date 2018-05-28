//+------------------------------------------------------------------+
//|                                                  CTradeMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

//马丁类
 class CMartiMgr
 {
      private:
         CDictionary *m_dict;
         int m_maxMarti;   //每个item最多多少marti
         int m_gridSize;   //加仓size
         double m_mutilplier;  //加仓倍数
         CTradeMgr *m_TradeMgr;
      public:
         CMartiMgr(CTradeMgr *TradeMgr, CDictionary *_dict){
            m_TradeMgr = TradeMgr;
            m_dict = _dict;
         };
         void Init(int gridSize, int maxMarti, double mutilplier);
         void CheckAllMarti(void);
         void CheckMarti(CItems* item);
         int  GetBaseMartiTicket(CItems* item);  //获取马丁基准订单号
         bool isNeedMarti(int ticket);
         double GetNewOrderLot(CItems* item);    //获取本次马丁应开手数
 };
 void CMartiMgr::Init(int gridSize, int maxMarti, double mutilplier)
 {
 
      m_maxMarti = maxMarti;
      //动态设置gridSize??
      m_gridSize = gridSize;
      m_mutilplier = mutilplier;
 }
 void CMartiMgr::CheckAllMarti(void)
 {
      if(m_dict.Total()<=0)return;
      CItems* currItem = m_dict.GetFirstNode();
      for(int i = 1; currItem != NULL; i++)
      {
         //printf((string)i + " ticket is :\t" + currItem.GetTicket());
         CheckMarti(currItem);
         if(m_dict.Total() >0){
            currItem = m_dict.GetNextNode();
         }else{
            currItem = NULL;
         } 
      }
 }
 void CMartiMgr::CheckMarti(CItems* item)
 {
      if(item.Hedg == 0){
         //当前组内无对冲单则返回
         return ;
      }
      if(item.Marti.Total() >= m_maxMarti){
         //当前组内对冲单数量大于最大设定
         return ;
      }
      //检测当前价格和最后一个对冲单/原始单的距离
      int baseTicket = GetBaseMartiTicket(item);
      if(baseTicket == 0) return;
      if(isNeedMarti(baseTicket)){
         //TODO
         //open新马丁订单
         if(OrderSelect(baseTicket, SELECT_BY_TICKET)==true){
            int TradeType = OrderType();
            //string memo = item.GetTicket();
            if(TradeType == OP_BUY){
                  int bTicket = m_TradeMgr.Buy(GetNewOrderLot(item),0,0,"Marti "+item.GetTicket());
                  Print("open new buy marti ticket is:",bTicket);
                  if(bTicket >0){
                     item.Marti.Add(bTicket);
                  }
            }
            if(TradeType == OP_SELL ){
                  int sTicket = m_TradeMgr.Sell(GetNewOrderLot(item),0,0,"Marti "+item.GetTicket());
                  Print("open new sell marti ticket is:",sTicket);
                  if(sTicket >0){
                     item.Marti.Add(sTicket);
                  }
            }
         }
         
      }
      
 }
 int CMartiMgr::GetBaseMartiTicket(CItems* item)
 {
      if(item.Hedg == 0){
         //如果还没开对冲单
         return 0;
      }
      datetime dtHedg = 0;
      datetime dtTick = 0;
      if(OrderSelect(item.Hedg, SELECT_BY_TICKET)==true){
         dtHedg = OrderCloseTime();
      }
      if(OrderSelect(item.GetTicket(), SELECT_BY_TICKET)==true){
         dtTick = OrderCloseTime();
      }
      if(dtHedg == 0 && dtTick == 0){
         //如果对冲单和原单都没平仓则返回
         return 0;
      }
      if(item.Marti.Total() > 0){
         //如果Marti里面已有记录则取最后一个作为基准
         return item.Marti.At(item.Marti.Total() -1);
      }
      //下面的逻辑是哪个没平仓选哪个作为基准
      if(dtHedg == 0){
         return item.Hedg;         //对冲单作为基准单
      }
      if(dtTick == 0){
         return item.GetTicket();  //原单为基准单
      }
      return 0;
 }
bool CMartiMgr::isNeedMarti(int ticket){
   //TODO
   //是否需要开马丁单check
   if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
        int TradeType = OrderType();
        double TradePrice = OrderOpenPrice();
        double DistancePoint = 0.0;
        if(TradeType == OP_BUY)
        {
             DistancePoint = NormalizeDouble(Open[0],Digits) - NormalizeDouble(TradePrice,Digits);
        }
        
        if(TradeType == OP_SELL )
        {
             DistancePoint = NormalizeDouble(TradePrice,Digits) - NormalizeDouble(Open[0],Digits);
        }  
        if(DistancePoint > 0)return false;
        if(DistancePoint < 0 && MathAbs(DistancePoint/m_TradeMgr.GetPip()) > m_gridSize){
            //满足加仓marti条件
            return true;
        }
   }
   return false;
}
double CMartiMgr::GetNewOrderLot(CItems* item)
{
     double _lot = 0;
     if(OrderSelect(item.GetTicket(), SELECT_BY_TICKET)==true){
         _lot = OrderLots();
     }
     if(item.Marti.Total() > 0)
     {
          int lotdecimal = 2;
          int NumOfTrades = item.Marti.Total()-1;
          double Lotsize  = NormalizeDouble(_lot * MathPow(m_mutilplier, NumOfTrades), lotdecimal);
          return(Lotsize);
     }
     return(_lot);
}