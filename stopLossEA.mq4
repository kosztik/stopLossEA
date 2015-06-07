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

int Size=0, cnt, orderType, StopLevel, flipflop=0, Size_now;
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
  
void slSet() {
   Size = OrdersTotal(); 
   for (int cnt=0;cnt<Size;cnt++) {
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
      
         slBuy = MathMax( iHigh(orderSymbol,PERIOD_M15,1) - Kv*iATR(orderSymbol,0,ATRperiod,1), iHigh(orderSymbol,PERIOD_M15,2) - Kv*iATR(orderSymbol,0,ATRperiod,2) );
         // MathMax( smin[shift], High[shift+i] - Kv*iATR(NULL,0,ATRperiod,shift+i)); 
         // if (atrstop < StopLevel) slBuy = StopLevel
      
         Print ("Market: ", StopLevel, ", ATRsL: ", Kv,", " ,iATR(orderSymbol,0,ATRperiod,1), ", ",Kv*iATR(orderSymbol,0,ATRperiod,1) );
         //Print (StopLevel,", ", High[1] - Kv*iATR(orderSymbol,0,ATRperiod,1));
      
         bool res=OrderModify(OrderTicket(),OrderOpenPrice(), slBuy,OrderTakeProfit(),0,Blue);
         if(!res) 
         {
              Print("Error in OrderModify. Error code=",GetLastError());
         }
         else 
         {
              Print("Order modified successfully.");
         }
      }
    
    if (orderType == OP_SELL) {
    
      
      slSell =  MathMin( iLow(orderSymbol,PERIOD_M15,2) + Kv*iATR(orderSymbol,0,ATRperiod,2), iLow(orderSymbol,PERIOD_M15,1) + Kv*iATR(orderSymbol,0,ATRperiod,1) );
      //  MathMin( smax[shift], Low[shift+i] + Kv*iATR(NULL,0,ATRperiod,shift+i));
      bool res=OrderModify(OrderTicket(),OrderOpenPrice(), slSell,OrderTakeProfit(),0,Red);
         if(!res) 
         {
            Print("Error in OrderModify. Error code=",GetLastError());
         }
       else 
       {
            Print("Order modified successfully.");
       }
    }
}

}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  
   int min, sec;
	
   min = Time[0] + PERIOD_M15*60 - CurTime();
   sec = min%60;
   min =(min - min%60) / 60; // idõszámítások, hogy pontosan tudjam mikor van 15. perc

   Size_now = OrdersTotal(); 
   if (Size != Size_now ) slSet();  // ha új pozi van, akkor annak nyomban beállítjuk az sl-t
                                    // így nem kell várni a köv. 15. percre. 
   
   
   if (min != 14) flipflop = 0;
  
   if (min == 14 && flipflop == 0) { // csak minden 15. percben fut le egyszer
      flipflop = 1;
      slSet();
   }
    
   
}
//+------------------------------------------------------------------+
