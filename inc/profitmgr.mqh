//+------------------------------------------------------------------+
//|                                                  CTradeMgr.mqh |
//|                                 Copyright 2015, Vasiliy Sokolov. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015."
#property link      "http://www.mql5.com"

//利润保护类
//功能：对冲单开单，对冲单或原单止盈互换，item整体止盈
 class CProfitMgr
 {
      private:
         CDictionary *m_dict;
         CTradeMgr *m_TradeMgr;
         double m_TpInMoney;
         //int m_releaseHedgStep;
         //int m_releaseHedgAdd;
         bool m_isHandCloseHedg;  //是否手动解对冲
         double m_hedgingPips;    //多少点开对冲单
         int m_afterHandCloseMinutes;  //手动解对冲后，过多久自动平仓，分钟数
         string m_signal;         //当前信号 up / down 使用后需重置
      public:
         
         CProfitMgr(CTradeMgr *TradeMgr, CDictionary *_dict){
            m_dict = _dict;
            m_TradeMgr = TradeMgr;
            //m_releaseHedgStep = 200;
            //m_releaseHedgAdd = 0;
            m_afterHandCloseMinutes = 180;
         };
         void Init(double tpmoney, bool isHandCloseHedg, double hedgingPips, int afterMinutes);
         //void EachColumnDo(void);    //每根柱子需要执行的动作
         void CheckOpenHedg(void);   //检测是否需要开启对冲单，最好每颗柱子开盘执行一次
         void CheckTakeprofit(void); //检测是否该止盈，应该每次tick执行
         double GetNetProfit(CItems* item);  //获取item当前净利润
         bool isItemAllClosed(CItems* item); //手动关闭所有订单，需要释放组
         double GetNetPips(int ticket);      //获取盈利点数
         bool isOrderClosed(int ticket);     //订单是否已关闭
         bool CloseItem(CItems* item);   //关闭item内所有订单
         int GetOrderType(int ticket);    //获取订单类型
         void onSignal(string signal);    //buy or sell 信号
 };
 
 void CProfitMgr::Init(double tpmoney, bool isHandCloseHedg, double hedgingPips, int afterMinutes)
 {
      m_TpInMoney = tpmoney;
      m_isHandCloseHedg = isHandCloseHedg;
      m_hedgingPips = hedgingPips; //亏损多少点开对冲单
      m_afterHandCloseMinutes = afterMinutes;
      m_signal = "none";
 }
 
 void CProfitMgr::onSignal(string signal)
 {
      m_signal = signal;    
 }
 /*
 void CProfitMgr::EachColumnDo(void)
 {
      if(m_releaseHedgAdd >0)
      {
         m_releaseHedgAdd -= 1;
      }
 }
 */
 void CProfitMgr::CheckOpenHedg(void)
 {
      //Print("begin hedg");
      if(m_dict.Total()<=0)return;
     // Print("hedg come in0 total is : ", m_dict.Total());
      CItems* currItem = m_dict.GetFirstNode();
     // Print("hedg come in1");
      for(int i = 1; currItem != NULL; i++)
      {
         //Print("open hedg 02 i is:",i);
         if(currItem.Hedg == 0){
            //Print("pre ticket is:",currItem.Hedg);
            if(OrderSelect(currItem.GetTicket(), SELECT_BY_TICKET)==true){
               double _net = OrderProfit();
               int TradeType = OrderType();
               double _lot = OrderLots();
               //Print("log ticket is:",currItem.GetTicket(),"; profit:",_net);
               //if(_net < (-1*3*m_TpInMoney)){
	            if(_net < (-1*10*m_hedgingPips*_lot)){
                  if(TradeType == OP_BUY){
                     int sTicket = m_TradeMgr.Sell(_lot,0,0,"Hedg "+currItem.GetTicket());
                     if(sTicket >0){
                        currItem.Hedg = sTicket;
                     }
                  }
                  if(TradeType == OP_SELL){
                     int bTicket = m_TradeMgr.Buy(_lot,0,0,"Hedg "+currItem.GetTicket());
                     if(bTicket >0){
                        currItem.Hedg = bTicket;
                     }
                    // Print("open hedg 03 i is:",i);
                  }
               }
            }
         }
         if(m_dict.Total() >0){
            currItem = m_dict.GetNextNode();
         }else{
            currItem = NULL;
         }
         
      }
      //Print("hedg come in3");
 }
 
 void  CProfitMgr::CheckTakeprofit(void)
 {
      //Print("begin profit");
      int ord_arr[20];
      int k = 0;
      for(int j=0;j<20;j++){
         ord_arr[j]=0;
      }
      if(m_dict.Total()<=0)return;
     //Print("m_dict total before:",m_dict.Total());
     CItems* currItem = m_dict.GetFirstNode();
     for(int i = 1; (currItem != NULL && CheckPointer(currItem)!=POINTER_INVALID); i++)
     {
         //Print("come into for");
         double _net = GetNetProfit(currItem);
         if(_net >= currItem.GetTP()){
            CloseItem(currItem);
            //m_dict.DeleteCurrentNode();  //删除当前节点
            ord_arr[k] = currItem.GetTicket();
            k += 1;
         }else{
            
            if(isItemAllClosed(currItem)){
               //检查是否该组所有订单已经关闭，如果已经关闭，则需要释放
               ord_arr[k] = currItem.GetTicket();
               k += 1;
            }else if(currItem.Hedg != 0){
               //检测是否有对冲单，如果有对冲单，check原单或对冲单是否已有达到100点利润者，哪个先到平仓哪个
               if(m_isHandCloseHedg){
                   //如果对冲单和原单其中有一个已经关闭了就不能再关了  
                    if(isOrderClosed(currItem.Hedg) || isOrderClosed(currItem.GetTicket())){
                        if(!currItem.IsHandClosed()){
                           currItem.SetHandClosed();  //设置close标记
                        }
                        currItem.addHandCloseMinutes(Period());//手动解对冲后，增加每次新柱体的分钟数
                        Print("afterHandCloseMinutes:",m_afterHandCloseMinutes,"#GetHandCloseMinutes:",currItem.GetHandCloseMinutes());
                        if(currItem.GetHandCloseMinutes() > m_afterHandCloseMinutes){
                           CloseItem(currItem);
                           ord_arr[k] = currItem.GetTicket();
                           k += 1;
                        }
                    }
               }else{
                  /*
                  del by yjx at 2018-05-28 此做法不妥
                  //哪个先到x点利润就先平仓
                  double hedgPips = GetNetPips(currItem.Hedg);        //对冲单净盈利点数
                  double tickPips = GetNetPips(currItem.GetTicket()); //原始单净盈利点数 
                  double closePips = 50 + MathCeil(m_releaseHedgAdd/10);
                  if(hedgPips > closePips){
                     m_TradeMgr.Close(currItem.Hedg);
                     m_releaseHedgAdd += m_releaseHedgStep;
                  }
                  if(tickPips > closePips){
                     m_TradeMgr.Close(currItem.GetTicket());
                     m_releaseHedgAdd += m_releaseHedgStep;
                  }
                  */
                  if(m_signal == "up"){
                     m_signal = "none";
                     if(GetOrderType(currItem.Hedg) == OP_SELL && !isOrderClosed(currItem.Hedg)){
                        m_TradeMgr.Close(currItem.Hedg);
                     }
                     if(GetOrderType(currItem.GetTicket()) == OP_SELL && !isOrderClosed(currItem.GetTicket())){
                        m_TradeMgr.Close(currItem.GetTicket());
                     }
                  }
                  if(m_signal == "down"){
                     m_signal = "none";
                     if(GetOrderType(currItem.Hedg) == OP_BUY && !isOrderClosed(currItem.Hedg)){
                        m_TradeMgr.Close(currItem.Hedg);
                     }
                     if(GetOrderType(currItem.GetTicket()) == OP_BUY && !isOrderClosed(currItem.GetTicket())){
                        m_TradeMgr.Close(currItem.GetTicket());
                     }
                  }
               }
            }
         }
         //Print("m_dict total after:",m_dict.Total());
         if(m_dict.Total() >0){
            currItem = m_dict.GetNextNode();
         }else{
            currItem = NULL;
         }
     }
     for(int m=0;m<20;m++){
         if(ord_arr[m] > 0){
            m_dict.DeleteObjectByKey(ord_arr[m]);  //删除止盈的item
            Print("DeleteObjectByKey:",ord_arr[m]);
         }
     }
     m_signal = "none"; //确保信号及时重置
     
 }
 //获取单个item总利润
 double CProfitMgr::GetNetProfit(CItems* item)
 {
      double _net = 0;
      if(OrderSelect(item.GetTicket(), SELECT_BY_TICKET)==true){
         //原单利润
         _net += OrderProfit();
      }
      if(item.Hedg != 0){
         if(OrderSelect(item.Hedg, SELECT_BY_TICKET)==true){
            //原单利润
            _net += OrderProfit();
         }
      }
      for(int i=0;i<item.Marti.Total();i++){
         if(OrderSelect(item.Marti.At(i), SELECT_BY_TICKET)==true){
            //原单利润
            _net += OrderProfit();
         }
      }
      return _net;
 }
 
 //如果有手动关闭了某组所有订单，需要释放组
 bool CProfitMgr::isItemAllClosed(CItems* item)
 {
   if(!isOrderClosed(item.GetTicket())){
      return false;
   }
   if(item.Hedg != 0){
      if(!isOrderClosed(item.Hedg)){
         return false;
      }
   }
   for(int i=0;i<item.Marti.Total();i++){
      if(!isOrderClosed(item.Marti.At(i))){
         return false;
      }
   }
   return true;
   
 }
 
 bool CProfitMgr::CloseItem(CItems* item)
 {
      if(item.GetTicket() != 0){
         m_TradeMgr.Close(item.GetTicket());
      }
      if(item.Hedg != 0){
         m_TradeMgr.Close(item.Hedg);
      }
      for(int i=0;i<item.Marti.Total();i++){
         m_TradeMgr.Close(item.Marti.At(i));
      }
      return true;
 }
 
 double CProfitMgr::GetNetPips(int ticket)
 {
    double pips = 0;
    if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
        datetime dtc = OrderCloseTime();
        if(dtc >0){
            //订单已平仓，则返回0
            return pips;
        }
        int TradeType = OrderType();
        double openPrice = OrderOpenPrice();
        if(TradeType == OP_BUY){
            pips = (Ask - openPrice)/m_TradeMgr.GetPip();
        }
        if(TradeType == OP_SELL){
            pips = (openPrice - Bid)/m_TradeMgr.GetPip();
        }
    }
    return pips;
 }
 
 bool CProfitMgr::isOrderClosed(int ticket)
 {
    if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
         datetime dtc = OrderCloseTime();
         if(dtc >0){
            return true;
         }else{
            return false;
         }
    }
    return false;
 }
 
 int CProfitMgr::GetOrderType(int ticket)
 {
      if(OrderSelect(ticket, SELECT_BY_TICKET)==true){
         return OrderType();
      }
      return -1;
 }
 
 