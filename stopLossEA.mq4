//+------------------------------------------------------------------+
//|                                                   stopLossEA.mq4 |
//|                                                   Istvan Kosztik |
//|                                https://www.kosztik.hu/stoplossea |
//+------------------------------------------------------------------+
#property copyright "Istvan Kosztik"
#property link      "https://www.kosztik.hu/stoplossea"
#property version   "1.00"
#property strict
//--- input parameters
extern int    Length=10;
extern int    ATRperiod=5;
extern double Kv=3.5;

int Size=0, cnt, orderType, StopLevel, flipflop=0;
string orderSymbol;
double smin, smax, slSell, slBuy;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   int min, sec;
	
   min = Time[0] + PERIOD_M15*60 - CurTime();
   sec = min%60;
   min =(min - min%60) / 60;
//---
   // nyitott kereskedések száma?
  //Print (min);
  
  if (min != 14) flipflop = 0;
  
  if (min == 14 && flipflop == 0) {
  flipflop = 1;
  Size = OrdersTotal();
  
  
  for(int cnt=0;cnt<Size;cnt++) {
    OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
    orderType = OrderType(); // megnézem a tipusát, az sl beállítása végett
    orderSymbol = OrderSymbol(); // DEvizapár
    StopLevel = MarketInfo(orderSymbol, MODE_STOPLEVEL) + MarketInfo(orderSymbol, MODE_SPREAD);
    
    
    
    /*
    
    OP_BUY  0
	 OP_SELL 1
	   
	   csak ezzel a kettõ értékkel foglalkozom, semmilyen más tipussal.
    */
    if (orderType == OP_BUY) {
      
      slBuy =  iHigh(orderSymbol,PERIOD_M15,1) - Kv*iATR(orderSymbol,0,ATRperiod,1);
      //Print (High[1] - Kv*iATR(orderSymbol,0,ATRperiod,1));
      //Print (StopLevel,", ", High[1] - Kv*iATR(orderSymbol,0,ATRperiod,1));
       bool res=OrderModify(OrderTicket(),OrderOpenPrice(), slBuy,OrderTakeProfit(),0,Blue);
       if(!res) {
            Print("Error in OrderModify. Error code=",GetLastError());
         }
       else {
         Print("Order modified successfully.");
         }
    
    }
    
    if (orderType == OP_SELL) {
    
      
      slSell =  iLow(orderSymbol,PERIOD_M15,1) + Kv*iATR(orderSymbol,0,ATRperiod,1);
      bool res=OrderModify(OrderTicket(),OrderOpenPrice(), slSell,OrderTakeProfit(),0,Red);
       if(!res) {
            Print("Error in OrderModify. Error code=",GetLastError());
         }
       else {
            Print("Order modified successfully.");
        }
    }
    }
    }
    
   
  }
//+------------------------------------------------------------------+
